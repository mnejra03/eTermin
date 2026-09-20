using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Infrastructure.Services;

public class RecommendationService : IRecommendationService
{
    private readonly eTerminDbContext _context;

    public RecommendationService(eTerminDbContext context)
    {
        _context = context;
    }

    public async Task<List<RecommendationDto>>
        GetRecommendationsAsync(int userId)
    {
        var bookedServiceIds = await _context.Appointments
            .Where(x =>
                x.UserId == userId &&
                x.Status != "Cancelled")
            .Select(x => x.ServiceId)
            .Distinct()
            .ToListAsync();

        var services = await _context.Services
            .Where(x =>
                x.IsActive &&
                !bookedServiceIds.Contains(x.Id))
            .ToListAsync();

        if (!bookedServiceIds.Any())
        {
            return await GetPopularServicesAsync(services);
        }

        var bookedServices = await _context.Services
            .Where(x =>
                bookedServiceIds.Contains(x.Id))
            .ToListAsync();

        var bookedServiceNames = bookedServices
            .Select(x => x.Name.ToLower())
            .ToList();

        var recommendations = services
            .Where(service =>
                bookedServiceNames.Any(name =>
                    service.Name
                        .ToLower()
                        .Contains(name) ||
                    name.Contains(
                        service.Name.ToLower())))
            .ToList();

        if (!recommendations.Any())
        {
            recommendations = services
                .Take(5)
                .ToList();
        }

        return await MapToDtoAsync(recommendations);
    }

    private async Task<List<RecommendationDto>>
        GetPopularServicesAsync(
            List<eTermin.Domain.Entities.Service> services)
    {
        var popularServiceIds = await _context.Appointments
            .Where(x => x.Status != "Cancelled")
            .GroupBy(x => x.ServiceId)
            .OrderByDescending(x => x.Count())
            .Select(x => x.Key)
            .Take(5)
            .ToListAsync();

        var popularServices = services
            .Where(x =>
                popularServiceIds.Contains(x.Id))
            .ToList();

        return await MapToDtoAsync(popularServices);
    }

    private async Task<List<RecommendationDto>>
        MapToDtoAsync(
            List<eTermin.Domain.Entities.Service> services)
    {
        var salonIds = services
            .Select(x => x.SalonId)
            .Distinct()
            .ToList();

        var salons = await _context.Salons
            .Where(x => salonIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, x => x.Name);

        return services
            .Select(service => new RecommendationDto
            {
                ServiceId = service.Id,
                ServiceName = service.Name,
                Description = service.Description,
                DurationInMinutes =
                    service.DurationInMinutes,
                Price = service.Price,
                SalonId = service.SalonId,
                SalonName =
                    salons.ContainsKey(service.SalonId)
                        ? salons[service.SalonId]
                        : string.Empty
            })
            .ToList();
    }
}