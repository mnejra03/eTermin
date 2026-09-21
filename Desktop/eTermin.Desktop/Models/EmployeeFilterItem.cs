namespace eTermin.Desktop.Models;

public class EmployeeFilterItem
{
    public int Id { get; set; }

    public int SalonId { get; set; }

    public string FirstName { get; set; } = "";

    public string LastName { get; set; } = "";

    public string Name =>
        $"{FirstName} {LastName}";
}