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

        // Računamo EndTime na osnovu trajanja usluge
        var startTime = appointmentDto.StartTime;

        var endTime = startTime.AddMinutes(
            service.DurationInMinutes);

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

        // Uzimamo postojeću uslugu termina
        var service = await _context.Services
            .FirstOrDefaultAsync(x => x.Id == appointment.ServiceId);

        if (service == null)
            throw new Exception("Usluga ne postoji.");

        // Backend sam računa EndTime
        var startTime = appointmentDto.StartTime;

        var endTime = startTime.AddMinutes(
            service.DurationInMinutes);

        // Provjera preklapanja
        var overlappingAppointment =
            await _context.Appointments.AnyAsync(a =>
                a.Id != id &&
                a.EmployeeId == appointment.EmployeeId &&
                a.Status != "Cancelled" &&
                a.StartTime < endTime &&
                a.EndTime > startTime);

        if (overlappingAppointment)
            throw new Exception(
                "Zaposlenik već ima termin u odabranom vremenu.");

        // Mijenjamo samo dozvoljene podatke
        appointment.StartTime = startTime;
        appointment.EndTime = endTime;

        if (!string.IsNullOrWhiteSpace(appointmentDto.Status))
        {
            appointment.Status = appointmentDto.Status;
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
                    $"Vaš termin je potvrđen za {appointment.StartTime:dd.MM.yyyy. HH:mm}.";
            }
            else if (appointment.Status == "Cancelled")
            {
                title = "Termin otkazan";

                message =
                    $"Vaš termin za {appointment.StartTime:dd.MM.yyyy. HH:mm} je otkazan.";
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
}