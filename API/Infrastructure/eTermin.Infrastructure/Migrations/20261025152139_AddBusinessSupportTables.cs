using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace eTermin.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddBusinessSupportTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AppointmentStatusHistories",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AppointmentId = table.Column<int>(type: "int", nullable: false),
                    PreviousStatus = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    NewStatus = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    ChangedByUserId = table.Column<int>(type: "int", nullable: false),
                    ChangedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppointmentStatusHistories", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppointmentStatusHistories_Appointments_AppointmentId",
                        column: x => x.AppointmentId,
                        principalTable: "Appointments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_AppointmentStatusHistories_Users_ChangedByUserId",
                        column: x => x.ChangedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "City",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_City", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "SalonImages",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    SalonId = table.Column<int>(type: "int", nullable: false),
                    ImageUrl = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: false),
                    SortOrder = table.Column<int>(type: "int", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_SalonImages", x => x.Id);
                    table.ForeignKey(
                        name: "FK_SalonImages_Salons_SalonId",
                        column: x => x.SalonId,
                        principalTable: "Salons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ServiceCategory",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "nvarchar(500)", maxLength: 500, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServiceCategory", x => x.Id);
                });

            migrationBuilder.Sql(
                """
                INSERT INTO City (Name)
                SELECT DISTINCT COALESCE(NULLIF(LTRIM(RTRIM(City)), ''), N'Nepoznat grad')
                FROM Salons;

                INSERT INTO ServiceCategory (Name, Description)
                VALUES (N'Ostalo', N'Kategorija za ranije postojeće usluge; uredite po potrebi.');
                """);

            migrationBuilder.AddColumn<int>(
                name: "CityId",
                table: "Salons",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ServiceCategoryId",
                table: "Services",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE salons
                SET CityId = city.Id
                FROM Salons salons
                INNER JOIN City city
                    ON city.Name = COALESCE(
                        NULLIF(LTRIM(RTRIM(salons.City)), ''),
                        N'Nepoznat grad');

                UPDATE Services
                SET ServiceCategoryId = (
                    SELECT TOP (1) Id
                    FROM ServiceCategory
                    WHERE Name = N'Ostalo');

                INSERT INTO SalonImages (SalonId, ImageUrl, SortOrder, CreatedAt)
                SELECT Id, ImageUrl, 0, SYSUTCDATETIME()
                FROM Salons
                WHERE NULLIF(LTRIM(RTRIM(ImageUrl)), '') IS NOT NULL;

                INSERT INTO AppointmentStatusHistories
                    (AppointmentId, PreviousStatus, NewStatus, ChangedByUserId, ChangedAt)
                SELECT Id, NULL, Status, COALESCE(CancelledByUserId, UserId), CreatedAt
                FROM Appointments;
                """);

            migrationBuilder.AlterColumn<int>(
                name: "CityId",
                table: "Salons",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.AlterColumn<int>(
                name: "ServiceCategoryId",
                table: "Services",
                type: "int",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "int",
                oldNullable: true);

            migrationBuilder.DropColumn(
                name: "City",
                table: "Salons");

            migrationBuilder.DropColumn(
                name: "ImageUrl",
                table: "Salons");

            migrationBuilder.CreateIndex(
                name: "IX_Services_ServiceCategoryId",
                table: "Services",
                column: "ServiceCategoryId");

            migrationBuilder.CreateIndex(
                name: "IX_Salons_CityId",
                table: "Salons",
                column: "CityId");

            migrationBuilder.CreateIndex(
                name: "IX_AppointmentStatusHistories_AppointmentId_ChangedAt",
                table: "AppointmentStatusHistories",
                columns: new[] { "AppointmentId", "ChangedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_AppointmentStatusHistories_ChangedByUserId",
                table: "AppointmentStatusHistories",
                column: "ChangedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_City_Name",
                table: "City",
                column: "Name",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_SalonImages_SalonId_SortOrder",
                table: "SalonImages",
                columns: new[] { "SalonId", "SortOrder" });

            migrationBuilder.CreateIndex(
                name: "IX_ServiceCategory_Name",
                table: "ServiceCategory",
                column: "Name",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_Salons_City_CityId",
                table: "Salons",
                column: "CityId",
                principalTable: "City",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Services_ServiceCategory_ServiceCategoryId",
                table: "Services",
                column: "ServiceCategoryId",
                principalTable: "ServiceCategory",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Salons_City_CityId",
                table: "Salons");

            migrationBuilder.DropForeignKey(
                name: "FK_Services_ServiceCategory_ServiceCategoryId",
                table: "Services");

            migrationBuilder.DropIndex(
                name: "IX_Services_ServiceCategoryId",
                table: "Services");

            migrationBuilder.DropIndex(
                name: "IX_Salons_CityId",
                table: "Salons");

            migrationBuilder.AddColumn<string>(
                name: "City",
                table: "Salons",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ImageUrl",
                table: "Salons",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.Sql(
                """
                UPDATE salons
                SET City = city.Name
                FROM Salons salons
                INNER JOIN City city ON city.Id = salons.CityId;

                UPDATE salons
                SET ImageUrl = image.ImageUrl
                FROM Salons salons
                OUTER APPLY (
                    SELECT TOP (1) ImageUrl
                    FROM SalonImages
                    WHERE SalonId = salons.Id
                    ORDER BY SortOrder, Id
                ) image;
                """);

            migrationBuilder.AlterColumn<string>(
                name: "City",
                table: "Salons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "ImageUrl",
                table: "Salons",
                type: "nvarchar(max)",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.DropColumn(
                name: "ServiceCategoryId",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "CityId",
                table: "Salons");

            migrationBuilder.DropTable(
                name: "AppointmentStatusHistories");

            migrationBuilder.DropTable(
                name: "City");

            migrationBuilder.DropTable(
                name: "SalonImages");

            migrationBuilder.DropTable(
                name: "ServiceCategory");
        }
    }
}
