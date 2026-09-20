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
            .FindAsync(id);

        if (appointment == null)
            return false;

        appointment.StartTime = appointmentDto.StartTime;
        appointment.Status = appointmentDto.Status;

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
}