namespace eTermin.Domain.Constants;

public static class AppointmentStatuses
{
    public const string Pending = "Pending";
    public const string Confirmed = "Confirmed";
    public const string Completed = "Completed";
    public const string Cancelled = "Cancelled";

    public static bool IsKnown(string status) => status is
        Pending or Confirmed or Completed or Cancelled;
}

public static class PaymentStatuses
{
    public const string Pending = "Pending";
    public const string Completed = "Completed";
}

public static class UserRoles
{
    public const string Admin = "Admin";
    public const string User = "User";
}
