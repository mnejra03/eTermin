using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Infrastructure.Data;
using ClosedXML.Excel;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

using eTermin.Domain.Constants;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = UserRoles.Admin)]
public class StatisticsController : ControllerBase
{
    private readonly IStatisticsService _statisticsService;
    private readonly eTerminDbContext _context;

    public StatisticsController(
        IStatisticsService statisticsService,
        eTerminDbContext context)
    {
        _statisticsService = statisticsService;
        _context = context;
    }

    [HttpGet("dashboard")]
    public async Task<ActionResult<DashboardStatisticsDto>>
    GetDashboardStatistics(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status)
    {
        var statistics =
    await _statisticsService
        .GetDashboardStatisticsAsync(
            from,
            to,
            salonId,
            status);

        return Ok(statistics);
    }

    [HttpGet("export/pdf")]
    public async Task<IActionResult> ExportPdf(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status,
        CancellationToken cancellationToken)
    {
        var rows = await GetReportRowsAsync(from, to, salonId, status, cancellationToken);
        QuestPDF.Settings.License = LicenseType.Community;

        var pdf = Document.Create(document =>
            document.Page(page =>
            {
                page.Margin(28);
                page.Header().Column(header =>
                {
                    header.Item().Text("eTermin — izvještaj termina").FontSize(20).Bold();
                    header.Item().Text($"Period: {from:dd.MM.yyyy} – {to:dd.MM.yyyy}");
                    header.Item().Text($"Broj termina: {rows.Count}");
                });
                page.Content().PaddingTop(18).Table(table =>
                {
                    table.ColumnsDefinition(columns =>
                    {
                        columns.RelativeColumn(1.2f);
                        columns.RelativeColumn(1.7f);
                        columns.RelativeColumn(1.5f);
                        columns.RelativeColumn(1.5f);
                        columns.RelativeColumn(1.4f);
                        columns.RelativeColumn(0.8f);
                    });
                    table.Header(header =>
                    {
                        header.Cell().Text("Termin").Bold();
                        header.Cell().Text("Korisnik").Bold();
                        header.Cell().Text("Salon").Bold();
                        header.Cell().Text("Usluga").Bold();
                        header.Cell().Text("Zaposlenik").Bold();
                        header.Cell().Text("Status").Bold();
                    });

                    foreach (var row in rows)
                    {
                        table.Cell().Text(row.StartTime.ToString("dd.MM.yy HH:mm"));
                        table.Cell().Text(row.UserName);
                        table.Cell().Text(row.SalonName);
                        table.Cell().Text(row.ServiceName);
                        table.Cell().Text(row.EmployeeName);
                        table.Cell().Text(row.Status);
                    }
                });
                page.Footer().AlignCenter().Text(text =>
                {
                    text.Span("eTermin • strana ");
                    text.CurrentPageNumber();
                });
            })).GeneratePdf();

        return File(pdf, "application/pdf", "etermin-izvjestaj.pdf");
    }

    [HttpGet("export/excel")]
    public async Task<IActionResult> ExportExcel(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status,
        CancellationToken cancellationToken)
    {
        var rows = await GetReportRowsAsync(from, to, salonId, status, cancellationToken);
        using var workbook = new XLWorkbook();
        var sheet = workbook.Worksheets.Add("Termini");
        sheet.Cell(1, 1).Value = "eTermin — izvještaj termina";
        sheet.Cell(2, 1).Value = "Period";
        sheet.Cell(2, 2).Value = $"{from:dd.MM.yyyy} – {to:dd.MM.yyyy}";
        sheet.Cell(3, 1).Value = "Ukupan broj termina";
        sheet.Cell(3, 2).Value = rows.Count;

        var headers = new[] { "ID", "Termin", "Korisnik", "Salon", "Usluga", "Zaposlenik", "Status", "Cijena (KM)" };
        for (var column = 0; column < headers.Length; column++)
            sheet.Cell(5, column + 1).Value = headers[column];

        for (var index = 0; index < rows.Count; index++)
        {
            var rowNumber = index + 6;
            var row = rows[index];
            sheet.Cell(rowNumber, 1).Value = row.Id;
            sheet.Cell(rowNumber, 2).Value = row.StartTime;
            sheet.Cell(rowNumber, 2).Style.DateFormat.Format = "dd.MM.yyyy HH:mm";
            sheet.Cell(rowNumber, 3).Value = row.UserName;
            sheet.Cell(rowNumber, 4).Value = row.SalonName;
            sheet.Cell(rowNumber, 5).Value = row.ServiceName;
            sheet.Cell(rowNumber, 6).Value = row.EmployeeName;
            sheet.Cell(rowNumber, 7).Value = row.Status;
            sheet.Cell(rowNumber, 8).Value = row.Price;
        }

        var headerRange = sheet.Range(5, 1, 5, headers.Length);
        headerRange.Style.Font.Bold = true;
        headerRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
        sheet.SheetView.FreezeRows(5);
        sheet.Columns().AdjustToContents();

        using var stream = new MemoryStream();
        workbook.SaveAs(stream);
        return File(
            stream.ToArray(),
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            "etermin-izvjestaj.xlsx");
    }

