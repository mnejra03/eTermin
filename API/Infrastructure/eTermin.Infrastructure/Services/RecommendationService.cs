using eTermin.Application.DTOs;
using eTermin.Application.Services;
using eTermin.Domain.Constants;
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
        var appointmentProfile = await _context.Appointments
            .Where(appointment =>
                appointment.UserId == userId &&
                appointment.Status != AppointmentStatuses.Cancelled)
            .Join(
                _context.Services,
                appointment => appointment.ServiceId,
                service => service.Id,
                (appointment, service) => new
                {
                    appointment.ServiceId,
                    service.ServiceCategoryId,
                    appointment.SalonId
                })
            .ToListAsync();

        var bookedServiceIds = appointmentProfile
            .Select(appointment => appointment.ServiceId)
            .Distinct()
            .ToHashSet();

        var services = await _context.Services
            .Where(x =>
                x.IsActive &&
                !bookedServiceIds.Contains(x.Id))
            .ToListAsync();

        if (appointmentProfile.Count == 0)
        {
            return await GetPopularServicesAsync(services);
        }

        var categoryCounts = appointmentProfile
            .GroupBy(appointment => appointment.ServiceCategoryId)
            .ToDictionary(group => group.Key, group => group.Count());
        var salonCounts = appointmentProfile
            .GroupBy(appointment => appointment.SalonId)
            .ToDictionary(group => group.Key, group => group.Count());
        var popularity = await GetServicePopularityAsync();

        var rankedServices = services
            .Select(service => new
            {
                Service = service,
                CategoryCount = categoryCounts.GetValueOrDefault(
                    service.ServiceCategoryId),
                SalonCount = salonCounts.GetValueOrDefault(service.SalonId)
            })
            .Where(item => item.CategoryCount > 0 || item.SalonCount > 0)
            .OrderByDescending(item =>
                item.CategoryCount * 2 + item.SalonCount)
            .ThenByDescending(item =>
                popularity.GetValueOrDefault(item.Service.Id))
            .ThenBy(item => item.Service.Name)
            .Take(5)
            .ToList();

        var categoryIds = categoryCounts.Keys.ToList();
        var profileSalonIds = salonCounts.Keys.ToList();
        var categoryNames = await _context.ServiceCategories
            .Where(category => categoryIds.Contains(category.Id))
            .ToDictionaryAsync(category => category.Id, category => category.Name);
        var salonNames = await _context.Salons
            .Where(salon => profileSalonIds.Contains(salon.Id))
            .ToDictionaryAsync(salon => salon.Id, salon => salon.Name);

        var recommendations = rankedServices
            .Select(item => (
                Service: item.Service,
                Reason: item.CategoryCount > 0
                    ? $"Rezervisali ste usluge iz kategorije " +
                      $"{categoryNames.GetValueOrDefault(item.Service.ServiceCategoryId, "usluga")}."
                    : $"Ranije ste rezervisali termine u salonu " +
                      $"{salonNames.GetValueOrDefault(item.Service.SalonId, "ovom salonu")}."
            ))
            .ToList();

        return await MapToDtoAsync(recommendations);
    }

    private async Task<List<RecommendationDto>>
        GetPopularServicesAsync(
            List<eTermin.Domain.Entities.Service> services)
    {
        var popularity = await GetServicePopularityAsync();
        var popularServices = services
            .OrderByDescending(service =>
                popularity.GetValueOrDefault(service.Id))
            .ThenBy(service => service.Name)
            .Take(5)
            .Select(service => (
                Service: service,
                Reason: "Popularna usluga među korisnicima."))
            .ToList();

        return await MapToDtoAsync(popularServices);
    }

    private async Task<Dictionary<int, int>> GetServicePopularityAsync()
    {
        return await _context.Appointments
            .Where(x => x.Status != AppointmentStatuses.Cancelled)
            .GroupBy(x => x.ServiceId)
            .Select(group => new
            {
                ServiceId = group.Key,
                Count = group.Count()
            })
            .ToDictionaryAsync(item => item.ServiceId, item => item.Count);
    }

    private async Task<List<RecommendationDto>>
        MapToDtoAsync(
            IEnumerable<(eTermin.Domain.Entities.Service Service, string Reason)> recommendations)
    {
        var recommendationItems = recommendations.ToList();
        var services = recommendationItems
            .Select(item => item.Service)
            .ToList();
        var salonIds = services
            .Select(x => x.SalonId)
            .Distinct()
            .ToList();

        var salons = await _context.Salons
            .Where(x => salonIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, x => x.Name);
        var categoryIds = services
            .Select(x => x.ServiceCategoryId)
            .Distinct()
            .ToList();
        var categories = await _context.ServiceCategories
            .Where(x => categoryIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, x => x.Name);

        return recommendationItems
            .Select(item => new RecommendationDto
            {
                ServiceId = item.Service.Id,
                ServiceName = item.Service.Name,
                Description = item.Service.Description,
                ServiceCategoryId = item.Service.ServiceCategoryId,
                ServiceCategoryName = categories.GetValueOrDefault(
                    item.Service.ServiceCategoryId, string.Empty),
                DurationInMinutes = item.Service.DurationInMinutes,
                Price = item.Service.Price,
                SalonId = item.Service.SalonId,
                SalonName = salons.GetValueOrDefault(
                    item.Service.SalonId, string.Empty),
                Reason = item.Reason
            })
            .ToList();
    }
}
