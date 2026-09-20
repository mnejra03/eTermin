using System.Windows;

namespace eTermin.Desktop;

public partial class DashboardWindow : Window
{
    public DashboardWindow()
    {
        InitializeComponent();
    }

    private void LogoutButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        var loginWindow = new MainWindow();

        loginWindow.Show();

        Close();
    }
}