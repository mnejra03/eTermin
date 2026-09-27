using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using System.Windows;
using System.Windows.Media;

namespace eTermin.Desktop.Windows;

public partial class SettingsWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AuthResponse _authResponse;
    private bool _isInitialized;

    public SettingsWindow(
    ApiService apiService,
    AuthResponse currentUser)
    {
        InitializeComponent();

        _apiService = apiService;
        _authResponse = currentUser;

        _isInitialized = true;

        ApplyLightTheme();
    }

    private void ProfileSettingsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        FirstNameTextBox.Text =
            _authResponse.FirstName;

        LastNameTextBox.Text =
            _authResponse.LastName;

        EmailTextBox.Text =
            _authResponse.Email;

        RoleTextBox.Text =
            _authResponse.Role;

        SettingsMenuPanel.Visibility =
            Visibility.Collapsed;

        SecurityPanel.Visibility =
            Visibility.Collapsed;

        AppearancePanel.Visibility =
            Visibility.Collapsed;

        ProfilePanel.Visibility =
            Visibility.Visible;
    }

    private void LightThemeRadioButton_Checked(
    object sender,
    RoutedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyLightTheme();
    }

    private void DarkThemeRadioButton_Checked(
    object sender,
    RoutedEventArgs e)
    {
        if (!_isInitialized)
            return;

        ApplyDarkTheme();
    }

    private void ApplyLightTheme()
    {
        Background =
            new SolidColorBrush(
                Color.FromRgb(247, 244, 248));

        SettingsMenuPanel.Background =
            Brushes.White;

        ProfilePanel.Background =
            Brushes.White;

        SecurityPanel.Background =
            Brushes.White;

        AppearancePanel.Background =
            Brushes.White;
    }

    private void ApplyDarkTheme()
    {
        Background =
            new SolidColorBrush(
                Color.FromRgb(35, 30, 38));

        SettingsMenuPanel.Background =
            new SolidColorBrush(
                Color.FromRgb(48, 42, 52));

        ProfilePanel.Background =
            new SolidColorBrush(
                Color.FromRgb(48, 42, 52));

        SecurityPanel.Background =
            new SolidColorBrush(
                Color.FromRgb(48, 42, 52));

        AppearancePanel.Background =
            new SolidColorBrush(
                Color.FromRgb(48, 42, 52));
    }

    private void SecuritySettingsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SettingsMenuPanel.Visibility =
            Visibility.Collapsed;

        ProfilePanel.Visibility =
            Visibility.Collapsed;

        AppearancePanel.Visibility =
            Visibility.Collapsed;

        SecurityPanel.Visibility =
            Visibility.Visible;
    }

    private void AppearanceSettingsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SettingsMenuPanel.Visibility =
            Visibility.Collapsed;

        ProfilePanel.Visibility =
            Visibility.Collapsed;

        SecurityPanel.Visibility =
            Visibility.Collapsed;

        AppearancePanel.Visibility =
            Visibility.Visible;
    }

    private void BackToSettings_Click(
    object sender,
    RoutedEventArgs e)
    {
        ProfilePanel.Visibility =
            Visibility.Collapsed;

        SecurityPanel.Visibility =
            Visibility.Collapsed;

        AppearancePanel.Visibility =
            Visibility.Collapsed;

        SettingsMenuPanel.Visibility =
            Visibility.Visible;
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