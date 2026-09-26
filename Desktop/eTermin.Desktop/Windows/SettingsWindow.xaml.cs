using System.Windows;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class SettingsWindow : Window
{
    private readonly ApiService _apiService;

    public SettingsWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;
    }

    private async void ChangePasswordButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        ErrorTextBlock.Visibility =
            Visibility.Collapsed;

        var currentPassword =
            CurrentPasswordBox.Password;

        var newPassword =
            NewPasswordBox.Password;

        var confirmPassword =
            ConfirmPasswordBox.Password;

        if (string.IsNullOrWhiteSpace(currentPassword))
        {
            ShowError("Unesite trenutnu lozinku.");
            return;
        }

        if (string.IsNullOrWhiteSpace(newPassword))
        {
            ShowError("Unesite novu lozinku.");
            return;
        }

        if (newPassword.Length < 6)
        {
            ShowError(
                "Nova lozinka mora sadržavati najmanje 6 znakova.");
            return;
        }

        if (newPassword != confirmPassword)
        {
            ShowError(
                "Nova lozinka i potvrda lozinke se ne podudaraju.");
            return;
        }

        if (currentPassword == newPassword)
        {
            ShowError(
                "Nova lozinka mora biti različita od trenutne.");
            return;
        }

        try
        {
            ChangePasswordButton.IsEnabled = false;

            var request = new
            {
                CurrentPassword = currentPassword,
                NewPassword = newPassword
            };

            await _apiService.PutAsync(
                "Auth/change-password",
                request);

            MessageBox.Show(
                "Lozinka je uspješno promijenjena.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            CurrentPasswordBox.Clear();
            NewPasswordBox.Clear();
            ConfirmPasswordBox.Clear();
        }
        catch (Exception ex)
        {
            ShowError(ex.Message);
        }
        finally
        {
            ChangePasswordButton.IsEnabled = true;
        }
    }

    private void ShowError(string message)
    {
        ErrorTextBlock.Text = message;
        ErrorTextBlock.Visibility = Visibility.Visible;
    }
}