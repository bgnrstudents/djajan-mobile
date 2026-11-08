import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/order.dart';
import '../models/umkm_seller_models.dart';
import 'catalog_service.dart';

/// Item rincian produk dalam struk
class ReceiptItem {
  final String name;
  final String variant;
  final int quantity;
  final double price;

  const ReceiptItem({
    required this.name,
    this.variant = '',
    required this.quantity,
    required this.price,
  });

  double get total => quantity * price;
}

/// Model data terpadu untuk pencetakan struk transaksi
class ReceiptData {
  final String orderId;
  final DateTime orderDate;
  final String merchantName;
  final String merchantPhone;
  final String merchantAddress;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? customerNote;
  final String deliveryMethod;
  final String paymentMethod;
  final String paymentStatus;
  final List<ReceiptItem> items;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;

  const ReceiptData({
    required this.orderId,
    required this.orderDate,
    required this.merchantName,
    this.merchantPhone = '',
    this.merchantAddress = 'Desa Kreyongan Atas',
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.customerNote,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.serviceFee,
    this.discount = 0,
    required this.total,
  });

  factory ReceiptData.fromCustomerOrder(Order order) {
    final main = order.mainVendor;
    final merchant = CatalogService().umkmById(main.umkmId);

    final items = <ReceiptItem>[];
    for (final v in order.vendors) {
      for (final item in v.items) {
        items.add(
          ReceiptItem(
            name: item.productName,
            variant: item.variant,
            quantity: item.quantity,
            price: item.price,
          ),
        );
      }
    }

    String payStatus = 'Belum Lunas';
    if (order.status == OrderStatus.completed) {
      payStatus = 'Lunas';
    } else if (order.paymentMethod == PaymentMethod.cod) {
      payStatus = 'Bayar di Tempat (COD)';
    } else if (order.status == OrderStatus.waitingPayment) {
      payStatus = 'Menunggu Pembayaran';
    } else {
      payStatus = 'Diproses / Lunas';
    }

    return ReceiptData(
      orderId: order.refId,
      orderDate: order.createdAt,
      merchantName: main.umkmName,
      merchantPhone: main.phone.isNotEmpty
          ? main.phone
          : (merchant?.phone ?? ''),
      merchantAddress: merchant?.pickupLocation.isNotEmpty == true
          ? merchant!.pickupLocation
          : 'Desa Kreyongan Atas, Patrang, Jember',
      customerName: order.recipient.name,
      customerPhone: order.recipient.phone,
      customerAddress: order.recipient.address,
      customerNote: order.recipient.addressNote,
      deliveryMethod: main.delivery == DeliveryMethod.courier
          ? 'Diantar Kurir Warga'
          : 'Ambil Sendiri (Pickup)',
      paymentMethod: order.paymentMethod == PaymentMethod.cod
          ? 'COD (Bayar di Tempat)'
          : 'Midtrans (Online)',
      paymentStatus: payStatus,
      items: items,
      subtotal: order.subtotal,
      deliveryFee: order.shippingTotal,
      serviceFee: order.serviceFee,
      discount: order.discount,
      total: order.total,
    );
  }

