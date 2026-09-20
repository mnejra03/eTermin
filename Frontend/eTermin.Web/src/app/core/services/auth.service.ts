import { Injectable } from '@angular/core';
import { Observable, tap } from 'rxjs';

import { ApiService } from './api.service';
import {
  AuthResponse,
  LoginRequest,
  RegisterRequest
} from '../../shared/models/auth.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private readonly tokenKey = 'eTermin_token';
  private readonly userKey = 'eTermin_user';

  constructor(private api: ApiService) {}

  login(request: LoginRequest): Observable<AuthResponse> {
    return this.api.post<AuthResponse>('Auth/login', request).pipe(
      tap(response => {
        this.saveAuthData(response);
      })
    );
  }

  register(request: RegisterRequest): Observable<AuthResponse> {
    return this.api.post<AuthResponse>('Auth/register', request).pipe(
      tap(response => {
        this.saveAuthData(response);
      })
    );
  }

  logout(): void {
    localStorage.removeItem(this.tokenKey);
    localStorage.removeItem(this.userKey);
  }

  getToken(): string | null {
    return localStorage.getItem(this.tokenKey);
  }

  getUser(): AuthResponse | null {
    const user = localStorage.getItem(this.userKey);

    if (!user) {
      return null;
    }

    return JSON.parse(user) as AuthResponse;
  }

  isLoggedIn(): boolean {
    return !!this.getToken();
  }

  private saveAuthData(response: AuthResponse): void {
    localStorage.setItem(this.tokenKey, response.token);

    localStorage.setItem(
      this.userKey,
      JSON.stringify(response)
    );
  }
}