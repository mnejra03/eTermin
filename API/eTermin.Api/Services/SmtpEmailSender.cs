using eTermin.Application.Services;
using System.Net;
using System.Net.Mail;

namespace eTermin.Api.Services;

public class SmtpEmailSender(IConfiguration configuration) : IEmailSender
{
    public void EnsureConfigured()
    {
        if (string.IsNullOrWhiteSpace(configuration["Email:SmtpHost"]) ||
            string.IsNullOrWhiteSpace(configuration["Email:FromAddress"]))
        {
            throw new InvalidOperationException(
                "Reset lozinke nije konfigurisan za slanje e-pošte.");
        }
    }

    public async Task SendAsync(string recipient, string subject, string body)
    {
        EnsureConfigured();

        var host = configuration["Email:SmtpHost"]!;
        var fromAddress = configuration["Email:FromAddress"]!;
        var fromName = configuration["Email:FromName"] ?? "eTermin";
        var port = int.TryParse(configuration["Email:SmtpPort"], out var parsedPort)
            ? parsedPort
            : 587;
        var enableSsl = !bool.TryParse(
            configuration["Email:EnableSsl"],
            out var parsedEnableSsl) || parsedEnableSsl;
        var username = configuration["Email:Username"];
        var password = configuration["Email:Password"];

        using var message = new MailMessage
        {
            From = new MailAddress(fromAddress, fromName),
            Subject = subject,
            Body = body,
            IsBodyHtml = false
        };
        message.To.Add(recipient);

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = enableSsl,
            DeliveryMethod = SmtpDeliveryMethod.Network
        };
        if (!string.IsNullOrWhiteSpace(username))
            client.Credentials = new NetworkCredential(username, password);

        await client.SendMailAsync(message);
    }
}
