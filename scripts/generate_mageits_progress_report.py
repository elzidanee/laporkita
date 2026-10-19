#!/usr/bin/env python3
"""
Generator Dokumen PDF Resmi: Laporan Progress Pengembangan LaporKita — MAGEITS 2026
Menggunakan ReportLab dengan NumberedCanvas 2-pass, styling profesional,
hierarki bab terstruktur, tabel perbandingan, dan screenshot visual beresolusi tinggi.
"""

import os
import sys
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak, HRFlowable
)
from reportlab.pdfgen import canvas
from PIL import Image as PILImage

OUTPUT_PDF_PATH = "folderMD/Laporan_Progress_LaporKita_MAGEITS_2026.pdf"

# ── Color Palette ─────────────────────────────────────────────────────────────
PRIMARY = colors.HexColor("#1D9C51")        # LaporKita Brand Green
PRIMARY_DARK = colors.HexColor("#206C57")   # Dark Header Green
PRIMARY_LIGHT = colors.HexColor("#E6F7ED")  # Soft Green Surface
ACCENT_GREEN = colors.HexColor("#B9D19E")   # Badge Accent
DARK_TEXT = colors.HexColor("#1A1A1A")      # Main Body Dark
MUTED_TEXT = colors.HexColor("#555555")     # Subtitle Gray
BORDER_COLOR = colors.HexColor("#E2E8E4")   # Dividers
CARD_BG = colors.HexColor("#F8FAFC")        # Soft Table Cards
WHITE = colors.HexColor("#FFFFFF")
AMBER = colors.HexColor("#F5A623")
DANGER = colors.HexColor("#E53935")


class NumberedCanvas(canvas.Canvas):
    """
    2-pass Canvas to dynamically calculate total page count:
    'Halaman X dari Y' on every page footer.
    """
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_decorations(num_pages)
            super().showPage()
        super().save()

    def draw_page_decorations(self, page_count):
        self.saveState()
        page_w, page_h = A4

        # Skip headers and footers on Cover Page (Page 1)
        if self._pageNumber > 1:
            # Running Header
            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(PRIMARY_DARK)
            self.drawString(36, page_h - 30, "LAPORKITA")
            self.setFont("Helvetica", 8)
            self.setFillColor(MUTED_TEXT)
            self.drawString(88, page_h - 30, "— City Intelligence Platform | MAGEITS 2026 Progress Report")

            self.setFont("Helvetica-Bold", 8)
            self.setFillColor(PRIMARY)
            self.drawRightString(page_w - 36, page_h - 30, "SMK TELKOM MALANG")

            self.setStrokeColor(BORDER_COLOR)
            self.setLineWidth(0.6)
            self.line(36, page_h - 35, page_w - 36, page_h - 35)

            # Running Footer
            self.setStrokeColor(BORDER_COLOR)
            self.setLineWidth(0.6)
            self.line(36, 38, page_w - 36, 38)

            self.setFont("Helvetica", 8)
            self.setFillColor(MUTED_TEXT)
            self.drawString(36, 26, "Tim Saya Akan Lawan • MAGEITS Competition 2026 • ITS Surabaya")

            page_str = f"Halaman {self._pageNumber} dari {page_count}"
            self.drawRightString(page_w - 36, 26, page_str)

        self.restoreState()


