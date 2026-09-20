using eTermin.Application.DTOs;
using eTermin.Application.Services;
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
        var service = new Service
        {
            SalonId = serviceDto.SalonId,
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

        service.SalonId = serviceDto.SalonId;
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
        var service = await _context.Services.FindAsync(id);

        if (service == null)
        {
            return false;
        }

        _context.Services.Remove(service);

        await _context.SaveChangesAsync();

        return true;
    }
}