  factory ReceiptData.fromUmkmPesanan(
    Pesanan pesanan, {
    String? merchantName,
    String? merchantPhone,
    String? merchantAddress,
  }) {
    final items = pesanan.items
        .map(
          (item) => ReceiptItem(
            name: item.namaProduk,
            variant: item.satuan.isNotEmpty ? item.satuan : '',
            quantity: item.jumlah,
            price: item.hargaSatuan.toDouble(),
          ),
        )
        .toList();

    return ReceiptData(
      orderId: pesanan.idPesanan,
      orderDate: pesanan.tanggalPesan,
      merchantName: merchantName ?? 'UMKM DJajan',
      merchantPhone: merchantPhone ?? '',
      merchantAddress: merchantAddress ?? 'Desa Kreyongan Atas, Patrang, Jember',
      customerName: pesanan.namaPembeli,
      customerPhone: pesanan.noTelp,
      customerAddress: pesanan.alamatTujuan,
      customerNote: pesanan.catatan.isNotEmpty ? pesanan.catatan : null,
      deliveryMethod: pesanan.metodePengiriman == 'kurir'
          ? 'Diantar Kurir Warga'
          : 'Ambil Sendiri (Pickup)',
      paymentMethod: pesanan.metodePembayaran.toUpperCase(),
      paymentStatus: pesanan.statusPembayaran == 'lunas'
          ? 'LUNAS'
          : pesanan.statusPembayaran.toUpperCase(),
      items: items,
      subtotal: pesanan.subtotal.toDouble(),
      deliveryFee: pesanan.biayaPengantaran.toDouble(),
      serviceFee: pesanan.biayaLayanan.toDouble(),
      discount: 0,
      total: pesanan.totalHarga.toDouble(),
    );
  }
}

/// Service untuk membuat dokumen PDF struk yang rapi dan siap cetak/download
class ReceiptPdfService {
  static String _rupiah(double value) {
    try {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(value);
    } catch (_) {
      final valStr = value.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return 'Rp $valStr';
    }
  }

  static String _formatDate(DateTime date) {
    try {
      final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
      return '${formatter.format(date)} WIB';
    } catch (_) {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[(date.month - 1).clamp(0, 11)];
      final year = date.year;
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day $month $year, $hour:$minute WIB';
    }
  }

