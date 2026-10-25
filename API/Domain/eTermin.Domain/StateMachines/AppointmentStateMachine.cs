using eTermin.Domain.Constants;

namespace eTermin.Domain.StateMachines;

public static class AppointmentStateMachine
{
    public static bool CanTransition(string currentStatus, string nextStatus)
    {
        return (currentStatus, nextStatus) switch
        {
            (AppointmentStatuses.Pending, AppointmentStatuses.Confirmed) => true,
            (AppointmentStatuses.Pending, AppointmentStatuses.Cancelled) => true,
            (AppointmentStatuses.Confirmed, AppointmentStatuses.Completed) => true,
            (AppointmentStatuses.Confirmed, AppointmentStatuses.Cancelled) => true,
            _ => false
        };
    }
}