def get_doc_styles():
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        name="CoverPreTitle",
        fontName="Helvetica-Bold",
        fontSize=10,
        leading=13,
        textColor=PRIMARY,
        alignment=1,
        spaceAfter=6,
    ))

    styles.add(ParagraphStyle(
        name="CoverMainTitle",
        fontName="Helvetica-Bold",
        fontSize=24,
        leading=28,
        textColor=PRIMARY_DARK,
        alignment=1,
        spaceAfter=10,
    ))

    styles.add(ParagraphStyle(
        name="CoverSubtitle",
        fontName="Helvetica",
        fontSize=11.5,
        leading=16,
        textColor=DARK_TEXT,
        alignment=1,
        spaceAfter=16,
    ))

    styles.add(ParagraphStyle(
        name="CoverMetaLabel",
        fontName="Helvetica-Bold",
        fontSize=8.5,
        leading=12,
        textColor=PRIMARY_DARK,
    ))

    styles.add(ParagraphStyle(
        name="CoverMetaValue",
        fontName="Helvetica",
        fontSize=8.5,
        leading=12,
        textColor=DARK_TEXT,
    ))

    styles.add(ParagraphStyle(
        name="ChapterTitle",
        fontName="Helvetica-Bold",
        fontSize=15,
        leading=19,
        textColor=PRIMARY_DARK,
        spaceBefore=10,
        spaceAfter=8,
        keepWithNext=True,
    ))

    styles.add(ParagraphStyle(
        name="SectionTitle",
        fontName="Helvetica-Bold",
        fontSize=11.5,
        leading=15,
        textColor=PRIMARY,
        spaceBefore=10,
        spaceAfter=5,
        keepWithNext=True,
    ))

    styles.add(ParagraphStyle(
        name="SubSectionTitle",
        fontName="Helvetica-Bold",
        fontSize=9.5,
        leading=13,
        textColor=DARK_TEXT,
        spaceBefore=8,
        spaceAfter=4,
        keepWithNext=True,
    ))

    styles.add(ParagraphStyle(
        name="DocBody",
        fontName="Helvetica",
        fontSize=9,
        leading=13.5,
        textColor=DARK_TEXT,
        spaceAfter=6,
    ))

    styles.add(ParagraphStyle(
        name="DocBodyBold",
        fontName="Helvetica-Bold",
        fontSize=9,
        leading=13.5,
        textColor=DARK_TEXT,
        spaceAfter=6,
    ))

    styles.add(ParagraphStyle(
        name="DocBullet",
        fontName="Helvetica",
        fontSize=8.5,
        leading=12.5,
        textColor=DARK_TEXT,
        leftIndent=12,
        spaceAfter=4,
    ))

    styles.add(ParagraphStyle(
        name="CalloutText",
        fontName="Helvetica",
        fontSize=8.5,
        leading=12.5,
        textColor=PRIMARY_DARK,
    ))

    styles.add(ParagraphStyle(
        name="ImageCaption",
        fontName="Helvetica",
        fontSize=7.5,
        leading=10.5,
        textColor=DARK_TEXT,
        alignment=1,
        spaceAfter=6,
    ))

    styles.add(ParagraphStyle(
        name="TableHead",
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=10.5,
        textColor=WHITE,
        alignment=0,
    ))

    styles.add(ParagraphStyle(
        name="TableCell",
        fontName="Helvetica",
        fontSize=8,
        leading=10.5,
        textColor=DARK_TEXT,
    ))

    styles.add(ParagraphStyle(
        name="TableCellBold",
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=10.5,
        textColor=DARK_TEXT,
    ))

    styles.add(ParagraphStyle(
        name="TableCellSuccess",
        fontName="Helvetica-Bold",
        fontSize=8,
        leading=10.5,
        textColor=PRIMARY,
    ))

    return styles


def fit_image_flowable(image_path, target_width=None, target_height=None, max_width=515, max_height=250):
    if not os.path.exists(image_path):
        return None

    try:
        with PILImage.open(image_path) as pil_img:
            orig_w, orig_h = pil_img.size

        aspect = orig_h / float(orig_w)

        if target_width and not target_height:
            w = min(target_width, max_width)
            h = min(w * aspect, max_height)
        elif target_height and not target_width:
            h = min(target_height, max_height)
            w = min(h / aspect, max_width)
        elif target_width and target_height:
            w = min(target_width, max_width)
            h = min(target_height, max_height)
        else:
            w = max_width
            h = min(w * aspect, max_height)

        return Image(image_path, width=w, height=h)
    except Exception as e:
        print(f"Error loading image {image_path}: {e}")
        return None


def create_callout(text, styles, bg_color=PRIMARY_LIGHT, border_color=PRIMARY):
    p = Paragraph(f"<b>Informasi Penting:</b> {text}", styles["CalloutText"])
    t = Table([[p]], colWidths=[515])
    t.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), bg_color),
        ('BOX', (0,0), (-1,-1), 1, border_color),
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
    ]))
    return t


