namespace eTermin.Api.QueryParameters;

public static class PaginationOptions
{
    public const int DefaultPageSize = 20;
    public const int MaximumPageSize = 100;

    public static (int Page, int PageSize) Normalize(
        int page,
        int pageSize)
    {
        var normalizedPageSize = Math.Clamp(
            pageSize,
            1,
            MaximumPageSize);
        var maximumPage = int.MaxValue / normalizedPageSize;
        return (
            (int)Math.Clamp((long)page, 1, maximumPage),
            normalizedPageSize);
    }
}
