using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eTermin.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUniqueAppointmentReminder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Notifications_AppointmentId",
                table: "Notifications");

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "Notifications",
                type: "nvarchar(450)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_AppointmentId_Type",
                table: "Notifications",
                columns: new[] { "AppointmentId", "Type" },
                unique: true,
                filter: "[AppointmentId] IS NOT NULL AND [Type] = N'AppointmentReminder'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Notifications_AppointmentId_Type",
                table: "Notifications");

            migrationBuilder.AlterColumn<string>(
                name: "Type",
                table: "Notifications",
                type: "nvarchar(max)",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(450)");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_AppointmentId",
                table: "Notifications",
                column: "AppointmentId");
        }
    }
}
