using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class ServiceService : IServiceService
{
    private readonly eTerminDbContext _context;

    public ServiceService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<ServiceDto>> GetAllAsync()
    {
        return await _context.Services
            .Select(s => new ServiceDto
            {
                Id = s.Id,
                SalonId = s.SalonId,
                ServiceCategoryId = s.ServiceCategoryId,
                ServiceCategoryName = _context.ServiceCategories
                    .Where(category => category.Id == s.ServiceCategoryId)
                    .Select(category => category.Name)
                    .FirstOrDefault() ?? string.Empty,
                Name = s.Name,
                Description = s.Description,
                DurationInMinutes = s.DurationInMinutes,
                Price = s.Price,
                IsActive = s.IsActive
            })
            .ToListAsync();
    }

    public async Task<ServiceDto?> GetByIdAsync(int id)
    {
        return await _context.Services
            .Where(s => s.Id == id)
            .Select(s => new ServiceDto
            {
                Id = s.Id,
                SalonId = s.SalonId,
                ServiceCategoryId = s.ServiceCategoryId,
                ServiceCategoryName = _context.ServiceCategories
                    .Where(category => category.Id == s.ServiceCategoryId)
                    .Select(category => category.Name)
                    .FirstOrDefault() ?? string.Empty,
                Name = s.Name,
                Description = s.Description,
                DurationInMinutes = s.DurationInMinutes,
                Price = s.Price,
                IsActive = s.IsActive
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ServiceDto> CreateAsync(ServiceDto serviceDto)
    {
        if (!await _context.ServiceCategories.AnyAsync(
                category => category.Id == serviceDto.ServiceCategoryId))
            throw new InvalidOperationException(
                "Odabrana kategorija usluge ne postoji.");

        var service = new Service
        {
            SalonId = serviceDto.SalonId,
            ServiceCategoryId = serviceDto.ServiceCategoryId,
            Name = serviceDto.Name,
            Description = serviceDto.Description,
            DurationInMinutes = serviceDto.DurationInMinutes,
            Price = serviceDto.Price,
            IsActive = true
        };

        _context.Services.Add(service);

        await _context.SaveChangesAsync();

        return new ServiceDto
        {
            Id = service.Id,
            SalonId = service.SalonId,
            ServiceCategoryId = service.ServiceCategoryId,
            ServiceCategoryName = await _context.ServiceCategories
                .Where(category => category.Id == service.ServiceCategoryId)
                .Select(category => category.Name)
                .FirstAsync(),
            Name = service.Name,
            Description = service.Description,
            DurationInMinutes = service.DurationInMinutes,
            Price = service.Price,
            IsActive = service.IsActive
        };
    }

    public async Task<bool> UpdateAsync(int id, ServiceDto serviceDto)
    {
        var service = await _context.Services.FindAsync(id);

        if (service == null)
        {
            return false;
        }

        if (!await _context.ServiceCategories.AnyAsync(
                category => category.Id == serviceDto.ServiceCategoryId))
            throw new InvalidOperationException(
                "Odabrana kategorija usluge ne postoji.");

        if (service.SalonId != serviceDto.SalonId)
        {
            var hasFutureAppointments = await _context.Appointments
                .AnyAsync(appointment =>
                    appointment.ServiceId == id &&
                    appointment.StartTime > DateTime.Now &&
                    (appointment.Status == AppointmentStatuses.Pending ||
                     appointment.Status == AppointmentStatuses.Confirmed));

            if (hasFutureAppointments)
                throw new InvalidOperationException(
                    "Usluzi se ne može promijeniti salon dok ima buduće aktivne termine.");

            var hasEmployeesFromAnotherSalon = await _context.EmployeeServices
                .AnyAsync(employeeService =>
                    employeeService.ServiceId == id &&
                    employeeService.Employee.SalonId != serviceDto.SalonId);

            if (hasEmployeesFromAnotherSalon)
                throw new InvalidOperationException(
                    "Salon usluge se ne može promijeniti jer je dodijeljena zaposlenicima drugog salona.");
        }

        service.SalonId = serviceDto.SalonId;
        service.ServiceCategoryId = serviceDto.ServiceCategoryId;
        service.Name = serviceDto.Name;
        service.Description = serviceDto.Description;
        service.DurationInMinutes = serviceDto.DurationInMinutes;
        service.Price = serviceDto.Price;
        service.IsActive = serviceDto.IsActive;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var service =
            await _context.Services.FindAsync(id);

        if (service == null)
        {
            return false;
        }

        var hasAppointments =
            await _context.Appointments
                .AnyAsync(x => x.ServiceId == id);

        if (hasAppointments)
        {
            throw new InvalidOperationException(
                "Usluga se ne može obrisati jer je već korištena u postojećim terminima. " +
                "Umjesto brisanja, možete je deaktivirati.");
        }

        _context.Services.Remove(service);

        await _context.SaveChangesAsync();

        return true;
    }
}