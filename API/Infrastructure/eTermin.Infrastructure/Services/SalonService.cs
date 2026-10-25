using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class SalonService : ISalonService
{
    private readonly eTerminDbContext _context;

    public SalonService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<SalonDto>> GetAllAsync()
    {
        return await _context.Salons
            .Select(s => new SalonDto
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                Address = s.Address,
                City = s.City,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                ImageUrl = s.ImageUrl,
                IsActive = s.IsActive
            })
            .ToListAsync();
    }

    public async Task<SalonDto?> GetByIdAsync(int id)
    {
        return await _context.Salons
            .Where(s => s.Id == id)
            .Select(s => new SalonDto
            {
                Id = s.Id,
                Name = s.Name,
                Description = s.Description,
                Address = s.Address,
                City = s.City,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                ImageUrl = s.ImageUrl,
                IsActive = s.IsActive
            })
            .FirstOrDefaultAsync();
    }

    public async Task<SalonDto> CreateAsync(SalonDto salonDto)
    {
        var salon = new Salon
        {
            Name = salonDto.Name,
            Description = salonDto.Description,
            Address = salonDto.Address,
            City = salonDto.City,
            PhoneNumber = salonDto.PhoneNumber,
            Email = salonDto.Email,
            ImageUrl = salonDto.ImageUrl,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Salons.Add(salon);

        await _context.SaveChangesAsync();

        return new SalonDto
        {
            Id = salon.Id,
            Name = salon.Name,
            Description = salon.Description,
            Address = salon.Address,
            City = salon.City,
            PhoneNumber = salon.PhoneNumber,
            Email = salon.Email,
            ImageUrl = salon.ImageUrl,
            IsActive = salon.IsActive
        };
    }

    public async Task<bool> UpdateAsync(int id, SalonDto salonDto)
    {
        var salon = await _context.Salons.FindAsync(id);

        if (salon == null)
        {
            return false;
        }

        salon.Name = salonDto.Name;
        salon.Description = salonDto.Description;
        salon.Address = salonDto.Address;
        salon.City = salonDto.City;
        salon.PhoneNumber = salonDto.PhoneNumber;
        salon.Email = salonDto.Email;
        salon.ImageUrl = salonDto.ImageUrl;
        salon.IsActive = salonDto.IsActive;

        await _context.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var salon = await _context.Salons.FindAsync(id);

        if (salon == null)
        {
            return false;
        }

        _context.Salons.Remove(salon);

        await _context.SaveChangesAsync();

        return true;
    }
}