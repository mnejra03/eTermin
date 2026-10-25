namespace eTermin.Application.Services;

public interface IEmailSender
{
    void EnsureConfigured();

    Task SendAsync(string recipient, string subject, string body);
}
