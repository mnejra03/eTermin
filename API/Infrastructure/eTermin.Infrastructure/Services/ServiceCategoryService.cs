using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Entities;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class ServiceCategoryService : IServiceCategoryService
{
    private readonly eTerminDbContext _context;

    public ServiceCategoryService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<ServiceCategoryDto>> GetAllAsync(
        int page,
        int pageSize) =>
        await _context.ServiceCategories
            .OrderBy(category => category.Name)
            .Select(category => new ServiceCategoryDto
            {
                Id = category.Id,
                Name = category.Name,
                Description = category.Description
            })
            .ToPagedResultAsync(page, pageSize);

    public async Task<ServiceCategoryDto?> GetByIdAsync(int id) =>
        await _context.ServiceCategories
            .Where(category => category.Id == id)
            .Select(category => new ServiceCategoryDto
            {
                Id = category.Id,
                Name = category.Name,
                Description = category.Description
            })
            .FirstOrDefaultAsync();

    public async Task<ServiceCategoryDto> CreateAsync(ServiceCategoryDto categoryDto)
    {
        var name = categoryDto.Name.Trim();
        if (await _context.ServiceCategories.AnyAsync(
                category => category.Name == name))
            throw new BusinessException(
                "Kategorija s ovim nazivom već postoji.");

        var category = new ServiceCategory
        {
            Name = name,
            Description = categoryDto.Description.Trim()
        };
        _context.ServiceCategories.Add(category);
        await _context.SaveChangesAsync();
        return new ServiceCategoryDto
        {
            Id = category.Id,
            Name = category.Name,
            Description = category.Description
        };
    }

    public async Task<bool> UpdateAsync(int id, ServiceCategoryDto categoryDto)
    {
        var category = await _context.ServiceCategories.FindAsync(id);
        if (category == null)
            return false;

        var name = categoryDto.Name.Trim();
        if (await _context.ServiceCategories.AnyAsync(
                existing => existing.Id != id && existing.Name == name))
            throw new BusinessException(
                "Kategorija s ovim nazivom već postoji.");

        category.Name = name;
        category.Description = categoryDto.Description.Trim();
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        var category = await _context.ServiceCategories.FindAsync(id);
        if (category == null)
            return false;

        if (await _context.Services.AnyAsync(
                service => service.ServiceCategoryId == id))
            throw new BusinessException(
                "Kategorija se ne može obrisati jer je dodijeljena jednoj ili više usluga.");

        _context.ServiceCategories.Remove(category);
        await _context.SaveChangesAsync();
        return true;
    }
}
