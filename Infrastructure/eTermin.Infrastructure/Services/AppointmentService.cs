using eTermin.Api.DTOs;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class AppointmentService : IAppointmentService
{
    private readonly eTerminDbContext _context;

    public AppointmentService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<AppointmentDto>> GetAllAsync()
    {
       return await _context.Appointments
    .Select(a => new AppointmentDto
    {
        Id = a.Id,
        UserId = a.UserId,
        SalonId = a.SalonId,
        EmployeeId = a.EmployeeId,
        ServiceId = a.ServiceId,
        StartTime = a.StartTime,
        EndTime = a.EndTime,
        Status = a.Status,
        Price = a.Price,
        CreatedAt = a.CreatedAt
    })
    .ToListAsync();
    }

    public async Task<List<AppointmentListDto>> GetAllForListAsync()
    {
        return await _context.Appointments
            .Select(a => new AppointmentListDto
            {
                Id = a.Id,

                UserId = a.UserId,

                SalonId = a.SalonId,

                EmployeeId = a.EmployeeId,

                ServiceId = a.ServiceId,

                UserName = _context.Users
                    .Where(u => u.Id == a.UserId)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault() ?? "",

                SalonName = _context.Salons
                    .Where(s => s.Id == a.SalonId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                EmployeeName = _context.Employees
                    .Where(e => e.Id == a.EmployeeId)
                    .Select(e => e.FirstName + " " + e.LastName)
                    .FirstOrDefault() ?? "",

                ServiceName = _context.Services
                    .Where(s => s.Id == a.ServiceId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                StartTime = a.StartTime,

                EndTime = a.EndTime,

                Status = a.Status,

                Price = a.Price,

                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }
    public async Task<List<AppointmentListDto>> GetMyForListAsync(
     int userId)
    {
        return await _context.Appointments
            .Where(a => a.UserId == userId)
            .Select(a => new AppointmentListDto
            {
                Id = a.Id,

                UserId = a.UserId,

                SalonId = a.SalonId,

                EmployeeId = a.EmployeeId,

                ServiceId = a.ServiceId,

                UserName = _context.Users
                    .Where(u => u.Id == a.UserId)
                    .Select(u => u.FirstName + " " + u.LastName)
                    .FirstOrDefault() ?? "",

                SalonName = _context.Salons
                    .Where(s => s.Id == a.SalonId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                EmployeeName = _context.Employees
                    .Where(e => e.Id == a.EmployeeId)
                    .Select(e => e.FirstName + " " + e.LastName)
                    .FirstOrDefault() ?? "",

                ServiceName = _context.Services
                    .Where(s => s.Id == a.ServiceId)
                    .Select(s => s.Name)
                    .FirstOrDefault() ?? "",

                StartTime = a.StartTime,

                EndTime = a.EndTime,

                Status = a.Status,

                Price = a.Price,

                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<AppointmentDto?> GetByIdAsync(int id)
    {
        return await _context.Appointments
            .Where(a => a.Id == id)
            .Select(a => new AppointmentDto
            {
                Id = a.Id,
                UserId = a.UserId,
                SalonId = a.SalonId,
                EmployeeId = a.EmployeeId,
                ServiceId = a.ServiceId,
                StartTime = a.StartTime,
                EndTime = a.EndTime,
                Status = a.Status,
                Price = a.Price,
                CreatedAt = a.CreatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<AppointmentDto> CreateAsync(AppointmentDto appointmentDto)
    {
        // Provjera korisnika
        var userExists = await _context.Users
            .AnyAsync(x => x.Id == appointmentDto.UserId);

        if (!userExists)
            throw new Exception("Korisnik ne postoji.");

        // Provjera salona
        var salonExists = await _context.Salons
            .AnyAsync(x => x.Id == appointmentDto.SalonId);

        if (!salonExists)
            throw new Exception("Salon ne postoji.");

        // Provjera zaposlenika
        var employee = await _context.Employees
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.EmployeeId);

        if (employee == null)
            throw new Exception("Zaposlenik ne postoji.");

        // Zaposlenik mora pripadati salonu
        if (employee.SalonId != appointmentDto.SalonId)
            throw new Exception("Zaposlenik ne pripada odabranom salonu.");

        // Provjera usluge
        var service = await _context.Services
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.ServiceId);

        if (service == null)
            throw new Exception("Usluga ne postoji.");

        // Usluga mora pripadati salonu
        if (service.SalonId != appointmentDto.SalonId)
            throw new Exception("Usluga ne pripada odabranom salonu.");

        // Provjera da zaposlenik pruža odabranu uslugu
        var employeeProvidesService =
            await _context.EmployeeServices.AnyAsync(es =>
                es.EmployeeId == appointmentDto.EmployeeId &&
                es.ServiceId == appointmentDto.ServiceId);

        if (!employeeProvidesService)
        {
            throw new Exception(
                "Odabrani zaposlenik ne pruža odabranu uslugu.");
        }

        // Računamo EndTime na osnovu trajanja usluge
        var startTime = appointmentDto.StartTime;

        var endTime = startTime.AddMinutes(
            service.DurationInMinutes);

        // Termin ne smije biti u prošlosti
        if (startTime <= DateTime.Now)
        {
            throw new Exception(
                "Termin ne može biti zakazan u prošlosti.");
        }

        // Provjera radnog vremena zaposlenika
        if (string.IsNullOrWhiteSpace(employee.WorkingHours))
        {
            throw new Exception(
                "Radno vrijeme zaposlenika nije definisano.");
        }

        var workingHoursParts =
            employee.WorkingHours.Split('-');

        if (workingHoursParts.Length != 2 ||
            !TimeSpan.TryParse(
                workingHoursParts[0],
                out var workStart) ||
            !TimeSpan.TryParse(
                workingHoursParts[1],
                out var workEnd))
        {
            throw new Exception(
                "Radno vrijeme mora biti u formatu HH:mm-HH:mm.");
        }

        var workDayStart =
            startTime.Date.Add(workStart);

        var workDayEnd =
            startTime.Date.Add(workEnd);

        if (startTime < workDayStart ||
            endTime > workDayEnd)
        {
            throw new Exception(
                "Termin nije unutar radnog vremena zaposlenika.");
        }

        // Provjera preklapanja termina
        var overlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.EmployeeId == appointmentDto.EmployeeId &&
                a.Status != "Cancelled" &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (overlappingAppointment)
            throw new Exception(
                "Zaposlenik već ima termin u odabranom vremenu.");

        // Provjera preklapanja termina za istog korisnika
        var userOverlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.UserId == appointmentDto.UserId &&
                a.Status != "Cancelled" &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (userOverlappingAppointment)
            throw new Exception(
                "Korisnik već ima termin u odabranom vremenu.");

        // Kreiranje termina
        var appointment = new Appointment
        {
            UserId = appointmentDto.UserId,
            SalonId = appointmentDto.SalonId,
            EmployeeId = appointmentDto.EmployeeId,
            ServiceId = appointmentDto.ServiceId,
            StartTime = startTime,
            EndTime = endTime,
            Status = "Pending",
            Price = service.Price,
            CreatedAt = DateTime.UtcNow
        };

        _context.Appointments.Add(appointment);

        // Prvo moramo sačuvati Appointment
        // kako bi SQL Server generisao njegov Id.
        await _context.SaveChangesAsync();

        // Tek sada appointment.Id postoji.
        var notification = new Notification
        {
            UserId = appointment.UserId,
            AppointmentId = appointment.Id,
            Title = "Termin uspješno rezervisan",
            Message =
                $"Vaš termin je uspješno rezervisan za {appointment.StartTime:dd.MM.yyyy. HH:mm}.",
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);

        // Čuvamo automatski kreiranu notifikaciju
        await _context.SaveChangesAsync();

        return new AppointmentDto
        {
            Id = appointment.Id,
            UserId = appointment.UserId,
            SalonId = appointment.SalonId,
            EmployeeId = appointment.EmployeeId,
            ServiceId = appointment.ServiceId,
            StartTime = appointment.StartTime,
            EndTime = appointment.EndTime,
            Status = appointment.Status,
            Price = appointment.Price,
            CreatedAt = appointment.CreatedAt
        };
    }

    public async Task<bool> UpdateAsync(
    int id,
    AppointmentDto appointmentDto)
    {
        var appointment = await _context.Appointments
            .FirstOrDefaultAsync(x => x.Id == id);

        if (appointment == null)
            return false;

        // Zapamtimo stari status
        var oldStatus = appointment.Status;

        // Provjera da salon postoji
        var salon = await _context.Salons
            .FirstOrDefaultAsync(x => x.Id == appointmentDto.SalonId);

        if (salon == null)
            throw new Exception("Salon ne postoji.");

        // Uzimamo NOVU odabranu uslugu
        var service = await _context.Services
            .FirstOrDefaultAsync(x =>
                x.Id == appointmentDto.ServiceId &&
                x.SalonId == appointmentDto.SalonId);

        if (service == null)
            throw new Exception(
                "Odabrana usluga ne postoji u odabranom salonu.");

        // Provjera da zaposlenik postoji
        var employee = await _context.Employees
            .FirstOrDefaultAsync(x =>
                x.Id == appointmentDto.EmployeeId &&
                x.SalonId == appointmentDto.SalonId);

        if (employee == null)
            throw new Exception(
                "Odabrani zaposlenik ne pripada odabranom salonu.");

        var employeeProvidesService =
    await _context.EmployeeServices.AnyAsync(es =>
        es.EmployeeId == appointmentDto.EmployeeId &&
        es.ServiceId == appointmentDto.ServiceId);

        if (!employeeProvidesService)
        {
            throw new Exception(
                "Odabrani zaposlenik ne pruža odabranu uslugu.");
        }

        // Backend sam računa EndTime
        // prema trajanju NOVE usluge.
        var startTime = appointmentDto.StartTime;

        var endTime = startTime.AddMinutes(
            service.DurationInMinutes);

        // Provjera da li se mijenja raspored termina
        var scheduleChanged =
            appointment.StartTime != appointmentDto.StartTime ||
            appointment.SalonId != appointmentDto.SalonId ||
            appointment.EmployeeId != appointmentDto.EmployeeId ||
            appointment.ServiceId != appointmentDto.ServiceId;

        // Termin ne može biti pomjeren u prošlost.
        // Promjena samo statusa za već završeni termin je dozvoljena.
        if (scheduleChanged && startTime <= DateTime.Now)
        {
            throw new Exception(
                "Termin ne može biti zakazan u prošlosti.");
        }

        if (string.IsNullOrWhiteSpace(employee.WorkingHours))
        {
            throw new Exception(
                "Radno vrijeme zaposlenika nije definisano.");
        }

        var workingHoursParts =
            employee.WorkingHours.Split('-');

        if (workingHoursParts.Length != 2 ||
            !TimeSpan.TryParse(
                workingHoursParts[0],
                out var workStart) ||
            !TimeSpan.TryParse(
                workingHoursParts[1],
                out var workEnd))
        {
            throw new Exception(
                "Radno vrijeme mora biti u formatu HH:mm-HH:mm.");
        }

        var workDayStart =
            startTime.Date.Add(workStart);

        var workDayEnd =
            startTime.Date.Add(workEnd);

        if (startTime < workDayStart ||
            endTime > workDayEnd)
        {
            throw new Exception(
                "Termin nije unutar radnog vremena zaposlenika.");
        }

        // Provjera preklapanja za NOVOG zaposlenika
        var overlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.Id != id &&
                a.EmployeeId == appointmentDto.EmployeeId &&
                a.Status != "Cancelled" &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (overlappingAppointment)
        {
            throw new Exception(
                "Zaposlenik već ima termin u odabranom vremenu.");
        }

        // Ažuriranje termina
        appointment.SalonId = appointmentDto.SalonId;

        appointment.ServiceId = appointmentDto.ServiceId;

        appointment.EmployeeId = appointmentDto.EmployeeId;

        appointment.StartTime = startTime;

        appointment.EndTime = endTime;

        // Cijena dolazi iz odabrane usluge.
        // Admin je ne unosi ručno.
        appointment.Price = service.Price;

        if (!string.IsNullOrWhiteSpace(appointmentDto.Status))
        {
            var newStatus = appointmentDto.Status;

            var allowedStatuses = new[]
            {
        "Pending",
        "Confirmed",
        "Completed",
        "Cancelled"
    };

            if (!allowedStatuses.Contains(newStatus))
            {
                throw new Exception(
                    "Neispravan status termina.");
            }

            if (oldStatus == "Completed")
            {
                throw new Exception(
                    "Završen termin nije moguće mijenjati.");
            }

            if (oldStatus == "Cancelled")
            {
                throw new Exception(
                    "Otkazan termin nije moguće mijenjati.");
            }

            if (newStatus == "Completed" &&
                appointment.EndTime > DateTime.Now)
            {
                throw new Exception(
                    "Termin se ne može označiti kao završen prije njegovog završetka.");
            }

            appointment.Status = newStatus;
        }

        // Ako se status promijenio,
        // kreiramo automatsku notifikaciju.
        if (oldStatus != appointment.Status)
        {
            string? title = null;
            string? message = null;

            if (appointment.Status == "Confirmed")
            {
                title = "Termin potvrđen";

                message =
                    $"Vaš termin je potvrđen za " +
                    $"{appointment.StartTime:dd.MM.yyyy. HH:mm}.";
            }
            else if (appointment.Status == "Cancelled")
            {
                title = "Termin otkazan";

                message =
                    $"Vaš termin za " +
                    $"{appointment.StartTime:dd.MM.yyyy. HH:mm} je otkazan.";
            }

            if (title != null && message != null)
            {
                var notification = new Notification
                {
                    UserId = appointment.UserId,
                    AppointmentId = appointment.Id,
                    Title = title,
                    Message = message,
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                };

                _context.Notifications.Add(notification);
            }
        }

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var appointment = await _context.Appointments
            .FindAsync(id);

        if (appointment == null)
            return false;

        _context.Appointments.Remove(appointment);

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<List<AvailableSlotDto>> GetAvailableSlotsAsync(
    int salonId,
    int employeeId,
    int serviceId,
    DateTime date)
    {
        // Provjera zaposlenika
        var employee = await _context.Employees
            .FirstOrDefaultAsync(x =>
                x.Id == employeeId &&
                x.SalonId == salonId &&
                x.IsActive);

        if (employee == null)
            throw new Exception(
                "Zaposlenik ne postoji ili ne pripada odabranom salonu.");

        // Provjera usluge
        var service = await _context.Services
            .FirstOrDefaultAsync(x =>
                x.Id == serviceId &&
                x.SalonId == salonId &&
                x.IsActive);

        if (service == null)
            throw new Exception(
                "Usluga ne postoji ili ne pripada odabranom salonu.");

        // Za sada koristimo WorkingHours zaposlenika.
        // Očekivani format: "08:00-16:00"
        if (string.IsNullOrWhiteSpace(employee.WorkingHours))
            throw new Exception(
                "Radno vrijeme zaposlenika nije definisano.");

        var parts = employee.WorkingHours.Split('-');

        if (parts.Length != 2 ||
            !TimeSpan.TryParse(parts[0], out var workStart) ||
            !TimeSpan.TryParse(parts[1], out var workEnd))
        {
            throw new Exception(
                "Radno vrijeme mora biti u formatu HH:mm-HH:mm.");
        }

        var dayStart = date.Date.Add(workStart);
        var dayEnd = date.Date.Add(workEnd);

        // Uzimamo postojeće aktivne termine tog zaposlenika za taj dan
        var appointments = await _context.Appointments
            .Where(x =>
                x.EmployeeId == employeeId &&
                x.StartTime.Date == date.Date &&
                x.Status != "Cancelled")
            .OrderBy(x => x.StartTime)
            .ToListAsync();

        var availableSlots = new List<AvailableSlotDto>();

        var currentStart = dayStart;

        while (currentStart.AddMinutes(service.DurationInMinutes) <= dayEnd)
        {
            var currentEnd =
                currentStart.AddMinutes(service.DurationInMinutes);

            var overlaps = appointments.Any(a =>
                a.StartTime < currentEnd &&
                a.EndTime > currentStart);

            if (!overlaps)
            {
                availableSlots.Add(new AvailableSlotDto
                {
                    StartTime = currentStart,
                    EndTime = currentEnd
                });
            }

            currentStart = currentStart.AddMinutes(30);
        }

        return availableSlots;
    }

    public async Task<List<DashboardAppointmentDto>> GetDashboardAppointmentsAsync(
    DateTime date,
    int? salonId)
    {
        var query = _context.Appointments
            .Where(a =>
                a.StartTime.Date == date.Date &&
                a.Status != "Cancelled");

        if (salonId.HasValue)
        {
            query = query.Where(a =>
                a.SalonId == salonId.Value);
        }

        var appointments = await query
            .OrderBy(a => a.StartTime)
            .ToListAsync();

        var result = new List<DashboardAppointmentDto>();

        foreach (var appointment in appointments)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(x => x.Id == appointment.UserId);

            var salon = await _context.Salons
                .FirstOrDefaultAsync(x => x.Id == appointment.SalonId);

            var service = await _context.Services
                .FirstOrDefaultAsync(x => x.Id == appointment.ServiceId);

            result.Add(new DashboardAppointmentDto
            {
                Id = appointment.Id,

                UserName = user == null
                    ? "Nepoznat korisnik"
                    : $"{user.FirstName} {user.LastName}",

                SalonName = salon?.Name ?? "Nepoznat salon",

                ServiceName = service?.Name ?? "Nepoznata usluga",

                StartTime = appointment.StartTime,

                EndTime = appointment.EndTime,

                Status = appointment.Status,

                Price = appointment.Price
            });
        }

        return result;
    }

    public async Task<DashboardAvailableSlotsDto> GetDashboardAvailableSlotsAsync(
    DateTime date,
    int? salonId)
    {
        var employeesQuery = _context.Employees
            .Where(x => x.IsActive);

        if (salonId.HasValue)
        {
            employeesQuery = employeesQuery
                .Where(x => x.SalonId == salonId.Value);
        }

        var activeEmployees = await employeesQuery.ToListAsync();

        var activeServices = await _context.Services
            .Where(x => x.IsActive)
            .ToListAsync();

        var appointmentsQuery = _context.Appointments
            .Where(x =>
                x.StartTime.Date == date.Date &&
                x.Status != "Cancelled");

        if (salonId.HasValue)
        {
            appointmentsQuery = appointmentsQuery
                .Where(x => x.SalonId == salonId.Value);
        }

        var appointments = await appointmentsQuery.ToListAsync();

        int totalSlots = 0;
        int occupiedSlots = 0;

        foreach (var employee in activeEmployees)
        {
            if (string.IsNullOrWhiteSpace(employee.WorkingHours))
                continue;

            var parts = employee.WorkingHours.Split('-');

            if (parts.Length != 2 ||
                !TimeSpan.TryParse(parts[0], out var workStart) ||
                !TimeSpan.TryParse(parts[1], out var workEnd))
            {
                continue;
            }

            var dayStart = date.Date.Add(workStart);
            var dayEnd = date.Date.Add(workEnd);

            var employeeServices = activeServices
                .Where(x => x.SalonId == employee.SalonId)
                .ToList();

            if (!employeeServices.Any())
                continue;

            var currentStart = dayStart;

            while (currentStart.AddMinutes(30) <= dayEnd)
            {
                totalSlots++;
                currentStart = currentStart.AddMinutes(30);
            }

            var employeeAppointments = appointments
                .Where(x => x.EmployeeId == employee.Id)
                .ToList();

            foreach (var appointment in employeeAppointments)
            {
                var durationSlots = Math.Max(
                    1,
                    (int)Math.Ceiling(
                        (appointment.EndTime - appointment.StartTime)
                            .TotalMinutes / 30));

                occupiedSlots += durationSlots;
            }
        }

        occupiedSlots = Math.Min(
            occupiedSlots,
            totalSlots);

        var availableSlots = Math.Max(
            0,
            totalSlots - occupiedSlots);

        var percentage = totalSlots == 0
            ? 0
            : (int)Math.Round(
                availableSlots * 100.0 / totalSlots);

        return new DashboardAvailableSlotsDto
        {
            AvailableSlots = availableSlots,
            TotalSlots = totalSlots,
            OccupiedSlots = occupiedSlots,
            Percentage = percentage
        };
    }
}