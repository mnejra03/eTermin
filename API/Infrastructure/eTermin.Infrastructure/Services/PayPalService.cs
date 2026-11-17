using eTermin.Application.Services;
using Microsoft.Extensions.Configuration;
using eTermin.Application.Exceptions;
using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace eTermin.Infrastructure.Services;

public class PayPalService : IPayPalService
{
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;

    public PayPalService(
        IConfiguration configuration,
        HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
    }

    public string GetApprovalUrl(string orderId)
    {
        var baseUrl = _configuration["PayPal:BaseUrl"] ?? string.Empty;
        var checkoutHost = baseUrl.Contains("sandbox", StringComparison.OrdinalIgnoreCase)
            ? "https://www.sandbox.paypal.com"
            : "https://www.paypal.com";

        return $"{checkoutHost}/checkoutnow?token={Uri.EscapeDataString(orderId)}";
    }

    public async Task<string> GetAccessTokenAsync()
    {
        var clientId =
            _configuration["PayPal:ClientId"];

        var clientSecret =
            _configuration["PayPal:ClientSecret"];

        var baseUrl =
            _configuration["PayPal:BaseUrl"];

        var credentials =
            Convert.ToBase64String(
                Encoding.UTF8.GetBytes(
                    $"{clientId}:{clientSecret}"));

        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                $"{baseUrl}/v1/oauth2/token");

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Basic",
                credentials);

        request.Content =
            new FormUrlEncodedContent(
                new Dictionary<string, string>
                {
                    ["grant_type"] =
                        "client_credentials"
                });

        var response =
            await _httpClient.SendAsync(request);

        var content =
            await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
                $"PayPal authentication failed: {content}");
        }

        using var document =
            JsonDocument.Parse(content);

        return document.RootElement
            .GetProperty("access_token")
            .GetString()!;
    }

    public async Task<PayPalOrderResult> CreateOrderAsync(
    decimal amount,
    string currency,
    string description,
    string requestId)
    {
        var accessToken =
            await GetAccessTokenAsync();

        var baseUrl =
            _configuration["PayPal:BaseUrl"];

        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);

        if (currency == "BAM")
        {
            amount = Math.Round(
                amount / 1.95583m,
                2);

            currency = "EUR";
        }

        var order = new
        {
            intent = "CAPTURE",

            purchase_units = new[]
    {
        new
        {
            amount = new
            {
                currency_code = currency,
                value = amount.ToString(
                    "0.00",
                    CultureInfo.InvariantCulture)
            },

            description = description
        }
    },

            payment_source = new
            {
                paypal = new
                {
                    experience_context = new
                    {
                        user_action = "PAY_NOW",
                        return_url =
    "etermin://paypal-return",
                        cancel_url =
    "etermin://paypal-cancel"
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(order);

        var content = new StringContent(
            json,
            Encoding.UTF8,
            "application/json");

        using var request =
    new HttpRequestMessage(
        HttpMethod.Post,
        $"{baseUrl}/v2/checkout/orders");

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);
        request.Headers.TryAddWithoutValidation(
            "PayPal-Request-Id",
            requestId);

        request.Content = content;

        var response =
            await _httpClient.SendAsync(request);


        var responseContent =
            await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
                $"PayPal order creation failed: " +
                responseContent);
        }

        using var document =
            JsonDocument.Parse(responseContent);

        var orderId = document.RootElement
    .GetProperty("id")
    .GetString()!;

        var approvalUrl = document.RootElement
    .GetProperty("links")
    .EnumerateArray()
    .First(x =>
    {
        var rel = x.GetProperty("rel").GetString();

        return rel == "approve" ||
               rel == "payer-action";
    })
    .GetProperty("href")
    .GetString()!;

        return new PayPalOrderResult
        {
            OrderId = orderId,
            ApprovalUrl = approvalUrl
        };
    }

    public async Task<string> CaptureOrderAsync(
    string orderId,
    string requestId)
    {
        var accessToken =
            await GetAccessTokenAsync();

        var baseUrl =
            _configuration["PayPal:BaseUrl"];

        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            $"{baseUrl}/v2/checkout/orders/{orderId}/capture");

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);
        request.Headers.TryAddWithoutValidation(
            "PayPal-Request-Id",
            requestId);

        

        request.Content = new StringContent(
            "{}",
            Encoding.UTF8,
            "application/json");

        var response =
            await _httpClient.SendAsync(request);

        var responseContent =
            await response.Content.ReadAsStringAsync();

        var debugId =
            response.Headers.TryGetValues(
                "PayPal-Debug-Id",
                out var debugValues)
                ? debugValues.FirstOrDefault()
                : null;

        var sentRequestId =
            request.Headers.TryGetValues(
                "PayPal-Request-Id",
                out var requestValues)
                ? requestValues.FirstOrDefault()
                : null;

        if (!response.IsSuccessStatusCode)
        {
            if (TryGetCaptureDecline(responseContent, out var declineMessage))
                throw new BusinessException(declineMessage);

            throw new Exception(
                $"PayPal order capture failed.\n" +
                $"HTTP Status: {(int)response.StatusCode} " +
                $"{response.StatusCode}\n" +
                $"PayPal-Debug-Id: {debugId}\n" +
                $"PayPal-Request-Id: {sentRequestId}\n" +
                $"Response: {responseContent}");
        }

        using var document =
            JsonDocument.Parse(responseContent);

        var captureId =
            document.RootElement
                .GetProperty("purchase_units")[0]
                .GetProperty("payments")
                .GetProperty("captures")[0]
                .GetProperty("id")
                .GetString();

        return captureId!;
    }

    private static bool TryGetCaptureDecline(
        string responseContent,
        out string message)
    {
        message = string.Empty;
        string? issue = null;

        try
        {
            using var document = JsonDocument.Parse(responseContent);
            var root = document.RootElement;
            if (root.TryGetProperty("details", out var details) &&
                details.ValueKind == JsonValueKind.Array)
            {
                issue = details.EnumerateArray()
                    .Select(item => item.TryGetProperty("issue", out var value)
                        ? value.GetString()
                        : null)
                    .FirstOrDefault(value => !string.IsNullOrWhiteSpace(value));
            }

            issue ??= root.TryGetProperty("name", out var name)
                ? name.GetString()
                : null;
        }
        catch (JsonException)
        {
            return false;
        }

        message = issue?.ToUpperInvariant() switch
        {
            "INSTRUMENT_DECLINED" or "PAYMENT_SOURCE_DECLINED" =>
                "PayPal je odbio način plaćanja. Provjerite podatke ili odaberite drugi način plaćanja.",
            "PAYER_CANNOT_PAY" =>
                "PayPal račun trenutno ne može izvršiti plaćanje. Provjerite račun ili pokušajte drugim načinom plaćanja.",
            "PAYER_ACCOUNT_RESTRICTED" =>
                "PayPal račun ima ograničenja i ne može izvršiti plaćanje. Provjerite račun ili koristite drugi način plaćanja.",
            "CARD_EXPIRED" =>
                "Kartica povezana s PayPal računom je istekla. Ažurirajte način plaćanja i pokušajte ponovo.",
            "MAX_NUMBER_OF_PAYMENT_ATTEMPTS_EXCEEDED" =>
                "PayPal je odbio dodatne pokušaje plaćanja. Pokušajte drugim načinom plaćanja.",
            "REDIRECT_PAYER_FOR_ALTERNATE_FUNDING" =>
                "PayPal nije mogao koristiti izabrani izvor sredstava. Pokušajte drugim načinom plaćanja.",
            "TRANSACTION_LIMIT_EXCEEDED" or "TRANSACTION_RECEIVING_LIMIT_EXCEEDED" =>
                "PayPal ograničenje transakcije ne dozvoljava ovu uplatu. Pokušajte drugim načinom plaćanja ili kontaktirajte PayPal podršku.",
            "TRANSACTION_REFUSED" =>
                "PayPal je odbio transakciju. Provjerite račun ili pokušajte drugim načinom plaćanja.",
            "PAYER_ACTION_REQUIRED" or "ORDER_NOT_APPROVED" =>
                "PayPal plaćanje nije odobreno. Ponovo otvorite PayPal i odobrite plaćanje.",
            "ORDER_ALREADY_CAPTURED" =>
                "PayPal prijavljuje da je ova narudžba već naplaćena. Osvježite prikaz i provjerite status uplate.",
            _ => string.Empty
        };

        return message.Length > 0;
    }
}
