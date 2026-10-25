using eTermin.Application.Exceptions;
using System.Text.Json;

namespace eTermin.Api.Middleware;

public sealed class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(
        RequestDelegate next,
        ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (BusinessException exception)
        {
            await WriteErrorAsync(
                context,
                StatusCodes.Status400BadRequest,
                exception.Message);
        }
        catch (NotFoundException exception)
        {
            await WriteErrorAsync(
                context,
                StatusCodes.Status404NotFound,
                exception.Message);
        }
        catch (Exception exception)
        {
            _logger.LogError(
                exception,
                "Unhandled error for {Method} {Path}",
                context.Request.Method,
                context.Request.Path);

            await WriteErrorAsync(
                context,
                StatusCodes.Status500InternalServerError,
                "Došlo je do neočekivane greške. Pokušajte ponovo kasnije.");
        }
    }

    private static async Task WriteErrorAsync(
        HttpContext context,
        int statusCode,
        string message)
    {
        if (context.Response.HasStarted)
            return;

        context.Response.Clear();
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsync(
            JsonSerializer.Serialize(new { message }));
    }
}
