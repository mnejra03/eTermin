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
        int? salonId,
        string? status)
    {
        // ==========================================
        // APPOINTMENTS QUERY
        // ==========================================

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

        // Ako je odabran salon,
        // uzimamo samo njegove termine.
        if (salonId.HasValue)
        {
            appointmentsQuery =
                appointmentsQuery.Where(x =>
                    x.SalonId == salonId.Value);
        }

       

        // ==========================================
        // SVI TERMINI ZA GRAF STATUSA
        // ==========================================

        var allAppointments =
            await appointmentsQuery
                .ToListAsync();



        // ==========================================
        // TERMINI PREMA ODABRANOM STATUSU
        // ==========================================

        // All statuses -> samo Completed termini
        // Odabrani status -> samo termini tog statusa
        var appointments =
            allAppointments
                .Where(x =>
                    string.IsNullOrWhiteSpace(status) ||
                    status == "All statuses"
                        ? x.Status == "Completed"
                        : x.Status == status)
                .ToList();


        // ==========================================
        // UKUPAN BROJ REZERVACIJA
        // ==========================================

        var totalAppointments =
            appointments.Count;


        // ==========================================
        // UKUPAN PRIHOD
        // ==========================================

        var totalRevenue = allAppointments
    .Where(x => x.Status == "Completed")
    .Sum(x => x.Price);


        // ==========================================
        // KORISNICI
        // ==========================================

        int totalUsers;

        if (salonId.HasValue)
        {
            // Kada je odabran salon,
            // brojimo jedinstvene korisnike
            // koji imaju rezervaciju u tom salonu.

            totalUsers =
                appointments
                    .Select(x => x.UserId)
                    .Distinct()
                    .Count();
        }
        else
        {
            // "Svi saloni" -> svi korisnici sistema.

            totalUsers =
                await _context.Users.CountAsync();
        }


        // ==========================================
        // SALONI
        // ==========================================

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


        // ==========================================
        // NAJPOPULARNIJA USLUGA
        // ==========================================

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
                        x.Id == mostPopularService.Key);

            serviceName =
                service?.Name;
        }


        var reservationsByService =
    appointments
        .GroupBy(x => x.ServiceId)
        .Select(g => new ServiceReservationDto
        {
            ServiceName =
                _context.Services
                    .Where(s => s.Id == g.Key)
                    .Select(s => s.Name)
                    .FirstOrDefault()
                    ?? "Nepoznata usluga",

            Count = g.Count()
        })
        .OrderByDescending(x => x.Count)
        .ToList();
        // ==========================================
        // NAJAKTIVNIJI KORISNIK
        // ==========================================

        string? activeUserName = null;
        var activeUserCount = 0;

        var mostActiveUser =
            appointments
                .GroupBy(x => x.UserId)
                .OrderByDescending(g => g.Count())
                .FirstOrDefault();

        if (mostActiveUser != null)
        {
            activeUserCount = mostActiveUser.Count();

            var user = await _context.Users
                .FirstOrDefaultAsync(x =>
                    x.Id == mostActiveUser.Key);

            if (user != null)
            {
                activeUserName =
                    $"{user.FirstName} {user.LastName}";
            }
        }

        // ==========================================
        // NAJAKTIVNIJI SALON
        // ==========================================

        string? activeSalonName = null;
        var activeSalonCount = 0;

        var mostActiveSalon =
            appointments
                .GroupBy(x => x.SalonId)
                .OrderByDescending(g => g.Count())
                .FirstOrDefault();

        if (mostActiveSalon != null)
        {
            activeSalonCount = mostActiveSalon.Count();

            var salon = await _context.Salons
                .FirstOrDefaultAsync(x =>
                    x.Id == mostActiveSalon.Key);

            if (salon != null)
            {
                activeSalonName = salon.Name;
            }
        }


        // ==========================================
        // REZERVACIJE PO DANIMA
        // ==========================================

        var reservationsByDay = new List<DailyReservationDto>();

        if (from.HasValue && to.HasValue)
        {
            var startDate = from.Value.Date;
            var endDate = to.Value.Date.AddDays(1);

            for (var date = startDate;
                 date < endDate;
                 date = date.AddDays(1))
            {
                var count =
                    appointments.Count(x =>
                        x.StartTime.Date == date);

                reservationsByDay.Add(
                    new DailyReservationDto
                    {
                        Date = date,
                        Count = count
                    });
            }
        }


        // ==========================================
        // REZERVACIJE PO STATUSU
        // ==========================================

        var reservationsByStatus =
    allAppointments
        .GroupBy(x => x.Status)
        .Select(g => new ReservationStatusDto
        {
            Status = g.Key,
            Count = g.Count()
        })
        .ToList();


        // ==========================================
        // REZULTAT
        // ==========================================

        return new DashboardStatisticsDto
        {
            TotalAppointments =
         totalAppointments,

            TotalUsers =
         totalUsers,

            TotalSalons =
         totalSalons,

            TotalRevenue =
         totalRevenue,

            MostPopularService =
         serviceName,

            MostPopularServiceCount =
         serviceCount,

            MostActiveUser =
         activeUserName,

            MostActiveUserCount =
         activeUserCount,

            MostActiveSalon =
         activeSalonName,

            MostActiveSalonCount =
         activeSalonCount,

            ReservationsByDay =
         reservationsByDay,

            ReservationsByStatus =
         reservationsByStatus,

         ReservationsByService =
    reservationsByService
        };
    } 
}
    