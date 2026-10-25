namespace eTermin.Domain.Entities;

public class Salon
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string Address { get; set; } = string.Empty;

    public int CityId { get; set; }

    public string PhoneNumber { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public ICollection<SalonImage> Images { get; set; } = new List<SalonImage>();

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }
}