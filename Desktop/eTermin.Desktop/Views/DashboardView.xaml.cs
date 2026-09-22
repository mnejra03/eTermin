using System.Windows.Controls;
using eTermin.Desktop.Services;

namespace eTermin.Desktop.Views;

public partial class DashboardView : UserControl
{
    private readonly ApiService _apiService;

    public DashboardView(ApiService apiService)
    {
        InitializeComponent();

        _apiService = apiService;
    }
}