    [HttpGet("export/salon-revenue/pdf")]
    public async Task<IActionResult> ExportSalonRevenuePdf(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status,
        CancellationToken cancellationToken)
    {
        var rows = await GetSalonRevenueRowsAsync(
            from,
            to,
            salonId,
            status,
            cancellationToken);
        QuestPDF.Settings.License = LicenseType.Community;

        var pdf = Document.Create(document =>
            document.Page(page =>
            {
                page.Margin(32);
                page.Header().Column(header =>
                {
                    header.Item().Text("eTermin — prihod po salonima")
                        .FontSize(20).Bold();
                    header.Item().Text(
                        $"Period: {from:dd.MM.yyyy} – {to?.AddDays(-1):dd.MM.yyyy}");
                    if (!string.IsNullOrWhiteSpace(status) &&
                        status != "All statuses" &&
                        status != "Svi statusi")
                    {
                        header.Item().Text($"Status termina: {status}");
                    }
                });
                page.Content().PaddingTop(18).Table(table =>
                {
                    table.ColumnsDefinition(columns =>
                    {
                        columns.RelativeColumn(3);
                        columns.RelativeColumn(1.2f);
                        columns.RelativeColumn(1.5f);
                    });
                    table.Header(header =>
                    {
                        header.Cell().Text("Salon").Bold();
                        header.Cell().AlignRight().Text("Broj uplata").Bold();
                        header.Cell().AlignRight().Text("Prihod (KM)").Bold();
                    });

                    foreach (var row in rows)
                    {
                        table.Cell().Text(row.SalonName);
                        table.Cell().AlignRight().Text(row.PaymentCount.ToString());
                        table.Cell().AlignRight().Text(row.Revenue.ToString("N2"));
                    }

                    table.Cell().ColumnSpan(2).AlignRight()
                        .Text("Ukupno").Bold();
                    table.Cell().AlignRight()
                        .Text(rows.Sum(row => row.Revenue).ToString("N2")).Bold();
                });
                page.Footer().AlignCenter().Text(text =>
                {
                    text.Span("eTermin • strana ");
                    text.CurrentPageNumber();
                });
            })).GeneratePdf();

        return File(pdf, "application/pdf", "etermin-prihod-po-salonima.pdf");
    }

    private async Task<List<AppointmentReportRow>> GetReportRowsAsync(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status,
        CancellationToken cancellationToken)
    {
        var query =
            from appointment in _context.Appointments.AsNoTracking()
            join user in _context.Users.AsNoTracking() on appointment.UserId equals user.Id
            join salon in _context.Salons.AsNoTracking() on appointment.SalonId equals salon.Id
            join employee in _context.Employees.AsNoTracking() on appointment.EmployeeId equals employee.Id
            join service in _context.Services.AsNoTracking() on appointment.ServiceId equals service.Id
            select new AppointmentReportRow
            {
                Id = appointment.Id,
                SalonId = appointment.SalonId,
                UserName = user.FirstName + " " + user.LastName,
                SalonName = salon.Name,
                EmployeeName = employee.FirstName + " " + employee.LastName,
                ServiceName = service.Name,
                StartTime = appointment.StartTime,
                Status = appointment.Status,
                Price = appointment.Price
            };

        if (from.HasValue)
            query = query.Where(row => row.StartTime >= from.Value.Date);
        if (to.HasValue)
            query = query.Where(row => row.StartTime < to.Value.Date);
        if (salonId.HasValue)
            query = query.Where(row => row.SalonId == salonId.Value);
        if (!string.IsNullOrWhiteSpace(status) && status != "All statuses" && status != "Svi statusi")
            query = query.Where(row => row.Status == status);

        return await query
            .OrderBy(row => row.StartTime)
            .ToListAsync(cancellationToken);
    }

    private async Task<List<SalonRevenueReportRow>> GetSalonRevenueRowsAsync(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status,
        CancellationToken cancellationToken)
    {
        var query =
            from payment in _context.Payments.AsNoTracking()
            join appointment in _context.Appointments.AsNoTracking()
                on payment.AppointmentId equals appointment.Id
            join salon in _context.Salons.AsNoTracking()
                on appointment.SalonId equals salon.Id
            where payment.Status == PaymentStatuses.Completed
            select new
            {
                appointment.SalonId,
                SalonName = salon.Name,
                appointment.StartTime,
                appointment.Status,
                payment.Amount
            };

        if (from.HasValue)
            query = query.Where(row => row.StartTime >= from.Value.Date);
        if (to.HasValue)
            query = query.Where(row => row.StartTime < to.Value.Date);
        if (salonId.HasValue)
            query = query.Where(row => row.SalonId == salonId.Value);
        if (!string.IsNullOrWhiteSpace(status) &&
            status != "All statuses" &&
            status != "Svi statusi")
        {
            query = query.Where(row => row.Status == status);
        }

        return await query
            .GroupBy(row => new { row.SalonId, row.SalonName })
            .Select(group => new SalonRevenueReportRow
            {
                SalonName = group.Key.SalonName,
                PaymentCount = group.Count(),
                Revenue = group.Sum(row => row.Amount)
            })
            .OrderByDescending(row => row.Revenue)
            .ToListAsync(cancellationToken);
    }

    private sealed class AppointmentReportRow
    {
        public int Id { get; set; }
        public int SalonId { get; set; }
        public string UserName { get; set; } = string.Empty;
        public string SalonName { get; set; } = string.Empty;
        public string EmployeeName { get; set; } = string.Empty;
        public string ServiceName { get; set; } = string.Empty;
        public DateTime StartTime { get; set; }
        public string Status { get; set; } = string.Empty;
        public decimal Price { get; set; }
    }

    private sealed class SalonRevenueReportRow
    {
        public string SalonName { get; set; } = string.Empty;
        public int PaymentCount { get; set; }
        public decimal Revenue { get; set; }
    }
}
