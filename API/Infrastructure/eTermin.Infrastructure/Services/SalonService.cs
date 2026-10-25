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
                CityId = s.CityId,
                CityName = _context.Cities
                    .Where(city => city.Id == s.CityId)
                    .Select(city => city.Name)
                    .FirstOrDefault() ?? string.Empty,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                ImageUrl = s.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault() ?? string.Empty,
                Images = s.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => new SalonImageDto
                    {
                        Id = image.Id,
                        ImageUrl = image.ImageUrl,
                        SortOrder = image.SortOrder
                    })
                    .ToList(),
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
                CityId = s.CityId,
                CityName = _context.Cities
                    .Where(city => city.Id == s.CityId)
                    .Select(city => city.Name)
                    .FirstOrDefault() ?? string.Empty,
                PhoneNumber = s.PhoneNumber,
                Email = s.Email,
                ImageUrl = s.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => image.ImageUrl)
                    .FirstOrDefault() ?? string.Empty,
                Images = s.Images
                    .OrderBy(image => image.SortOrder)
                    .Select(image => new SalonImageDto
                    {
                        Id = image.Id,
                        ImageUrl = image.ImageUrl,
                        SortOrder = image.SortOrder
                    })
                    .ToList(),
                IsActive = s.IsActive
            })
            .FirstOrDefaultAsync();
    }

    public async Task<SalonDto> CreateAsync(SalonDto salonDto)
    {
        if (!await _context.Cities.AnyAsync(city => city.Id == salonDto.CityId))
            throw new InvalidOperationException("Odabrani grad ne postoji.");

        var salon = new Salon
        {
            Name = salonDto.Name,
            Description = salonDto.Description,
            Address = salonDto.Address,
            CityId = salonDto.CityId,
            PhoneNumber = salonDto.PhoneNumber,
            Email = salonDto.Email,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.Salons.Add(salon);

        await _context.SaveChangesAsync();

        ReplaceImages(salon, salonDto);
        await _context.SaveChangesAsync();
        return (await GetByIdAsync(salon.Id))!;
    }

    public async Task<bool> UpdateAsync(int id, SalonDto salonDto)
    {
        var salon = await _context.Salons
            .Include(existing => existing.Images)
            .FirstOrDefaultAsync(existing => existing.Id == id);

        if (salon == null)
        {
            return false;
        }

        if (!await _context.Cities.AnyAsync(city => city.Id == salonDto.CityId))
            throw new InvalidOperationException("Odabrani grad ne postoji.");

        salon.Name = salonDto.Name;
        salon.Description = salonDto.Description;
        salon.Address = salonDto.Address;
        salon.CityId = salonDto.CityId;
        salon.PhoneNumber = salonDto.PhoneNumber;
        salon.Email = salonDto.Email;
        salon.IsActive = salonDto.IsActive;
        ReplaceImages(salon, salonDto);

        await _context.SaveChangesAsync();

        return true;
    }

    private void ReplaceImages(Salon salon, SalonDto salonDto)
    {
        _context.SalonImages.RemoveRange(salon.Images);
        salon.Images.Clear();

        var images = salonDto.Images ??
            (string.IsNullOrWhiteSpace(salonDto.ImageUrl)
                ? new List<SalonImageDto>()
                : new List<SalonImageDto>
                {
                    new() { ImageUrl = salonDto.ImageUrl }
                });

        foreach (var image in images.Where(
                     item => !string.IsNullOrWhiteSpace(item.ImageUrl)))
        {
            salon.Images.Add(new SalonImage
            {
                SalonId = salon.Id,
                ImageUrl = image.ImageUrl.Trim(),
                SortOrder = image.SortOrder,
                CreatedAt = DateTime.UtcNow
            });
        }
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var salon = await _context.Salons.FindAsync(id);

        if (salon == null)
        {
            return false;
        }

        var employeeCount = await _context.Employees
            .CountAsync(employee => employee.SalonId == id);
        var serviceCount = await _context.Services
            .CountAsync(service => service.SalonId == id);
        var appointmentCount = await _context.Appointments
            .CountAsync(appointment => appointment.SalonId == id);

        if (employeeCount > 0 || serviceCount > 0 || appointmentCount > 0)
        {
            var reasons = new List<string>();
            if (employeeCount > 0)
                reasons.Add($"ima {employeeCount} zaposlenika");
            if (serviceCount > 0)
                reasons.Add($"ima {serviceCount} usluga");
            if (appointmentCount > 0)
                reasons.Add($"ima {appointmentCount} termina");

            throw new InvalidOperationException(
                $"Salon se ne može obrisati jer {string.Join(", ", reasons)}. " +
                "Umjesto brisanja, deaktivirajte salon postavljanjem polja IsActive na false.");
        }

        _context.Salons.Remove(salon);

        await _context.SaveChangesAsync();

        return true;
    }
}