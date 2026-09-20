namespace eTermin.Application.DTOs;

public class RecommendationDto
{
    public int ServiceId { get; set; }
    public string ServiceName { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int DurationInMinutes { get; set; }
    public decimal Price { get; set; }
    public int SalonId { get; set; }
    public string SalonName { get; set; } = string.Empty;
}