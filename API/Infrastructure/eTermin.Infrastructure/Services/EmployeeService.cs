using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using EmployeeServiceEntity = eTermin.Domain.Entities.EmployeeService;

namespace eTermin.Infrastructure.Services;

public class EmployeeService : IEmployeeService
{
    private readonly eTerminDbContext _context;

    public EmployeeService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<EmployeeDto>> GetAllAsync(
        int page,
        int pageSize)
    {
        return await _context.Employees
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                SalonId = e.SalonId,
                FirstName = e.FirstName,
                LastName = e.LastName,
                Email = e.Email,
                PhoneNumber = e.PhoneNumber,
                Position = e.Position,
                WorkingSchedule = e.WorkingSchedule
                    .Select(hours => new EmployeeWorkingHourDto
                    {
                        DayOfWeek = hours.DayOfWeek,
                        StartTime = hours.StartTime,
                        EndTime = hours.EndTime
                    })
                    .ToList(),
                IsActive = e.IsActive,

                ServiceIds = e.EmployeeServices
                    .Select(es => es.ServiceId)
                    .ToList()
            })
            .OrderBy(employee => employee.LastName)
            .ThenBy(employee => employee.FirstName)
            .ThenBy(employee => employee.Id)
            .ToPagedResultAsync(page, pageSize);
    }

    public async Task<EmployeeDto?> GetByIdAsync(int id)
    {
        return await _context.Employees
            .Where(e => e.Id == id)
            .Select(e => new EmployeeDto
            {
                Id = e.Id,
                SalonId = e.SalonId,
                FirstName = e.FirstName,
                LastName = e.LastName,
                Email = e.Email,
                PhoneNumber = e.PhoneNumber,
                Position = e.Position,
                WorkingSchedule = e.WorkingSchedule
                    .Select(hours => new EmployeeWorkingHourDto
                    {
                        DayOfWeek = hours.DayOfWeek,
                        StartTime = hours.StartTime,
                        EndTime = hours.EndTime
                    })
                    .ToList(),
                IsActive = e.IsActive,

                ServiceIds = e.EmployeeServices
                    .Select(es => es.ServiceId)
                    .ToList()
            })
            .FirstOrDefaultAsync();
    }

    public async Task<EmployeeDto> CreateAsync(EmployeeDto employeeDto)
    {
        ValidateWorkingSchedule(employeeDto.WorkingSchedule);
        await ValidateServiceAssignmentsAsync(
            employeeDto.SalonId,
            employeeDto.ServiceIds);

        var employee = new Employee
        {
            SalonId = employeeDto.SalonId,
            FirstName = employeeDto.FirstName,
            LastName = employeeDto.LastName,
            Email = employeeDto.Email,
            PhoneNumber = employeeDto.PhoneNumber,
            Position = employeeDto.Position,
            IsActive = true
        };

        _context.Employees.Add(employee);

        await _context.SaveChangesAsync();

        var workingSchedule = employeeDto.WorkingSchedule
            .Select(hours => new EmployeeWorkingHour
            {
                EmployeeId = employee.Id,
                DayOfWeek = hours.DayOfWeek,
                StartTime = hours.StartTime,
                EndTime = hours.EndTime
            })
            .ToList();
        _context.EmployeeWorkingHours.AddRange(workingSchedule);

        if (employeeDto.ServiceIds != null &&
            employeeDto.ServiceIds.Count > 0)
        {
            var employeeServices =
    employeeDto.ServiceIds
        .Distinct()
        .Select(serviceId => new EmployeeServiceEntity
        {
            EmployeeId = employee.Id,
            ServiceId = serviceId
        })
        .ToList();

            _context.EmployeeServices.AddRange(employeeServices);

        }

        await _context.SaveChangesAsync();

        return new EmployeeDto
        {
            Id = employee.Id,
            SalonId = employee.SalonId,
            FirstName = employee.FirstName,
            LastName = employee.LastName,
            Email = employee.Email,
            PhoneNumber = employee.PhoneNumber,
            Position = employee.Position,
            WorkingSchedule = employeeDto.WorkingSchedule,
            IsActive = employee.IsActive,
            ServiceIds = employeeDto.ServiceIds ?? new List<int>()
        };
    }

    public async Task<bool> UpdateAsync(
    int id,
    EmployeeDto employeeDto)
    {
        var employee =
            await _context.Employees
                .FirstOrDefaultAsync(e => e.Id == id);

        if (employee == null)
        {
            return false;
        }

        ValidateWorkingSchedule(employeeDto.WorkingSchedule);

        if (employee.SalonId != employeeDto.SalonId)
        {
            var hasFutureAppointments = await _context.Appointments
                .AnyAsync(appointment =>
                    appointment.EmployeeId == id &&
                    appointment.StartTime > DateTime.Now &&
                    (appointment.Status == AppointmentStatuses.Pending ||
                     appointment.Status == AppointmentStatuses.Confirmed));

            if (hasFutureAppointments)
                throw new BusinessException(
                    "Zaposleniku se ne može promijeniti salon dok ima buduće aktivne termine.");
        }

        await ValidateServiceAssignmentsAsync(
            employeeDto.SalonId,
            employeeDto.ServiceIds);

        employee.SalonId = employeeDto.SalonId;
        employee.FirstName = employeeDto.FirstName;
        employee.LastName = employeeDto.LastName;
        employee.Email = employeeDto.Email;
        employee.PhoneNumber = employeeDto.PhoneNumber;
        employee.Position = employeeDto.Position;
        employee.IsActive = employeeDto.IsActive;

        var existingSchedule = await _context.EmployeeWorkingHours
            .Where(hours => hours.EmployeeId == id)
            .ToListAsync();

        var submittedSchedule = employeeDto.WorkingSchedule
            .ToDictionary(hours => hours.DayOfWeek);
        foreach (var existingHours in existingSchedule)
        {
            if (submittedSchedule.Remove(
                    existingHours.DayOfWeek,
                    out var updatedHours))
            {
                existingHours.StartTime = updatedHours.StartTime;
                existingHours.EndTime = updatedHours.EndTime;
            }
            else
            {
                _context.EmployeeWorkingHours.Remove(existingHours);
            }
        }

        var newWorkingHours = submittedSchedule.Values
            .Select(hours => new EmployeeWorkingHour
            {
                EmployeeId = id,
                DayOfWeek = hours.DayOfWeek,
                StartTime = hours.StartTime,
                EndTime = hours.EndTime
            })
            .ToList();
        _context.EmployeeWorkingHours.AddRange(newWorkingHours);

        // Ukloni stare veze prema uslugama
        var existingServices =
            await _context.EmployeeServices
                .Where(es => es.EmployeeId == id)
                .ToListAsync();

        _context.EmployeeServices.RemoveRange(existingServices);

        // Dodaj nove veze prema uslugama
        if (employeeDto.ServiceIds != null &&
            employeeDto.ServiceIds.Count > 0)
        {
            var newEmployeeServices =
    employeeDto.ServiceIds
        .Distinct()
        .Select(serviceId => new EmployeeServiceEntity
        {

            EmployeeId = id,
            ServiceId = serviceId
        })
        .ToList();

            _context.EmployeeServices.AddRange(
                newEmployeeServices);
        }

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var employee = await _context.Employees.FindAsync(id);

        if (employee == null)
        {
            return false;
        }

        var appointmentCount = await _context.Appointments
            .CountAsync(appointment => appointment.EmployeeId == id);

        if (appointmentCount > 0)
            throw new BusinessException(
                $"Zaposlenik se ne može obrisati jer ima {appointmentCount} povezanih termina. " +
                "Umjesto brisanja, deaktivirajte zaposlenika postavljanjem polja IsActive na false.");

        _context.Employees.Remove(employee);

        await _context.SaveChangesAsync();

        return true;
    }

    private async Task ValidateServiceAssignmentsAsync(
        int salonId,
        IReadOnlyCollection<int>? serviceIds)
    {
        var distinctServiceIds = serviceIds?.Distinct().ToArray() ?? [];
        if (distinctServiceIds.Length == 0)
            return;

        var services = await _context.Services
            .Where(service => distinctServiceIds.Contains(service.Id))
            .Select(service => new { service.Id, service.SalonId })
            .ToListAsync();

        if (services.Count != distinctServiceIds.Length ||
            services.Any(service => service.SalonId != salonId))
        {
            throw new BusinessException(
                "Sve odabrane usluge moraju postojati i pripadati istom salonu kao zaposlenik.");
        }
    }

    private static void ValidateWorkingSchedule(
        IReadOnlyCollection<EmployeeWorkingHourDto>? schedule)
    {
        if (schedule == null)
            throw new BusinessException(
                "Raspored radnog vremena je obavezan (može biti prazan za neradne dane).");

        if (schedule.Any(x => !Enum.IsDefined(x.DayOfWeek)) ||
            schedule.Select(x => x.DayOfWeek).Distinct().Count() != schedule.Count)
            throw new BusinessException(
                "Raspored može sadržavati najviše jedan zapis za svaki dan u sedmici.");

        if (schedule.Any(x => x.StartTime < TimeSpan.Zero ||
                              x.EndTime > TimeSpan.FromDays(1) ||
                              x.EndTime <= x.StartTime))
            throw new BusinessException(
                "Vrijeme završetka mora biti nakon početka unutar istog dana.");
    }
}
