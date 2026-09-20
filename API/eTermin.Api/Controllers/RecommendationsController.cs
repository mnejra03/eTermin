using System.Security.Claims;
using eTermin.Application.DTOs;
using eTermin.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace eTermin.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService
        _recommendationService;

    public RecommendationsController(
        IRecommendationService recommendationService)
    {
        _recommendationService =
            recommendationService;
    }

    [HttpGet("my")]
    public async Task<ActionResult<List<RecommendationDto>>>
        GetMyRecommendations()
    {
        var userIdClaim =
            User.FindFirst(ClaimTypes.NameIdentifier);

        if (userIdClaim == null)
            return Unauthorized();

        var userId = int.Parse(userIdClaim.Value);

        var recommendations =
            await _recommendationService
                .GetRecommendationsAsync(userId);

        return Ok(recommendations);
    }
}