def build_progress_pdf():
    os.makedirs(os.path.dirname(OUTPUT_PDF_PATH), exist_ok=True)
    doc = SimpleDocTemplate(
        OUTPUT_PDF_PATH,
        pagesize=A4,
        leftMargin=40,
        rightMargin=40,
        topMargin=45,
        bottomMargin=45
    )

    styles = get_doc_styles()
    story = []

    # ═════════════════════════════════════════════════════════════════════════
    # 1. COVER PAGE
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Spacer(1, 15))

    badge_p = Paragraph("DOKUMEN RESMI TAHAP PENGEMBANGAN FINAL • MAGEITS 2026", styles["CoverPreTitle"])
    story.append(badge_p)
    story.append(Spacer(1, 8))

    logo = fit_image_flowable("assets/images/logoLK.png", target_width=75, target_height=75)
    if logo:
        story.append(logo)
        story.append(Spacer(1, 10))

    story.append(Paragraph("LAPORAN PROGRESS PENGERJAAN PLATFORM", styles["CoverMainTitle"]))
    story.append(Paragraph(
        "<b>LaporKita:</b> City Intelligence Platform untuk Kota Malang berbasis AI & Intelligence System<br/>"
        "<i>\"From Report to Resolve — Menghubungkan Laporan Warga ke Tindak Lanjut Nyata\"</i>",
        styles["CoverSubtitle"]
    ))

    story.append(HRFlowable(width="100%", thickness=1.5, color=PRIMARY, spaceAfter=14))

    meta_data = [
        [Paragraph("Nama Aplikasi", styles["CoverMetaLabel"]), Paragraph("LaporKita (Citizen App & Command Center)", styles["CoverMetaValue"])],
        [Paragraph("Ajang Kompetisi", styles["CoverMetaLabel"]), Paragraph("<b>MAGEITS 2026</b> (Multimedia and Game Event — Institut Teknologi Sepuluh Nopember)", styles["CoverMetaValue"])],
        [Paragraph("Kategori Bidang", styles["CoverMetaLabel"]), Paragraph("Application / Software Development (Smart City & Public Infrastructure)", styles["CoverMetaValue"])],
        [Paragraph("Tim Pengembang", styles["CoverMetaLabel"]), Paragraph("<b>Tim Saya Akan Lawan</b>", styles["CoverMetaValue"])],
        [Paragraph("Institusi Asal", styles["CoverMetaLabel"]), Paragraph("SMK Telkom Malang — Jawa Timur", styles["CoverMetaValue"])],
        [Paragraph("Tanggal Laporan", styles["CoverMetaLabel"]), Paragraph("Oktober 2026", styles["CoverMetaValue"])],
        [Paragraph("Status Milestone", styles["CoverMetaLabel"]), Paragraph("<font color='#1D9C51'><b>100% COMPLETE & VERIFIED — READY FOR COMPETITION</b></font>", styles["CoverMetaValue"])],
        [Paragraph("Target Implementasi", styles["CoverMetaLabel"]), Paragraph("Kota Malang (Wilayah Pilot: Klojen, Lowokwaru, Blimbing, Sukun, Kedungkandang)", styles["CoverMetaValue"])],
    ]
    t_meta = Table(meta_data, colWidths=[130, 385])
    t_meta.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), CARD_BG),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
        ('INNERGRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 10),
        ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ]))
    story.append(t_meta)
    story.append(Spacer(1, 16))

    story.append(Paragraph("<b>Ringkasan Teknologi Inti Platform</b>", styles["SubSectionTitle"]))
    tech_data = [
        [
            Paragraph("<b>Mobile Client:</b> Flutter 3.x (Clean Architecture, BLoC)", styles["TableCell"]),
            Paragraph("<b>Backend Gateway:</b> NestJS 11 + Prisma ORM + JWT RBAC", styles["TableCell"])
        ],
        [
            Paragraph("<b>AI Computer Vision:</b> YOLOv11-cls Nano (Akurasi 99.49%, 2.1ms)", styles["TableCell"]),
            Paragraph("<b>Risk Prediction AI:</b> XGBoost Regressor (R² = 0.9635, Banjir)", styles["TableCell"])
        ],
        [
            Paragraph("<b>Policy Simulator LLM:</b> Google Gemini 2.5 Flash (Dampak)", styles["TableCell"]),
            Paragraph("<b>Navigation Engine:</b> OSRM Routing + Indonesian Voice TTS", styles["TableCell"])
        ],
        [
            Paragraph("<b>Database Spasial:</b> PostgreSQL 16 + PostGIS Extension", styles["TableCell"]),
            Paragraph("<b>QA Automation:</b> Playwright E2E + 109 Unit/Widget Tests (100%)", styles["TableCell"])
        ]
    ]
    t_tech = Table(tech_data, colWidths=[255, 260])
    t_tech.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), PRIMARY_LIGHT),
        ('BOX', (0,0), (-1,-1), 1, PRIMARY),
        ('INNERGRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_tech)

    story.append(PageBreak())

    # ═════════════════════════════════════════════════════════════════════════
    # 2. BAB I: RINGKASAN EKSEKUTIF & LATAR BELAKANG
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB I: RINGKASAN EKSEKUTIF & LATAR BELAKANG", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph("1.1 Latar Belakang Masalah Perkotaan di Kota Malang", styles["SectionTitle"]))
    story.append(Paragraph(
        "Kota Malang sebagai salah satu pusat pendidikan, pariwisata, dan ekonomi di Jawa Timur menghadapi tantangan "
        "besar dalam pemeliharaan infrastruktur publik. Tingginya curah hujan musiman sering kali mempercepat kerusakan "
        "jalan (jalan berlubang), memicu luapan genangan air akibat drainase tersumbat, serta mengakibatkan gangguan penerangan "
        "jalan umum (PJU) dan trotoar pejalan kaki. Kanal pelaporan konvensional saat ini sering kali memiliki jeda waktu "
        "penanganan yang lama, minim validasi otomatis, serta tidak transparan bagi masyarakat yang melapor.",
        styles["DocBody"]
    ))
    story.append(Paragraph(
        "Platform <b>LaporKita</b> hadir sebagai solusi <i>City Intelligence Platform</i> berbasis kecerdasan buatan (AI) "
        "yang mengusung filosofi <b>\"From Report to Resolve\"</b>. LaporKita tidak hanya memfasilitasi pelaporan warga "
        "dalam 3 sentuhan mudah (3-Tap Rule), tetapi juga menyediakan sistem manajemen penugasan terintegrasi bagi "
        "Pemerintah Kota Malang (DPUPR, Dishub, DLH) untuk memverifikasi, menugaskan petugas lapangan, memantau pengerjaan fisik, "
        "hingga mensimulasikan dampak kebijakan publik perkotaan berbasis model AI generatif.",
        styles["DocBody"]
    ))

    story.append(Paragraph("1.2 Indikator Keberhasilan & Milestone Scorecard", styles["SectionTitle"]))
    story.append(Paragraph(
        "Selama proses pengerjaan intensif, tim telah menetapkan dan menyelesaikan seluruh metrik keberhasilan teknis:",
        styles["DocBody"]
    ))

    scorecard_data = [
        [Paragraph("Indikator / Target Proyek", styles["TableHead"]), Paragraph("Target Awal", styles["TableHead"]), Paragraph("Capaian Aktual Terverifikasi", styles["TableHead"]), Paragraph("Status", styles["TableHead"])],
        [Paragraph("Kecepatan Pelaporan Warga", styles["TableCellBold"]), Paragraph("< 30 detik", styles["TableCell"]), Paragraph("<b>3 Sentuhan (3-Tap Flow)</b> ~15 detik", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERLAMPAUI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Akurasi Klasifikasi AI (YOLOv11)", styles["TableCellBold"]), Paragraph("> 90.0%", styles["TableCell"]), Paragraph("<b>99.49% Test Accuracy</b> (2.1 ms/gambar)", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERLAMPAUI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Prediksi Risiko Wilayah (XGBoost)", styles["TableCellBold"]), Paragraph("R² > 0.85", styles["TableCell"]), Paragraph("<b>R² = 0.9635, MAE = 0.0369</b>", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERLAMPAUI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Simulasi Kebijakan Publik (Gemini)", styles["TableCellBold"]), Paragraph("Structured JSON", styles["TableCell"]), Paragraph("<b>Gemini 2.5 Flash Live Response</b>", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERPENUHI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Navigasi Titik Bahaya (OSRM)", styles["TableCellBold"]), Paragraph("Rute A ke B", styles["TableCell"]), Paragraph("<b>OSRM Corridor + Indonesian Voice TTS</b>", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERPENUHI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Cakupan Pengujian Unit & Widget", styles["TableCellBold"]), Paragraph("> 80% coverage", styles["TableCell"]), Paragraph("<b>109/109 Tests Passed (100% Pass)</b>", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERPENUHI</b></font>", styles["TableCellSuccess"])],
        [Paragraph("Kualitas Kode Statis (Flutter Analyze)", styles["TableCellBold"]), Paragraph("0 Error", styles["TableCell"]), Paragraph("<b>0 Error, 0 Warning (Clean Audit)</b>", styles["TableCell"]), Paragraph("<font color='#1D9C51'><b>TERPENUHI</b></font>", styles["TableCellSuccess"])],
    ]
    t_score = Table(scorecard_data, colWidths=[140, 80, 205, 90])
    t_score.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_DARK),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
        ('INNERGRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, CARD_BG]),
        ('TOPPADDING', (0,0), (-1,-1), 4.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4.5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_score)

    story.append(PageBreak())

    # ═════════════════════════════════════════════════════════════════════════
    # 3. BAB II: ARSITEKTUR SISTEM & TOPOLOGI TEKNOLOGI
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB II: ARSITEKTUR SISTEM & TOPOLOGI TEKNOLOGI", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph("2.1 Topologi Multi-Tier Microservice", styles["SectionTitle"]))
    story.append(Paragraph(
        "Sistem LaporKita dibangun menggunakan arsitektur modular terpisah untuk memastikan skalabilitas tinggi, "
        "keamanan otorisasi bertingkat, serta latensi inferensi yang sangat rendah:",
        styles["DocBody"]
    ))

    arch_data = [
        [Paragraph("Komponen Lapisan", styles["TableHead"]), Paragraph("Teknologi Stack", styles["TableHead"]), Paragraph("Tugas & Tanggung Jawab Utama", styles["TableHead"])],
        [
            Paragraph("<b>Client Mobile App</b>", styles["TableCellBold"]),
            Paragraph("Flutter 3.x, Dart 3.x, BLoC", styles["TableCell"]),
            Paragraph("Aplikasi terpadu Warga (B2C) & Command Center Pemerintah (B2G). Menggunakan Clean Architecture (Presentation, Domain, Data) dan local storage.", styles["TableCell"])
        ],
        [
            Paragraph("<b>Backend API Gateway</b>", styles["TableCellBold"]),
            Paragraph("NestJS 11, TypeScript, Prisma ORM", styles["TableCell"]),
            Paragraph("Pusat autentikasi JWT RBAC, manajemen CRUD laporan, audit status pengerjaan, rate-limiting, upload media, dan validasi idempotency.", styles["TableCell"])
        ],
        [
            Paragraph("<b>AI Microservice</b>", styles["TableCellBold"]),
            Paragraph("FastAPI, Python 3.11, PyTorch", styles["TableCell"]),
            Paragraph("Pemrosesan Computer Vision (YOLOv11-cls), inferensi XGBoost Regressor untuk prediksi banjir, dan integrasi Google Gemini 2.5 Flash.", styles["TableCell"])
        ],
        [
            Paragraph("<b>Smart Routing Machine</b>", styles["TableCellBold"]),
            Paragraph("OSRM, OpenStreetMap, FlutterMap", styles["TableCell"]),
            Paragraph("Kalkulasi rute berkendara nyata Kota Malang, pencarian titik jalan rusak sepanjang koridor rute, serta panduan suara belokan TTS.", styles["TableCell"])
        ],
        [
            Paragraph("<b>Basis Data Spasial</b>", styles["TableCellBold"]),
            Paragraph("PostgreSQL 16 + PostGIS Extension", styles["TableCell"]),
            Paragraph("Penyimpanan relasional ACID dengan indeks spasial GIS (ST_DWithin, ST_Contains) untuk validasi batas administratif Kota Malang.", styles["TableCell"])
        ],
    ]
    t_arch = Table(arch_data, colWidths=[120, 135, 260])
    t_arch.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
        ('INNERGRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, CARD_BG]),
        ('TOPPADDING', (0,0), (-1,-1), 5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 5),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
    ]))
    story.append(t_arch)
    story.append(Spacer(1, 10))

    story.append(Paragraph("2.2 Spesifikasi Endpoint & Layanan Cloud Aktif", styles["SectionTitle"]))
    story.append(create_callout(
        "Seluruh service backend dan AI microservice telah ter-deploy dan aktif di lingkungan produksi: "
        "<b>https://api.canadev.my.id/api/v1</b> (Backend Gateway) dan "
        "<b>https://ai.canadev.my.id</b> (AI Service). Routing kalkulasi jalan menggunakan public demo server "
        "<b>https://router.project-osrm.org</b>.",
        styles
    ))

    story.append(PageBreak())

    # ═════════════════════════════════════════════════════════════════════════
    # 4. BAB III: KRONOLOGI TAHAPAN PENGERJAAN PROYEK
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB III: KRONOLOGI & TAHAPAN PENGEMBANGAN SISTEM", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph("3.1 Fase 1: Perencanaan, PRD & Desain Sistem UI/UX", styles["SectionTitle"]))
    story.append(Paragraph(
        "Pada tahap awal, tim menyusun Product Requirements Document (PRD) yang mendefinisikan persona pengguna utama: "
        "<b>Kalandra (Warga Pelapor, 24 th)</b>, <b>Operator Lapangan (DPUPR/Dishub)</b>, dan <b>Pengambil Kebijakan (Bappeda/Dinas)</b>. "
        "Tim merumuskan <i>3-Tap Rule</i> agar warga dapat melapor kerusakan dalam waktu kurang dari 30 detik. "
        "Desain UI/UX dirancang menggunakan Figma dengan panduan <i>Design Tokens</i> berbasis palet warna berkelanjutan "
        "(Primary Green <code>#1D9C51</code>, Dark Green <code>#206C57</code>, Surface Soft <code>#E6F7ED</code>).",
        styles["DocBody"]
    ))

    story.append(Paragraph("3.2 Fase 2: Rekayasa Backend Gateway & Basis Data", styles["SectionTitle"]))
    story.append(Paragraph(
        "Pengembangan backend diimplementasikan menggunakan NestJS dengan arsitektur enterprise-grade:",
        styles["DocBody"]
    ))
    story.append(Paragraph("• <b>16 Modul API Lengkap:</b> Auth JWT, Users, Reports, Categories, Agencies, Prediction, Policy Simulator, Notifications.", styles["DocBullet"]))
    story.append(Paragraph("• <b>RBAC Otorisasi 4 Role:</b> <code>citizen</code>, <code>operator</code>, <code>admin</code>, dan <code>policy_maker</code> dengan Guards ketat.", styles["DocBullet"]))
    story.append(Paragraph("• <b>PostGIS Geofencing:</b> Memverifikasi koordinat GPS laporan berada di dalam bounding box Kota Malang (-8.05 s/d -7.90).", styles["DocBullet"]))
    story.append(Paragraph("• <b>Proteksi Idempotensi:</b> Header <code>x-idempotency-key</code> untuk mencegah duplikasi laporan akibat double-tap jaringan lemah.", styles["DocBullet"]))

    story.append(Paragraph("3.3 Fase 3: Rekayasa Model Kecerdasan Buatan (AI Microservice)", styles["SectionTitle"]))
    story.append(Paragraph(
        "AI Microservice dibangun mandiri menggunakan Python FastAPI untuk mendukung 3 kapabilitas analitik canggih:",
        styles["DocBody"]
    ))
    story.append(Paragraph("• <b>Computer Vision (YOLOv11-cls):</b> Dilatih pada ribuan citra kerusakan jalan Indonesia. Menghasilkan akurasi uji <b>99.49%</b> dengan kecepatan inferensi hanya <b>2.1 ms/gambar</b> untuk klasifikasi 5 kelas (Jalan Berlubang, Trotoar, Lampu, Rambu, Drainase).", styles["DocBullet"]))
    story.append(Paragraph("• <b>Urban Risk Prediction (XGBoost Regressor):</b> Memprediksi probabilitas banjir dan indeks stres wilayah berdasarkan curah hujan real-time (mm), rasio masalah drainase, dan densitas laporan. Model mencapai performa regresi <b>R² = 0.9635</b>.", styles["DocBullet"]))
    story.append(Paragraph("• <b>Policy Simulator (Google Gemini 2.5 Flash):</b> Menghubungkan Large Language Model terkini untuk mensimulasikan dampak alokasi anggaran infrastruktur, memproyeksikan penurunan keluhan (%), estimasi biaya (Rp), dan rekomendasi mitigasi risiko konkret.", styles["DocBullet"]))

    story.append(Paragraph("3.4 Fase 4: Rekayasa Frontend Mobile Flutter (Clean Architecture)", styles["SectionTitle"]))
    story.append(Paragraph(
        "Aplikasi mobile Flutter menerapkan arsitektur bersih <i>Presentation → Domain → Data</i> dengan state management <b>BLoC</b>. "
        "Aplikasi menyediakan dua mode akses utama:",
        styles["DocBody"]
    ))
    story.append(Paragraph("• <b>Modul Warga (B2C):</b> Kamera pelaporan Citizen Vision (3 sentuhan), kartu prediktif cuaca & risiko banjir di beranda, peta interaktif sebaran laporan, timeline progres transparan, serta validasi penyelesaian fisik oleh warga (Citizen Validation).", styles["DocBullet"]))
    story.append(Paragraph("• <b>Navigasi Rute Cerdas A → B:</b> Memadukan kalkulasi rute OSRM dengan spatial query laporan jalan berlubang di rute. Dilengkapi panduan suara Text-to-Speech (TTS) Bahasa Indonesia yang mengingatkan pengemudi saat mendekati lubang jalan dalam radius 50 meter.", styles["DocBullet"]))
    story.append(Paragraph("• <b>Modul Pemerintah (B2G):</b> Dashboard penugasan tugas teknis dinas, pengunggahan foto fisik sebelum dan sesudah perbaikan jalan, verifikasi manual laporan berisiko, serta simulator kebijakan publik interaktif.", styles["DocBullet"]))

    story.append(Paragraph("3.5 Fase 5: QA Audit, Optimasi Performa & Bug Squashing", styles["SectionTitle"]))
    story.append(Paragraph(
        "Sebagai bagian dari komitmen keunggulan mutu kompetisi, tim melakukan audit QA menyeluruh:",
        styles["DocBody"]
    ))
    story.append(Paragraph("• <b>Penanganan Error Jujur (FE-09):</b> Memastikan blok exception di UI tidak memalsukan status berhasil (*zero fake success*).", styles["DocBullet"]))
    story.append(Paragraph("• <b>Perbaikan RenderFlex Overflow:</b> Membungkus teks berlebih dengan <code>Flexible</code> dan <code>Expanded</code> pada 3 layar command center saat dirender di layar compact.", styles["DocBullet"]))
    story.append(Paragraph("• <b>Pembersihan Data Dummy & Optimasi Rendering 60-120 FPS:</b> Menghapus seluruh duplikasi seed lama, mengeliminasi ClipRRect yang berat, menambahkan downsampling dekode gambar (<code>cacheWidth: 240</code>), dan menerapkan <code>RepaintBoundary</code> untuk performa scrolling super mulus.", styles["DocBullet"]))
    story.append(Paragraph("• <b>Sinkronisasi Dinamis Peta:</b> Tombol Rute dan Legenda pada halaman peta kini menempel rapat 14px di atas menu sebaran laporan dan bergerak mulus mengikuti tarikan pengguna.", styles["DocBullet"]))

    story.append(PageBreak())

    # ═════════════════════════════════════════════════════════════════════════
    # 5. BAB IV: SHOWCASE VISUAL IMPLEMENTASI FITUR (SCREENSHOTS)
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB IV: GALERI VISUAL IMPLEMENTASI FITUR NYATA", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph(
        "Berikut adalah dokumentasi visual antarmuka platform LaporKita yang berjalan nyata di perangkat mobile emulator/fisik:",
        styles["DocBody"]
    ))

    img1 = fit_image_flowable("assets/doc_images/01_citizen_dashboard.png", target_width=130, target_height=250)
    img2 = fit_image_flowable("assets/doc_images/02_peta_interaktif.png", target_width=130, target_height=250)

    cell1 = [
        img1 if img1 else Paragraph("Foto Dashboard", styles["TableCell"]),
        Paragraph("<b>Gambar 4.1: Beranda Warga (Citizen Dashboard)</b><br/>Menampilkan sapaan personal, kartu prediktif cuaca & risiko banjir, kategori fasilitas, dan daftar laporan terdekat yang bersih tanpa duplikasi dummy.", styles["ImageCaption"])
    ]
    cell2 = [
        img2 if img2 else Paragraph("Foto Peta", styles["TableCell"]),
        Paragraph("<b>Gambar 4.2: Peta Interaktif Sebaran Laporan</b><br/>Peta OpenStreetMap dengan pin status berwarna, legenda otomatis, dan tombol rute yang menempel dinamis mengikuti tarikan menu laporan.", styles["ImageCaption"])
    ]

    t_grid1 = Table([[cell1, cell2]], colWidths=[255, 260])
    t_grid1.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_grid1)
    story.append(Spacer(1, 8))

    img3 = fit_image_flowable("assets/doc_images/03_detail_laporan_navigasi.png", target_width=130, target_height=250)
    img4 = fit_image_flowable("assets/doc_images/04_policy_simulator_gemini.png", target_width=130, target_height=250)

    cell3 = [
        img3 if img3 else Paragraph("Foto Detail Laporan", styles["TableCell"]),
        Paragraph("<b>Gambar 4.3: Detail Laporan & Tombol Navigasi</b><br/>Tampilan detail laporan terpadu dengan mini-map dan tombol 'Navigasi ke lokasi' yang langsung membuka rute GPS terkini.", styles["ImageCaption"])
    ]
    cell4 = [
        img4 if img4 else Paragraph("Foto Policy Simulator", styles["TableCell"]),
        Paragraph("<b>Gambar 4.4: Policy Simulator (Gemini 2.5 Flash)</b><br/>Simulasi skenario kebijakan alokasi anggaran (PUPR/Drainase/DLH) menghasilkan proyeksi penurunan laporan & estimasi biaya real-time.", styles["ImageCaption"])
    ]

    t_grid2 = Table([[cell3, cell4]], colWidths=[255, 260])
    t_grid2.setStyle(TableStyle([
        ('ALIGN', (0,0), (-1,-1), 'CENTER'),
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 8),
        ('RIGHTPADDING', (0,0), (-1,-1), 8),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
    ]))
    story.append(t_grid2)

    story.append(PageBreak())

    # ═════════════════════════════════════════════════════════════════════════
    # 6. BAB V: HASIL PENGUJIAN OTOMATIS & EVALUASI MUTU
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB V: HASIL PENGUJIAN OTOMATIS & EVALUASI MUTU", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph("5.1 Rekapitulasi Uji Mutu Otomatis (Test Suite Results)", styles["SectionTitle"]))
    story.append(Paragraph(
        "Platform LaporKita diuji menggunakan pendekatan *Automated Quality Engineering* di seluruh lapisan (End-to-End):",
        styles["DocBody"]
    ))

    test_summary_data = [
        [Paragraph("Domain Pengujian", styles["TableHead"]), Paragraph("Framework / Tool", styles["TableHead"]), Paragraph("Jumlah Kasus Uji", styles["TableHead"]), Paragraph("Tingkat Kelulusan", styles["TableHead"]), Paragraph("Status Akhir", styles["TableHead"])],
        [
            Paragraph("<b>Flutter Mobile Tests</b>", styles["TableCellBold"]),
            Paragraph("flutter_test (Widget & Unit)", styles["TableCell"]),
            Paragraph("109 Kasus Uji (18 Test Suites)", styles["TableCell"]),
            Paragraph("<b>109 / 109 Lulus</b> (100%)", styles["TableCellBold"]),
            Paragraph("<font color='#1D9C51'><b>PASSED</b></font>", styles["TableCellSuccess"])
        ],
        [
            Paragraph("<b>Backend API Gateway</b>", styles["TableCellBold"]),
            Paragraph("Jest, Supertest, Nest Testing", styles["TableCell"]),
            Paragraph("123 Kasus Uji (16 Test Suites)", styles["TableCell"]),
            Paragraph("<b>123 / 123 Lulus</b> (100%)", styles["TableCellBold"]),
            Paragraph("<font color='#1D9C51'><b>PASSED</b></font>", styles["TableCellSuccess"])
        ],
        [
            Paragraph("<b>E2E Browser & API Regress</b>", styles["TableCellBold"]),
            Paragraph("Playwright Test Engine", styles["TableCell"]),
            Paragraph("4 Skenario Inti (Gemini, OSRM, API)", styles["TableCell"]),
            Paragraph("<b>4 / 4 Lulus</b> (100%)", styles["TableCellBold"]),
            Paragraph("<font color='#1D9C51'><b>PASSED</b></font>", styles["TableCellSuccess"])
        ],
        [
            Paragraph("<b>Mobile Driver Automation</b>", styles["TableCellBold"]),
            Paragraph("Appium Flutter Driver", styles["TableCell"]),
            Paragraph("Verifikasi ValueKey & Entrypoint", styles["TableCell"]),
            Paragraph("<b>id.canadev.laporkita Ready</b>", styles["TableCellBold"]),
            Paragraph("<font color='#1D9C51'><b>VERIFIED</b></font>", styles["TableCellSuccess"])
        ],
        [
            Paragraph("<b>Analisis Kode Statis</b>", styles["TableCellBold"]),
            Paragraph("flutter analyze (Dart Linter)", styles["TableCell"]),
            Paragraph("Seluruh file kode lib/ & test/", styles["TableCell"]),
            Paragraph("<b>0 Error, 0 Warning</b>", styles["TableCellBold"]),
            Paragraph("<font color='#1D9C51'><b>CLEAN</b></font>", styles["TableCellSuccess"])
        ],
    ]
    t_test = Table(test_summary_data, colWidths=[115, 110, 125, 95, 70])
    t_test.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), PRIMARY_DARK),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
        ('INNERGRID', (0,0), (-1,-1), 0.5, BORDER_COLOR),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [WHITE, CARD_BG]),
        ('TOPPADDING', (0,0), (-1,-1), 4.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4.5),
        ('LEFTPADDING', (0,0), (-1,-1), 6),
        ('RIGHTPADDING', (0,0), (-1,-1), 6),
    ]))
    story.append(t_test)
    story.append(Spacer(1, 10))

    story.append(Paragraph("5.2 Evaluasi Kesiapan Fitur untuk Penjurian MAGEITS 2026", styles["SectionTitle"]))
    story.append(Paragraph(
        "Seluruh alur utama yang akan didemonstrasikan di hadapan dewan juri telah diuji ketahanannya:",
        styles["DocBody"]
    ))
    story.append(Paragraph("1. <b>Skenario Pelaporan Warga (B2C):</b> Pengambilan foto jalan rusak di Sawojajar → deteksi AI verifikasi otomatis → submit laporan berhasil dengan nomor tiket <code>#LP-2026-xxxxx</code> → status tampil real-time di beranda warga.", styles["DocBullet"]))
    story.append(Paragraph("2. <b>Skenario Peringatan Rute Jalan Berlubang:</b> Pengemudi memilih rute Alun-Alun ke Jl. Soekarno-Hatta → OSRM menghitung rute tercepat → panduan suara TTS aktif memperingatkan bahaya lubang jalan dalam radius 50 meter.", styles["DocBullet"]))
    story.append(Paragraph("3. <b>Skenario Penanganan Petugas Lapangan (B2G):</b> Petugas DPUPR membuka menu Tugas → klik 'Navigasi ke lokasi' → unggah foto fisik sebelum pengerjaan → geser progress pengerjaan → unggah foto hasil akhir penanganan jalan.", styles["DocBullet"]))
    story.append(Paragraph("4. <b>Skenario Simulasi Kebijakan AI:</b> Pengambil kebijakan memilih skenario normalisasi drainase → Google Gemini 2.5 Flash menghasilkan analisis narasi dan estimasi anggaran dalam hitungan detik.", styles["DocBullet"]))

    story.append(Spacer(1, 12))

    # ═════════════════════════════════════════════════════════════════════════
    # 7. BAB VI: KESIMPULAN & PENUTUP
    # ═════════════════════════════════════════════════════════════════════════
    story.append(Paragraph("BAB VI: KESIMPULAN & PENUTUP", styles["ChapterTitle"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_DARK, spaceAfter=8))

    story.append(Paragraph(
        "Berdasarkan seluruh hasil perancangan, implementasi, optimasi performa, serta serangkaian pengujian otomatis "
        "yang telah dilaksanakan, platform <b>LaporKita — City Intelligence Platform</b> dinyatakan telah mencapai tingkat "
        "kesiapan <b>100% (Production Ready)</b>. Sistem telah memenuhi seluruh kriteria fungsional dan teknis yang disyaratkan "
        "pada kompetisi <b>MAGEITS 2026</b>.",
        styles["DocBody"]
    ))
    story.append(Paragraph(
        "Inovasi yang dihadirkan tidak hanya menyajikan purwarupa visual semata, namun merupakan sistem end-to-end yang nyata "
        "dengan backend aktif, integrasi AI mutakhir (YOLOv11, XGBoost, Gemini 2.5 Flash), navigasi bersuara OSRM, serta kualitas "
        "kode yang bebas dari error maupun warning. Tim pengembang siap mempresentasikan dan mendemonstrasikan keunggulan "
        "platform LaporKita dalam mewujudkan tata kelola kota yang responsif, cerdas, dan transparan bagi Kota Malang.",
        styles["DocBody"]
    ))

    story.append(Spacer(1, 14))

    sig_data = [
        [
            Paragraph("Mengetahui,<br/><b>Pembimbing / Institusi</b><br/><br/><br/><br/><b>SMK Telkom Malang</b>", styles["TableCell"]),
            Paragraph("Malang, 19 Oktober 2026<br/>Ketua Pengembang LaporKita,<br/><br/><br/><br/><b>Tim Saya Akan Lawan</b>", styles["TableCellBold"])
        ]
    ]
    t_sig = Table(sig_data, colWidths=[255, 260])
    t_sig.setStyle(TableStyle([
        ('TOPPADDING', (0,0), (-1,-1), 8),
        ('BOTTOMPADDING', (0,0), (-1,-1), 8),
        ('LEFTPADDING', (0,0), (-1,-1), 16),
        ('RIGHTPADDING', (0,0), (-1,-1), 16),
        ('BACKGROUND', (0,0), (-1,-1), CARD_BG),
        ('BOX', (0,0), (-1,-1), 1, BORDER_COLOR),
    ]))
    story.append(t_sig)

    print(f"Generating PDF progress report at: {OUTPUT_PDF_PATH}...")
    doc.build(story, canvasmaker=NumberedCanvas)
    print("✅ PDF generated successfully!")


if __name__ == "__main__":
    build_progress_pdf()
