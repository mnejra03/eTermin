using System.Windows;
using eTermin.Desktop.Models;

namespace eTermin.Desktop.Windows;

public partial class EmployeeDetailsWindow : Window
{
    public EmployeeDetailsWindow(EmployeeListItem employee)
    {
        InitializeComponent();

        FullNameText.Text = employee.FullName;
        EmailText.Text = employee.Email;
        PhoneText.Text = employee.PhoneNumber;
        PositionText.Text = employee.Position;
        SalonText.Text = employee.SalonName;
        ServicesText.Text = employee.ServicesText;
        WorkingHoursText.Text = employee.WorkingHours;
    }

    private void CloseButton_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }
}