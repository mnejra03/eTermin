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

   
}