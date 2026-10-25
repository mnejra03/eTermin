using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class CityService : ICityService
{
    private readonly eTerminDbContext _context;

    public CityService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<CityDto>> GetAllAsync() =>
        await _context.Cities
            .OrderBy(city => city.Name)
            .Select(city => new CityDto { Id = city.Id, Name = city.Name })
            .ToListAsync();

    public async Task<CityDto?> GetByIdAsync(int id) =>
        await _context.Cities
            .Where(city => city.Id == id)
            .Select(city => new CityDto { Id = city.Id, Name = city.Name })
            .FirstOrDefaultAsync();

    public async Task<CityDto> CreateAsync(CityDto cityDto)
    {
        var name = cityDto.Name.Trim();
        if (await _context.Cities.AnyAsync(city => city.Name == name))
            throw new InvalidOperationException(
                "Grad s ovim nazivom već postoji.");

        var city = new City { Name = name };
        _context.Cities.Add(city);
        await _context.SaveChangesAsync();
        return new CityDto { Id = city.Id, Name = city.Name };
    }

    public async Task<bool> UpdateAsync(int id, CityDto cityDto)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city == null)
            return false;

        var name = cityDto.Name.Trim();
        if (await _context.Cities.AnyAsync(
                existing => existing.Id != id && existing.Name == name))
            throw new InvalidOperationException(
                "Grad s ovim nazivom već postoji.");

        city.Name = name;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var city = await _context.Cities.FindAsync(id);
        if (city == null)
            return false;

        if (await _context.Salons.AnyAsync(salon => salon.CityId == id))
            throw new InvalidOperationException(
                "Grad se ne može obrisati jer ga koristi jedan ili više salona.");

        _context.Cities.Remove(city);
        await _context.SaveChangesAsync();
        return true;
    }
}
