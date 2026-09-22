using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using System.Windows.Input;

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


    private async void NotificationBorder_MouseLeftButtonUp(
    object sender,
    MouseButtonEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not NotificationDto notification)
            return;

        if (notification.IsRead)
            return;

        try
        {
            await _apiService.PutAsync(
                $"Notifications/{notification.Id}/read",
                new { });

            notification.IsRead = true;

            NotificationsItemsControl.ItemsSource = null;
            NotificationsItemsControl.ItemsSource = _notifications;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri označavanju obavijesti:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void DeleteNotificationButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not NotificationDto notification)
            return;

        var result = MessageBox.Show(
            "Da li želite obrisati ovu obavijest?\n\nObavijest će biti trajno uklonjena.",
            "Brisanje obavijesti",
            MessageBoxButton.YesNo,
            MessageBoxImage.Question);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Notifications/{notification.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Obavijest nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            _notifications.Remove(notification);

            NotificationsItemsControl.ItemsSource = null;
            NotificationsItemsControl.ItemsSource =
                _notifications;
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri brisanju obavijesti:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }
}