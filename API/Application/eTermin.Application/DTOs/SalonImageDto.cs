namespace eTermin.Application.DTOs;

public class SalonImageDto
{
    public int Id { get; set; }

    public string ImageUrl { get; set; } = string.Empty;

    public int SortOrder { get; set; }
}
