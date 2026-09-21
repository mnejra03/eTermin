namespace eTermin.Desktop.Models;

public class ServiceFilterItem
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string Name { get; set; } = "";

    public string Description { get; set; } = "";

    public int DurationInMinutes { get; set; }

    public decimal Price { get; set; }

    public bool IsActive { get; set; }
}