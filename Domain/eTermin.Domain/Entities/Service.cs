namespace eTermin.Domain.Entities;

public class Service
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public int DurationInMinutes { get; set; }

    public decimal Price { get; set; }

    public bool IsActive { get; set; }

    public ICollection<EmployeeService> EmployeeServices { get; set; }
    = new List<EmployeeService>();
}