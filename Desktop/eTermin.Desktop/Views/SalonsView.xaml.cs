using eTermin.Desktop.Models;
using eTermin.Desktop.Services;
using eTermin.Desktop.Windows;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace eTermin.Desktop.Views;

public partial class SalonsView : System.Windows.Controls.UserControl
{
    private readonly ApiService _apiService;

    private List<Salon> _salons = new();

    private List<Salon> _filteredSalons = new();

    private int _currentPage = 1;

    private int PageSize
    {
        get
        {
            const double rowHeight = 48;

            var availableHeight = SalonsDataGrid.ActualHeight;

            if (availableHeight <= 0)
                return 1;

            return Math.Max(
                1,
                (int)(availableHeight / rowHeight));
        }
    }

    private int TotalPages =>
    Math.Max(
        1,
        (int)Math.Ceiling(
            _filteredSalons.Count /
            (double)PageSize));

    public SalonsView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;

        Loaded += SalonsView_Loaded;
    }

    private async void SalonsView_Loaded(
        object sender,
        RoutedEventArgs e)
    {
        await LoadSalonsAsync();
    }

    private async Task LoadSalonsAsync()
    {
        try
        {
            var result =
                await _apiService.GetAsync<List<Salon>>(
                    "Salons");

            _salons =
                result ?? new List<Salon>();

            var totalSalons =
                _salons.Count;

            var activeSalons =
                _salons.Count(s => s.IsActive);

            var inactiveSalons =
                _salons.Count(s => !s.IsActive);

            TotalSalonsCountText.Text =
                totalSalons.ToString();

            ActiveSalonsCountText.Text =
                activeSalons.ToString();

            InactiveSalonsCountText.Text =
                inactiveSalons.ToString();

            _filteredSalons =
    _salons.ToList();

            _currentPage = 1;

            ApplyPagination();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri učitavanju salona:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void ApplyPagination()
    {
        var pageSize = PageSize;

        if (_currentPage > TotalPages)
            _currentPage = TotalPages;

        var pagedSalons = _filteredSalons
            .Skip((_currentPage - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        SalonsDataGrid.ItemsSource = pagedSalons;

        UpdatePaginationUI();
    }

    private void UpdatePaginationUI()
    {
        PaginationPanel.Children.Clear();

        var totalItems = _filteredSalons.Count;
        var pageSize = PageSize;

        var start = totalItems == 0
            ? 0
            : ((_currentPage - 1) * pageSize) + 1;

        var end = Math.Min(
            _currentPage * pageSize,
            totalItems);

        PaginationInfoText.Text =
            $"Prikazano {start}–{end} od {totalItems} salona";

        if (TotalPages <= 1)
        {
            PaginationPanel.Visibility =
                Visibility.Collapsed;

            return;
        }

        PaginationPanel.Visibility =
            Visibility.Visible;

        var previousButton =
            CreatePaginationButton("‹");

        previousButton.IsEnabled =
            _currentPage > 1;

        previousButton.Click +=
            PreviousPageButton_Click;

        PaginationPanel.Children.Add(
            previousButton);

        for (var page = 1;
             page <= TotalPages;
             page++)
        {
            var pageButton =
                CreatePaginationButton(
                    page.ToString());

            if (page == _currentPage)
            {
                pageButton.Background =
                    new SolidColorBrush(
                        Color.FromRgb(156, 39, 176));

                pageButton.Foreground =
                    Brushes.White;
            }

            var selectedPage = page;

            pageButton.Click +=
                (sender, e) =>
                {
                    _currentPage = selectedPage;
                    ApplyPagination();
                };

            PaginationPanel.Children.Add(
                pageButton);
        }

        var nextButton =
            CreatePaginationButton("›");

        nextButton.IsEnabled =
            _currentPage < TotalPages;

        nextButton.Click +=
            NextPageButton_Click;

        PaginationPanel.Children.Add(
            nextButton);
    }

    private Button CreatePaginationButton(
    string content)
    {
        return new Button
        {
            Content = content,
            Width = 34,
            Height = 34,
            Margin = new Thickness(0, 0, 5, 0),
            Background =
                System.Windows.Media.Brushes.Transparent,
            Foreground =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        85,
                        85,
                        85)),
            BorderBrush =
                new System.Windows.Media.SolidColorBrush(
                    System.Windows.Media.Color.FromRgb(
                        229,
                        223,
                        232)),
            BorderThickness =
                new Thickness(1),
            FontSize = 12,
            Cursor =
                System.Windows.Input.Cursors.Hand
        };
    }


    

    private void SearchTextBox_TextChanged(
    object sender,
    System.Windows.Controls.TextChangedEventArgs e)
    {
        SearchPlaceholderText.Visibility =
            string.IsNullOrWhiteSpace(SearchTextBox.Text)
                ? Visibility.Visible
                : Visibility.Collapsed;

        var search =
            SearchTextBox.Text
                .Trim()
                .ToLower();

        if (string.IsNullOrWhiteSpace(search))
        {
            _filteredSalons =
                _salons.ToList();
        }
        else
        {
            _filteredSalons =
                _salons
                    .Where(s =>
                        s.Name.ToLower().Contains(search) ||
                        s.City.ToLower().Contains(search) ||
                        s.Address.ToLower().Contains(search))
                    .ToList();
        }

        _currentPage = 1;

        ApplyPagination();
    }

    private async void AddSalonButton_Click(
     object sender,
     RoutedEventArgs e)
    {
        var window =
            new AddSalonWindow(_apiService)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();

        await LoadSalonsAsync();
    }

    private void DetailsSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var window =
            new SalonDetailsWindow(salon)
            {
                Owner = Window.GetWindow(this)
            };

        window.ShowDialog();
    }

    private async void EditSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var window =
            new EditSalonWindow(
                _apiService,
                salon)
            {
                Owner = Window.GetWindow(this)
            };

        var result = window.ShowDialog();

        if (result == true)
        {
            await LoadSalonsAsync();
        }
    }

    private async void DeleteSalonButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (sender is not FrameworkElement element)
            return;

        if (element.DataContext is not Salon salon)
            return;

        var result = MessageBox.Show(
            $"Da li želite obrisati salon \"{salon.Name}\"?\n\n" +
            "Ova radnja će trajno obrisati salon.",
            "Brisanje salona",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
            return;

        try
        {
            var deleted =
                await _apiService.DeleteAsync(
                    $"Salons/{salon.Id}");

            if (!deleted)
            {
                MessageBox.Show(
                    "Salon nije moguće obrisati.",
                    "eTermin",
                    MessageBoxButton.OK,
                    MessageBoxImage.Warning);

                return;
            }

            MessageBox.Show(
                "Salon je uspješno obrisan.",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Information);

            await LoadSalonsAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show(
                $"Greška pri brisanju salona:\n{ex.Message}",
                "eTermin",
                MessageBoxButton.OK,
                MessageBoxImage.Error);
        }
    }

    private void SearchTextBox_GotFocus(
    object sender,
    RoutedEventArgs e)
    {
        SearchPlaceholderText.Visibility =
            Visibility.Collapsed;
    }

    private void SearchTextBox_LostFocus(
        object sender,
        RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(SearchTextBox.Text))
        {
            SearchPlaceholderText.Visibility =
                Visibility.Visible;
        }
    }

    private void PreviousPageButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (_currentPage <= 1)
            return;

        _currentPage--;

        ApplyPagination();
    }

    private void NextPageButton_Click(
    object sender,
    RoutedEventArgs e)
    {
        if (_currentPage >= TotalPages)
            return;

        _currentPage++;

        ApplyPagination();
    }

    private void Page1Button_Click(
        object sender,
        RoutedEventArgs e)
    {
        _currentPage = 1;

        ApplyPagination();
    }

    private void Page2Button_Click(
        object sender,
        RoutedEventArgs e)
    {
        _currentPage = 2;

        ApplyPagination();
    }

    private void Page3Button_Click(
        object sender,
        RoutedEventArgs e)
    {
        _currentPage = 3;

        ApplyPagination();
    }
}