using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class MainWindow : Window
{
    private readonly ApiService _apiService;

    public MainWindow()
    {
        InitializeComponent();

        _apiService = new ApiService();
    }

    private async void LoginButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        ErrorTextBlock.Visibility = Visibility.Collapsed;

        var email = EmailTextBox.Text.Trim();
        var password =
    PasswordBox.Visibility == Visibility.Visible
        ? PasswordBox.Password
        : VisiblePasswordTextBox.Text;

        if (string.IsNullOrWhiteSpace(email) ||
            string.IsNullOrWhiteSpace(password))
        {
            ShowError("Unesite email i lozinku.");
            return;
        }

        try
        {
            LoginButton.IsEnabled = false;
            LoginButton.Content = "Prijava...";

            var request = new LoginRequest
            {
                Email = email,
                Password = password
            };

            var response =
                await _apiService.PostAsync<LoginRequest, AuthResponse>(
                    "Auth/login",
                    request);

            if (response == null)
            {
                ShowError("Prijava nije uspjela.");
                return;
            }

            if (response.Role != "Admin")
            {
                ShowError(
                    "Ova desktop aplikacija je namijenjena administratorima.");
                return;
            }

            _apiService.SetToken(response.Token);

            var dashboardWindow =
    new DashboardWindow(
        _apiService,
        response);

            dashboardWindow.Show();
            Close();
        }
        catch
        {
            ShowError(
                "Nije moguće povezati se sa serverom.");
        }
        finally
        {
            LoginButton.IsEnabled = true;
            LoginButton.Content = "Prijavi se";
        }
    }

    private void PasswordVisibilityButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (PasswordBox.Visibility == Visibility.Visible)
        {
            VisiblePasswordTextBox.Text = PasswordBox.Password;

            PasswordBox.Visibility = Visibility.Collapsed;
            VisiblePasswordTextBox.Visibility = Visibility.Visible;
        }
        else
        {
            PasswordBox.Password = VisiblePasswordTextBox.Text;

            VisiblePasswordTextBox.Visibility = Visibility.Collapsed;
            PasswordBox.Visibility = Visibility.Visible;
        }
    }

    private void ShowError(string message)
    {
        ErrorTextBlock.Text = message;
        ErrorTextBlock.Visibility = Visibility.Visible;
    }
}