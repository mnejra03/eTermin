using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace eTermin.Desktop.Services;

public class ApiService
{
    private readonly HttpClient _httpClient;

    public ApiService()
    {
        var handler = new HttpClientHandler
        {
            ServerCertificateCustomValidationCallback =
                HttpClientHandler.DangerousAcceptAnyServerCertificateValidator
        };

        _httpClient = new HttpClient(handler)
        {
            BaseAddress = new Uri("https://localhost:7119/api/")
        };

        _httpClient.Timeout = TimeSpan.FromSeconds(30);
    }

    public void SetToken(string token)
    {
        _httpClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", token);
    }

    public async Task<T?> GetAsync<T>(string endpoint)
    {
        return await _httpClient.GetFromJsonAsync<T>(endpoint);
    }

    public async Task<TResponse?> PostAsync<TRequest, TResponse>(
        string endpoint,
        TRequest request)
    {
        var response = await _httpClient.PostAsJsonAsync(endpoint, request);
        response.EnsureSuccessStatusCode();

        return await response.Content.ReadFromJsonAsync<TResponse>();
    }

    public async Task<bool> PutAsync<TRequest>(
    string endpoint,
    TRequest request)
    {
        var response = await _httpClient.PutAsJsonAsync(
            endpoint,
            request);

        if (response.IsSuccessStatusCode)
            return true;

        var errorMessage =
            await response.Content.ReadAsStringAsync();

        throw new Exception(
            $"API greška ({(int)response.StatusCode}): {errorMessage}");
    }

    public async Task<bool> DeleteAsync(
    string endpoint)
    {
        var response =
            await _httpClient.DeleteAsync(endpoint);

        return response.IsSuccessStatusCode;
    }
}