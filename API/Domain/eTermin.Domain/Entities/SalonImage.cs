namespace eTermin.Domain.Entities;

public class SalonImage
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string ImageUrl { get; set; } = string.Empty;

    public int SortOrder { get; set; }

    public DateTime CreatedAt { get; set; }
}
