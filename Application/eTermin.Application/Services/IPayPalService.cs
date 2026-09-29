namespace eTermin.Application.Services;

public interface IPayPalService
{
    Task<string> GetAccessTokenAsync();

    Task<PayPalOrderResult> CreateOrderAsync(
        decimal amount,
        string currency,
        string description);

    Task<string> CaptureOrderAsync(
        string orderId);

    Task<string> GetOrderDetailsAsync(string orderId);

}

public class PayPalOrderResult
{
    public string OrderId { get; set; } = string.Empty;

    public string ApprovalUrl { get; set; } = string.Empty;
}