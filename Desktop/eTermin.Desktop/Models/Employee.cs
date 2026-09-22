namespace eTermin.Desktop.Models;

public class Employee
{
    public int Id { get; set; }
    public int SalonId { get; set; }
    public string FirstName { get; set; } = "";
    public string LastName { get; set; } = "";
    public string Email { get; set; } = "";
    public string PhoneNumber { get; set; } = "";
    public string Position { get; set; } = "";
    public string WorkingHours { get; set; } = "";
    public bool IsActive { get; set; }

    public List<int> ServiceIds { get; set; } = new();
}