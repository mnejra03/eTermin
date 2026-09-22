namespace eTermin.Domain.Entities;

public class Employee
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string FirstName { get; set; } = string.Empty;

    public string LastName { get; set; } = string.Empty;

    public string Email { get; set; } = string.Empty;

    public string PhoneNumber { get; set; } = string.Empty;

    public string Position { get; set; } = string.Empty;

    public string WorkingHours { get; set; } = string.Empty;

    public bool IsActive { get; set; }

    public ICollection<EmployeeService> EmployeeServices { get; set; }
    = new List<EmployeeService>();
}