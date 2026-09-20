using eTermin.Application.DTOs;
using eTermin.Application.Services;
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

    public async Task<DashboardStatisticsDto>
        GetDashboardStatisticsAsync(
            DateTime? from,
            DateTime? to,
            int? salonId)
    {
        var appointmentsQuery =
            _context.Appointments
                .AsQueryable();

        if (from.HasValue)
        {
            appointmentsQuery =
                appointmentsQuery.Where(x =>
                    x.StartTime >= from.Value);
        }

        if (to.HasValue)
        {
            var endDate = to.Value.Date.AddDays(1);

            appointmentsQuery =
                appointmentsQuery.Where(x =>
                    x.StartTime < endDate);
        }

        if (salonId.HasValue)
        {
            appointmentsQuery =
                appointmentsQuery.Where(x =>
                    x.SalonId == salonId.Value);
        }

        var appointments =
            await appointmentsQuery
                .Where(x => x.Status != "Cancelled")
                .ToListAsync();

        var totalAppointments =
            appointments.Count;

        var totalRevenue =
            appointments.Sum(x => x.Price);

        var totalUsers =
            await _context.Users.CountAsync();

        var totalSalonsQuery =
            _context.Salons
                .Where(x => x.IsActive);

        if (salonId.HasValue)
        {
            totalSalonsQuery =
                totalSalonsQuery.Where(x =>
                    x.Id == salonId.Value);
        }

        var totalSalons =
            await totalSalonsQuery.CountAsync();

        var mostPopularService =
            appointments
                .GroupBy(x => x.ServiceId)
                .OrderByDescending(g => g.Count())
                .FirstOrDefault();

        string? serviceName = null;
        var serviceCount = 0;

        if (mostPopularService != null)
        {
            serviceCount =
                mostPopularService.Count();

            var service =
                await _context.Services
                    .FirstOrDefaultAsync(x =>
                        x.Id ==
                        mostPopularService.Key);

            serviceName =
                service?.Name;
        }

        return new DashboardStatisticsDto
        {
            TotalAppointments = totalAppointments,
            TotalUsers = totalUsers,
            TotalSalons = totalSalons,
            TotalRevenue = totalRevenue,
            MostPopularService = serviceName,
            MostPopularServiceCount = serviceCount
        };
    }
}