  /// Menghasilkan byte dokumen PDF struk resmi DJajan
  static Future<Uint8List> generateReceiptPdf(ReceiptData data) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logoNoBg.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final brandPrimary = PdfColor.fromHex('#00880C'); // Hijau DJajan
    final brandDark = PdfColor.fromHex('#111827');
    final neutralGray = PdfColor.fromHex('#6B7280');
    final lightBg = PdfColor.fromHex('#F9FAFB');
    final borderLine = PdfColor.fromHex('#E5E7EB');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ---------------- Header Logo & Judul ----------------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 44,
                          height: 44,
                          margin: const pw.EdgeInsets.only(right: 12),
                          child: pw.Image(logoImage),
                        ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DJAJAN',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: brandPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.Text(
                            'Marketplace Hyperlocal UMKM Desa Kreyongan Atas',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: neutralGray,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: borderLine),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'STRUK TRANSAKSI',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: brandDark,
                          ),
                        ),
                        pw.Text(
                          data.orderId,
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Divider(color: borderLine, thickness: 1),
              pw.SizedBox(height: 12),

              // ---------------- Info UMKM & Penerima ----------------
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Sisi Kiri: Info UMKM
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PENJUAL / UMKM',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: neutralGray,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            data.merchantName,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                          if (data.merchantPhone.isNotEmpty)
                            pw.Text(
                              data.merchantPhone,
                              style: pw.TextStyle(fontSize: 9.5, color: brandDark),
                            ),
                          pw.Text(
                            data.merchantAddress,
                            style: pw.TextStyle(fontSize: 9, color: neutralGray),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                  // Sisi Kanan: Info Pembeli & Pengiriman
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'PEMBELI & PENGIRIMAN',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: neutralGray,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            '${data.customerName} (${data.customerPhone})',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                          pw.Text(
                            data.customerAddress,
                            style: pw.TextStyle(fontSize: 9, color: brandDark),
                            maxLines: 2,
                          ),
                          if (data.customerNote != null && data.customerNote!.isNotEmpty)
                            pw.Text(
                              'Patokan: ${data.customerNote}',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontStyle: pw.FontStyle.italic,
                                color: neutralGray,
                              ),
                            ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Metode: ${data.deliveryMethod}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 14),

              // ---------------- Meta Pembayaran ----------------
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderLine),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Waktu Transaksi: ${_formatDate(data.orderDate)}',
                      style: pw.TextStyle(fontSize: 9.5, color: brandDark),
                    ),
                    pw.Text(
                      'Pembayaran: ${data.paymentMethod} | [${data.paymentStatus}]',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: brandDark,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // ---------------- Tabel Rincian Menu ----------------
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.6), // No
                  1: pw.FlexColumnWidth(3.8), // Menu / Varian
                  2: pw.FlexColumnWidth(1.2), // Qty
                  3: pw.FlexColumnWidth(2.2), // Harga Satuan
                  4: pw.FlexColumnWidth(2.2), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      border: pw.Border(
                        top: pw.BorderSide(color: borderLine),
                        bottom: pw.BorderSide(color: borderLine, width: 1.5),
                      ),
                    ),
                    children: [
                      _th('#'),
                      _th('Menu / Produk'),
                      _th('Qty', align: pw.TextAlign.center),
                      _th('Harga Satuan', align: pw.TextAlign.right),
                      _th('Subtotal', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(data.items.length, (index) {
                    final item = data.items[index];
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: borderLine, width: 0.5)),
                      ),
                      children: [
                        _td('${index + 1}'),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                item.name,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: brandDark,
                                ),
                              ),
                              if (item.variant.isNotEmpty)
                                pw.Text(
                                  'Varian: ${item.variant}',
                                  style: pw.TextStyle(fontSize: 8.5, color: neutralGray),
                                ),
                            ],
                          ),
                        ),
                        _td('${item.quantity}x', align: pw.TextAlign.center),
                        _td(_rupiah(item.price), align: pw.TextAlign.right),
                        _td(_rupiah(item.total), align: pw.TextAlign.right, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 12),

              // ---------------- Rincian Total ----------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal Produk', _rupiah(data.subtotal)),
                        _summaryRow('Biaya Pengantaran', data.deliveryFee == 0 ? 'Gratis' : _rupiah(data.deliveryFee)),
                        _summaryRow('Biaya Layanan', data.serviceFee == 0 ? 'Gratis' : _rupiah(data.serviceFee)),
                        if (data.discount > 0)
                          _summaryRow('Diskon Promo', '-${_rupiah(data.discount)}', isDiscount: true),
                        pw.Divider(color: borderLine),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 4),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'TOTAL BAYAR',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: brandDark,
                                ),
                              ),
                              pw.Text(
                                _rupiah(data.total),
                                style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: brandPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ---------------- Footer Catatan & QR Verification ----------------
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: borderLine),
                ),
                child: pw.Row(
                  children: [
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'DJAJAN:${data.orderId}:${data.total.toInt()}',
                      width: 50,
                      height: 50,
                    ),
                    pw.SizedBox(width: 14),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Terima kasih telah berbelanja di DJajan!',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: brandDark,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Setiap pesanan Anda memberdayakan ekonomi pelaku UMKM Desa Kreyongan Atas. Struk ini merupakan bukti sah transaksi digital.',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: neutralGray,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _th(String label, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        label,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#374151'),
        ),
      ),
    );
  }

  static pw.Widget _td(String label, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        label,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('#1F2937'),
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isDiscount = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9.5, color: PdfColor.fromHex('#6B7280')),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: isDiscount ? PdfColor.fromHex('#EF4444') : PdfColor.fromHex('#1F2937'),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuka preview & dialog cetak/download PDF di HP
  static Future<void> printOrDownloadReceipt(BuildContext context, ReceiptData data) async {
    final pdfBytes = await generateReceiptPdf(data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Struk_${data.orderId}.pdf',
    );
  }

  /// Membagikan file PDF struk langsung (misal via WhatsApp / Email)
  static Future<void> shareReceiptPdf(ReceiptData data) async {
    final pdfBytes = await generateReceiptPdf(data);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Struk_${data.orderId}.pdf',
    );
  }
}
