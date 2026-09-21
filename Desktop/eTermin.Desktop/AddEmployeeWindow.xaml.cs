using System.Windows;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop;

public partial class AddEmployeeWindow : Window
{
    private readonly ApiService _apiService;

    public AddEmployeeWindow(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += AddEmployeeWindow_Loaded;
    }

    private async void AddEmployeeWindow_Loaded(object sender, RoutedEventArgs e)
    {
        await LoadSalonsAsync();
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var salons =
                await _apiService.GetAsync<List<SalonFilterItem>>("Salons");

            if (salons == null)
                return;

            SalonComboBox.ItemsSource = salons
                .Where(x => x.Id.HasValue)
                .ToList();

            SalonComboBox.DisplayMemberPath = "Name";
            SalonComboBox.SelectedValuePath = "Id";
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja salona:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private async void AddButton_Click(object sender, RoutedEventArgs e)
    {
        if (SalonComboBox.SelectedValue == null)
        {
            MessageBox.Show(
                "Odaberite salon.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(FirstNameTextBox.Text))
        {
            MessageBox.Show(
                "Unesite ime zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            FirstNameTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(LastNameTextBox.Text))
        {
            MessageBox.Show(
                "Unesite prezime zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            LastNameTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(EmailTextBox.Text))
        {
            MessageBox.Show(
                "Unesite e-mail zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            EmailTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(PhoneNumberTextBox.Text))
        {
            MessageBox.Show(
                "Unesite broj telefona.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            PhoneNumberTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(PositionTextBox.Text))
        {
            MessageBox.Show(
                "Unesite poziciju zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            PositionTextBox.Focus();
            return;
        }

        if (string.IsNullOrWhiteSpace(WorkingHoursTextBox.Text))
        {
            MessageBox.Show(
                "Unesite radno vrijeme.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            WorkingHoursTextBox.Focus();
            return;
        }

        var request = new CreateEmployeeRequest
        {
            SalonId = (int)SalonComboBox.SelectedValue,
            FirstName = FirstNameTextBox.Text.Trim(),
            LastName = LastNameTextBox.Text.Trim(),
            Email = EmailTextBox.Text.Trim(),
            PhoneNumber = PhoneNumberTextBox.Text.Trim(),
            Position = PositionTextBox.Text.Trim(),
            WorkingHours = WorkingHoursTextBox.Text.Trim(),
            IsActive = IsActiveCheckBox.IsChecked == true
        };

        try
        {
            await _apiService.PostAsync<CreateEmployeeRequest, object>(
                "Employees",
                request);

            MessageBox.Show(
                "Zaposlenik je uspješno dodan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom dodavanja zaposlenika:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CancelButton_Click(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}