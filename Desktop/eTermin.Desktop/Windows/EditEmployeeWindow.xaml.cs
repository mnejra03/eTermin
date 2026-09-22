using System.Windows;
using System.Windows.Controls;
using eTermin.Desktop.Models;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Windows;

public partial class EditEmployeeWindow : Window
{
    private readonly ApiService _apiService;
    private readonly EmployeeListItem _employee;

    private List<Service> _services = new();

    public EditEmployeeWindow(
        ApiService apiService,
        EmployeeListItem employee)
    {
        InitializeComponent();

        _apiService = apiService;
        _employee = employee;

        Loaded += EditEmployeeWindow_Loaded;
    }

    private async void EditEmployeeWindow_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadSalonsAsync();

        FirstNameTextBox.Text = _employee.FirstName;
        LastNameTextBox.Text = _employee.LastName;
        EmailTextBox.Text = _employee.Email;
        PhoneNumberTextBox.Text = _employee.PhoneNumber;
        PositionTextBox.Text = _employee.Position;
        WorkingHoursTextBox.Text = _employee.WorkingHours;
        IsActiveCheckBox.IsChecked = _employee.IsActive;

        SalonComboBox.SelectedValue = _employee.SalonId;
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

    private async void SalonComboBox_SelectionChanged(
        object sender,
        SelectionChangedEventArgs e)
    {
        if (SalonComboBox.SelectedValue == null)
            return;

        if (!int.TryParse(
                SalonComboBox.SelectedValue.ToString(),
                out int salonId))
            return;

        await LoadServicesAsync(salonId);
    }

    private async Task LoadServicesAsync(int salonId)
    {
        try
        {
            ServicesPanel.Children.Clear();

            var services =
                await _apiService.GetAsync<List<Service>>("Services");

            _services = services?
                .Where(s =>
                    s.SalonId == salonId &&
                    s.IsActive)
                .ToList()
                ?? new List<Service>();

            foreach (var service in _services)
            {
                var checkBox = new CheckBox
                {
                    Content = service.Name,
                    Tag = service.Id,
                    FontSize = 14,
                    Foreground =
                        new System.Windows.Media.SolidColorBrush(
                            System.Windows.Media.Color.FromRgb(
                                64, 55, 71)),
                    Margin = new Thickness(2, 4, 2, 4),
                    IsChecked = _employee
                        .ServicesText
                        .Split(',')
                        .Select(x => x.Trim())
                        .Contains(service.Name)
                };

                ServicesPanel.Children.Add(checkBox);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom učitavanja usluga:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private List<int> GetSelectedServiceIds()
    {
        return ServicesPanel.Children
            .OfType<CheckBox>()
            .Where(x =>
                x.IsChecked == true &&
                x.Tag != null)
            .Select(x => Convert.ToInt32(x.Tag))
            .ToList();
    }

    private async void SaveButton_Click(
        object sender,
        RoutedEventArgs e)
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

            return;
        }

        if (string.IsNullOrWhiteSpace(LastNameTextBox.Text))
        {
            MessageBox.Show(
                "Unesite prezime zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(EmailTextBox.Text))
        {
            MessageBox.Show(
                "Unesite e-mail zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(PhoneNumberTextBox.Text))
        {
            MessageBox.Show(
                "Unesite broj telefona.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(PositionTextBox.Text))
        {
            MessageBox.Show(
                "Unesite poziciju zaposlenika.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

            return;
        }

        if (string.IsNullOrWhiteSpace(WorkingHoursTextBox.Text))
        {
            MessageBox.Show(
                "Unesite radno vrijeme.",
                "Validacija",
                MessageBoxButton.OK,
                MessageBoxImage.Warning);

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
            IsActive = IsActiveCheckBox.IsChecked == true,
            ServiceIds = GetSelectedServiceIds()
        };

        try
        {
            var updated =
                await _apiService.PutAsync(
                    $"Employees/{_employee.Id}",
                    request);

            if (!updated)
            {
                MessageBox.Show(
                    "Zaposlenika nije moguće urediti.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            MessageBox.Show(
                "Podaci zaposlenika su uspješno izmijenjeni.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            DialogResult = true;
            Close();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška prilikom uređivanja zaposlenika:\n{ex.Message}",
                "Greška",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void CancelButton_Click(
        object sender,
        RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}