using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class StatisticsService : IStatisticsService
{
    private readonly eTerminDbContext _context;

    public StatisticsService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardStatisticsDto> GetDashboardStatisticsAsync(
        DateTime? from,
        DateTime? to,
        int? salonId,
        string? status)
    {
        var allAppointments = ApplyFilters(
            _context.Appointments.AsNoTracking(),
            from,
            to,
            salonId);

        var selectedAppointments = allAppointments;
        if (!string.IsNullOrWhiteSpace(status) &&
            status != "All statuses" &&
            status != "Svi statusi")
        {
            selectedAppointments = selectedAppointments
                .Where(appointment => appointment.Status == status);
        }

        var totalAppointments = await selectedAppointments.CountAsync();
        var totalUsers = salonId.HasValue
            ? await selectedAppointments
                .Select(appointment => appointment.UserId)
                .Distinct()
                .CountAsync()
            : await _context.Users.CountAsync();

        var salonsQuery = _context.Salons
            .Where(salon => salon.IsActive);
        if (salonId.HasValue)
            salonsQuery = salonsQuery.Where(salon => salon.Id == salonId.Value);

        var totalSalons = await salonsQuery.CountAsync();

        var payments = from payment in _context.Payments.AsNoTracking()
                       join appointment in _context.Appointments.AsNoTracking()
                           on payment.AppointmentId equals appointment.Id
                       where payment.Status == PaymentStatuses.Completed
                       select new
                       {
                           payment.Amount,
                           appointment.StartTime,
                           appointment.SalonId
                       };
        if (from.HasValue)
            payments = payments.Where(payment =>
                payment.StartTime >= from.Value.Date);
        if (to.HasValue)
            payments = payments.Where(payment =>
                payment.StartTime < to.Value.Date);
        if (salonId.HasValue)
            payments = payments.Where(payment =>
                payment.SalonId == salonId.Value);

        var totalRevenue = await payments
            .Select(payment => payment.Amount)
            .DefaultIfEmpty()
            .SumAsync();

        var serviceStatistics = await (
                from appointment in selectedAppointments
                join service in _context.Services.AsNoTracking()
                    on appointment.ServiceId equals service.Id
                group appointment by new { service.Id, service.Name }
                into serviceGroup
                select new ServiceReservationDto
                {
                    ServiceName = serviceGroup.Key.Name,
                    Count = serviceGroup.Count()
                })
            .OrderByDescending(item => item.Count)
            .ThenBy(item => item.ServiceName)
            .ToListAsync();

        var mostActiveUser = await (
                from appointment in selectedAppointments
                join user in _context.Users.AsNoTracking()
                    on appointment.UserId equals user.Id
                group appointment by new
                {
                    user.Id,
                    user.FirstName,
                    user.LastName
                }
                into userGroup
                orderby userGroup.Count() descending
                select new
                {
                    Name = userGroup.Key.FirstName + " " + userGroup.Key.LastName,
                    Count = userGroup.Count()
                })
            .FirstOrDefaultAsync();

        var mostActiveSalon = await (
                from appointment in selectedAppointments
                join salon in _context.Salons.AsNoTracking()
                    on appointment.SalonId equals salon.Id
                group appointment by new { salon.Id, salon.Name }
                into salonGroup
                orderby salonGroup.Count() descending
                select new
                {
                    Name = salonGroup.Key.Name,
                    Count = salonGroup.Count()
                })
            .FirstOrDefaultAsync();

        var reservationsByStatus = await allAppointments
            .GroupBy(appointment => appointment.Status)
            .Select(group => new ReservationStatusDto
            {
                Status = group.Key,
                Count = group.Count()
            })
            .OrderBy(item => item.Status)
            .ToListAsync();

        var reservationsByDay = new List<DailyReservationDto>();
        if (from.HasValue && to.HasValue)
        {
            var startDate = from.Value.Date;
            var endDate = to.Value.Date;
            var dailyCounts = await selectedAppointments
                .GroupBy(appointment => appointment.StartTime.Date)
                .Select(group => new
                {
                    Date = group.Key,
                    Count = group.Count()
                })
                .ToDictionaryAsync(item => item.Date, item => item.Count);

            for (var date = startDate; date < endDate; date = date.AddDays(1))
            {
                reservationsByDay.Add(new DailyReservationDto
                {
                    Date = date,
                    Count = dailyCounts.GetValueOrDefault(date)
                });
            }
        }

        var popularService = serviceStatistics.FirstOrDefault();

        return new DashboardStatisticsDto
        {
            TotalAppointments = totalAppointments,
            TotalUsers = totalUsers,
            TotalSalons = totalSalons,
            TotalRevenue = totalRevenue,
            MostPopularService = popularService?.ServiceName,
            MostPopularServiceCount = popularService?.Count ?? 0,
            MostActiveUser = mostActiveUser?.Name,
            MostActiveUserCount = mostActiveUser?.Count ?? 0,
            MostActiveSalon = mostActiveSalon?.Name,
            MostActiveSalonCount = mostActiveSalon?.Count ?? 0,
            ReservationsByDay = reservationsByDay,
            ReservationsByStatus = reservationsByStatus,
            ReservationsByService = serviceStatistics
        };
    }

    private static IQueryable<Appointment> ApplyFilters(
        IQueryable<Appointment> appointments,
        DateTime? from,
        DateTime? to,
        int? salonId)
    {
        if (from.HasValue)
            appointments = appointments.Where(appointment =>
                appointment.StartTime >= from.Value.Date);
        if (to.HasValue)
            appointments = appointments.Where(appointment =>
                appointment.StartTime < to.Value.Date);
        if (salonId.HasValue)
            appointments = appointments.Where(appointment =>
                appointment.SalonId == salonId.Value);

        return appointments;
    }
}
