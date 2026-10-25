namespace eTermin.Application.Services;

public interface IAppointmentReminderPublisher
{
    Task PublishAsync(int appointmentId, CancellationToken cancellationToken = default);
}
