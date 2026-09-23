namespace eTermin.Desktop.Models;

public class UserFilterItem
{
    public int Id { get; set; }

    public string FirstName { get; set; } = "";

    public string LastName { get; set; } = "";

    public string Name =>
        $"{FirstName} {LastName}";

    public string Email { get; set; } = "";
}