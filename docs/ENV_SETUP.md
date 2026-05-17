# Environment Configuration Guide

This project uses environment variables to manage sensitive configuration like API keys.

## Setup

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Get your Unsplash API Client ID:
   - Visit https://unsplash.com/developers
   - Register/Login to your account
   - Create a new application
   - Copy the Client ID

3. Update `.env` file:
   ```
   UNSPLASH_CLIENT_ID=your_actual_client_id_here
   ```

4. The `.env` file is already added to `.gitignore`, so your API key won't be committed to the repository.

## Usage

The app will automatically load the environment variables from `.env` file when it starts.

## Security Notes

- Never commit `.env` file to version control
- Only share `.env.example` with placeholder values
- For production builds, consider using CI/CD environment variables
