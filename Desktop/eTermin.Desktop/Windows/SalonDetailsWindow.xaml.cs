using System.Windows;
using eTermin.Desktop.Models;

namespace eTermin.Desktop.Windows;

public partial class SalonDetailsWindow : Window
{
    private readonly Salon _salon;

    public SalonDetailsWindow(Salon salon)
    {
        InitializeComponent();

        _salon = salon;

        NameText.Text =
            _salon.Name;

        DescriptionText.Text =
            string.IsNullOrWhiteSpace(_salon.Description)
                ? "Nema opisa."
                : _salon.Description;

        AddressText.Text =
            _salon.Address;

        CityText.Text =
            _salon.City;

        PhoneText.Text =
            _salon.PhoneNumber;

        EmailText.Text =
            _salon.Email;

        StatusText.Text =
            _salon.IsActive
                ? "Aktivan"
                : "Neaktivan";
    }

    private void CloseButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        Close();
    }
}