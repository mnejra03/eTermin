# eTermin Admin (Flutter)

Flutter Windows desktop client for eTermin administrators. This is the active desktop application; `../eTermin.Desktop` contains the legacy WPF client.

## Run locally

Start the full backend with `docker compose up --build -d` from the repository root. For terminal-free client startup, double-click `Start-eTermin.vbs`; it opens Flutter Admin after the API is reachable. The Docker database is `220043`.

If the admin password is rejected, double-click `Reset-and-Start-eTermin.vbs` in the repository root. It rebuilds the API, resets only the configured admin account, then opens the Flutter admin.

The default API URL is `http://localhost:5130/api/`. To use another address:

```powershell
flutter run -d windows --dart-define=ET_API_BASE_URL=http://localhost:5130/api/
```

The first screen authenticates against `POST Auth/login` and accepts only the `Admin` role. Use the Desktop administrator test account listed in the root `README.md`; it is seeded into a fresh Docker database.

## Migration status

- Admin login and role check: implemented.
- Desktop navigation shell: implemented.
- Dashboard statistics from the API: implemented.
- Salons: database list, search, create, edit, and delete.
- Employees and services: database lists, search, create, edit, and delete.
- Appointments: database list, search, status filter, status update, create, edit, and delete.
- Statistics: date period and status filters with daily, service, and status summaries.
- Notifications: list, mark read, and delete.
- Settings: update profile and change password.
- Appointment detail view: implemented.
- Statistics PDF and Excel exports: implemented.
- Visual styling can still be tuned against screenshots of the legacy WPF screens.
