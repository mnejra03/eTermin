namespace eTermin.Application.Services;

public interface IPayPalService
{
    Task<string> GetAccessTokenAsync();

    Task<PayPalOrderResult> CreateOrderAsync(
        decimal amount,
        string currency,
        string description,
        string requestId);

    Task<string> CaptureOrderAsync(
        string orderId,
        string requestId);

    string GetApprovalUrl(string orderId);

}

public class PayPalOrderResult
{
    public string OrderId { get; set; } = string.Empty;

    public string ApprovalUrl { get; set; } = string.Empty;
}
