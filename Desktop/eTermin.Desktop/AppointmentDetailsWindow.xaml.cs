using System.Net.Http.Json;
using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop;

public partial class AppointmentDetailsWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AppointmentListItem _appointment;

    public AppointmentDetailsWindow(
        ApiService apiService,
        AppointmentListItem appointment)
    {
        InitializeComponent();

        _apiService = apiService;
        _appointment = appointment;

        UserNameText.Text = appointment.UserName;
        SalonNameText.Text = appointment.SalonName;
        ServiceNameText.Text = appointment.ServiceName;

        DateText.Text =
            appointment.StartTime.ToString("dd.MM.yyyy.");

        TimeText.Text =
            $"{appointment.StartTime:HH:mm} - {appointment.EndTime:HH:mm}";

        PriceText.Text =
            $"{appointment.Price:0.00} KM";

        StatusText.Text =
            appointment.Status;
    }

    private void CloseButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        Close();
    }

    private async void CancelButton_Click(
     object sender,
     RoutedEventArgs e)
    {
        var result = MessageBox.Show(
            "Da li ste sigurni da želite otkazati ovaj termin?",
            "Potvrda otkazivanja",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var request = new
            {
                Id = _appointment.Id,
                UserId = 0,
                SalonId = _appointment.SalonId,
                EmployeeId = 0,
                ServiceId = 0,
                StartTime = _appointment.StartTime,
                EndTime = _appointment.EndTime,
                Status = "Cancelled",
                Price = _appointment.Price,
                CreatedAt = DateTime.Now
            };

            var response = await _apiService.PutAsync(
                $"Appointments/{_appointment.Id}",
                request);

            if (!response)
            {
                MessageBox.Show(
                    "Backend nije prihvatio promjenu termina.",
                    "Greška",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);

                return;
            }

            MessageBox.Show(
                "Termin je uspješno otkazan.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom otkazivanja termina:\n\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }
}