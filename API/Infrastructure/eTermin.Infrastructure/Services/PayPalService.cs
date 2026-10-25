using eTermin.Application.Services;
using Microsoft.Extensions.Configuration;
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
    string description)
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
    "etermin://paypal-return"
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
    string orderId)
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

        var requestId =
            request.Headers.TryGetValues(
                "PayPal-Request-Id",
                out var requestValues)
                ? requestValues.FirstOrDefault()
                : null;

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
                $"PayPal order capture failed.\n" +
                $"HTTP Status: {(int)response.StatusCode} " +
                $"{response.StatusCode}\n" +
                $"PayPal-Debug-Id: {debugId}\n" +
                $"PayPal-Request-Id: {requestId}\n" +
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
    public async Task<string> GetOrderDetailsAsync(
     string orderId)
    {
        var accessToken =
            await GetAccessTokenAsync();

        var baseUrl =
            _configuration["PayPal:BaseUrl"];

        using var request =
            new HttpRequestMessage(
                HttpMethod.Get,
                $"{baseUrl}/v2/checkout/orders/{orderId}");

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);

        var response =
            await _httpClient.SendAsync(request);

        var responseContent =
            await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception(
                $"PayPal order details failed: " +
                responseContent);
        }

        return responseContent;
    }
}