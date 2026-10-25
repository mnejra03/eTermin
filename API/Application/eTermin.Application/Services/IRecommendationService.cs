using eTermin.Application.DTOs;

namespace eTermin.Application.Services;

public interface IRecommendationService
{
    Task<List<RecommendationDto>> GetRecommendationsAsync(
        int userId);
}