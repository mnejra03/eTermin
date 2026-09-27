using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using System.Windows;
using System.Windows.Media;
using System.Text.RegularExpressions;

namespace eTermin.Desktop.Windows;

public partial class SettingsWindow : Window
{
    private readonly ApiService _apiService;
    private readonly AuthResponse _authResponse;

    public SettingsWindow(
    ApiService apiService,
    AuthResponse currentUser)
    {
        InitializeComponent();

        _apiService = apiService;
        _authResponse = currentUser;


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


        ProfilePanel.Visibility =
            Visibility.Visible;
    }

    private async void SaveProfileButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        var firstName =
            FirstNameTextBox.Text.Trim();

        var lastName =
            LastNameTextBox.Text.Trim();

        var email =
            EmailTextBox.Text.Trim();

        // Provjera imena
        if (string.IsNullOrWhiteSpace(firstName))
        {
            MessageBox.Show(
                "Ime ne može biti prazno.",
                "Neuspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        // Provjera prezimena
        if (string.IsNullOrWhiteSpace(lastName))
        {
            MessageBox.Show(
                "Prezime ne može biti prazno.",
                "Neuspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        // Provjera praznog emaila
        if (string.IsNullOrWhiteSpace(email))
        {
            MessageBox.Show(
                "Email ne može biti prazan.",
                "Neuspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        // Provjera formata emaila
        var emailPattern =
            @"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$";

        if (!Regex.IsMatch(email, emailPattern))
        {
            MessageBox.Show(
                "Email adresa nije ispravna.\n\n" +
                "Email mora biti u formatu:\n" +
                "ime@domena.ba ili ime@domena.com\n\n" +
                "Primjer: nejra@gmail.com",
                "Neuspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Error);

            return;
        }

        try
        {
            SaveProfileButton.IsEnabled = false;
            SaveProfileButton.Content = "Spremanje...";

            var request = new
            {
                FirstName = firstName,
                LastName = lastName,
                Email = email
            };

            await _apiService.PutAsync(
                "Auth/profile",
                request);

            _authResponse.FirstName = firstName;
            _authResponse.LastName = lastName;
            _authResponse.Email = email;

            if (Owner is DashboardWindow dashboardWindow)
            {
                dashboardWindow.UpdateCurrentUser(
                    _authResponse);
            }

            MessageBox.Show(
                "Podaci profila su uspješno izmijenjeni.",
                "Uspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                "Promjene nisu sačuvane.\n\n" +
                ex.Message,
                "Neuspješno",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
        finally
        {
            SaveProfileButton.IsEnabled = true;
            SaveProfileButton.Content =
                "Sačuvaj promjene";
        }
    }


    private void SecuritySettingsButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        SettingsMenuPanel.Visibility =
            Visibility.Collapsed;

        ProfilePanel.Visibility =
            Visibility.Collapsed;


        SecurityPanel.Visibility =
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
        ErrorTextBlock.Visibility =
            Visibility.Visible;
    }
}