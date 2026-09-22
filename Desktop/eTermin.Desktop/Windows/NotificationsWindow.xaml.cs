using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class NotificationsWindow : Window
{
    private readonly ApiService _apiService;

    private List<NotificationDto> _notifications = new();

    public NotificationsWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += NotificationsWindow_Loaded;
    }

    private async void NotificationsWindow_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadNotificationsAsync();
    }

    private async Task LoadNotificationsAsync()
    {
        try
        {
            var result =
                await _apiService.GetAsync<List<NotificationDto>>(
                    "Notifications/my");

            _notifications =
                result ?? new List<NotificationDto>();

            NotificationsItemsControl.ItemsSource =
                _notifications;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri učitavanju obavijesti:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CloseButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        Close();
    }


}