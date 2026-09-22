using eTermin.Desktop.Models;
using System.Windows;

namespace eTermin.Desktop.Windows;

public partial class ProfileWindow : Window
{
    private readonly AuthResponse _currentUser;

    public ProfileWindow(AuthResponse currentUser)
    {
        InitializeComponent();

        _currentUser = currentUser;

        FullNameText.Text =
            $"{_currentUser.FirstName} {_currentUser.LastName}";

        EmailText.Text =
            _currentUser.Email;

        RoleText.Text =
            _currentUser.Role;
    }

    private void CloseButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        Close();
    }
}