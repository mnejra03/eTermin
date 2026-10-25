
using eTermin.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace eTermin.Worker;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = Host.CreateApplicationBuilder(args);

        var connectionString =
            builder.Configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection nije konfigurisan.");

        builder.Services.AddDbContext<eTerminDbContext>(options =>
            options.UseSqlServer(connectionString));

        builder.Services.AddHostedService<Worker>();

        var host = builder.Build();
        host.Run();
    }
}
