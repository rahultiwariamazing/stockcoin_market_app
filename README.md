# 🚀 StockCoin Market App

A Flutter-based cryptocurrency portfolio tracking application that helps users monitor market trends, simulate crypto trading, analyze portfolio performance, and receive AI-powered market insights.

---

## 📱 Overview

StockCoin Market App provides a clean and modern cryptocurrency tracking experience. Users can browse live crypto market data, simulate buy and sell transactions, track portfolio performance, and interact with AI-powered insights for informed decision-making.

The application is designed using a feature-based architecture with a strong separation between UI, business logic, repositories, and services.

---

## ✨ Features

### 📊 Market Tracking
- Real-time cryptocurrency market data
- CoinGecko API integration
- Search functionality
- Pagination support
- Market ranking and pricing information

### 💰 Portfolio Management
- Buy crypto simulation
- Sell crypto simulation
- Portfolio holdings tracking
- Investment value tracking
- Profit/Loss calculations
- Ownership validation

### 📈 Price Charts
- 1 Day price trend
- 7 Day price trend
- 1 Month price trend
- Interactive chart visualization

### 🤖 AI-Powered Insights
- AI-generated crypto analysis
- Market sentiment insights
- Investment guidance
- Groq AI integration

### 💬 AI Assistant Chat
- Dedicated AI Insights screen
- Interactive chat experience
- Suggested prompts/chips
- Typing indicators
- Auto-scroll support
- Safety filtering for harmful content

### 🎨 Premium User Experience
- Buy/Sell particle animations
- Animated portfolio badge updates
- Smooth navigation
- User-friendly error handling
- Responsive layouts

### ✅ Validation & Safety
- Quantity validation
- Ownership checks
- Sell quantity protection
- Input validation
- AI content moderation

---

## 🏗️ Architecture

Current Architecture:

```text
UI
↓
Providers
↓
Repositories
↓
Services
↓
API / Local Storage
```

Target Architecture:

```text
UI
↓
Providers
↓
Use Cases
↓
Repositories
↓
Services
↓
API / Local Storage
```

Architecture Style:

- Feature-based structure
- Provider state management
- Repository pattern
- Service layer abstraction
- Typed error handling
- Local persistence support

---

## 📱 Screens

### 🔐 Login Screen
- Form validation
- Simulated authentication flow
- User access management

### 🏠 Dashboard
- Portfolio summary
- Holdings overview
- Portfolio value tracking

### 📈 Market Screen
- Cryptocurrency listings
- Search functionality
- Pagination
- Market metrics

### 📄 Crypto Details Screen
- Coin information
- Interactive charts
- AI insights
- Buy/Sell simulation

### 🤖 AI Insights Screen
- AI-powered crypto assistant
- Chat interface
- Suggested prompts
- Intelligent responses

### 👤 User Screen
- User-related settings
- Application information

---

## 🛠️ Technology Stack

### Frontend
- Flutter
- Dart

### State Management
- Riverpod

### Networking
- Dio

### Local Storage
- Hive

### APIs
- CoinGecko API
- Groq AI API

### Architecture
- Feature-Based Architecture
- Repository Pattern
- Provider Pattern

---

## 📂 Project Structure

```text
lib/
├── config/
│   ├── router/
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── local/
│   └── network/
│
├── features/
│   ├── auth/
│   ├── crypto/
│   ├── home/
│   ├── insights/
│   ├── portfolio/
│   └── splash/
│
├── shared/
│   ├── animations/
│   └── widgets/
│
└── main.dart
```

---

## 🔄 Application Flow

```text
Login
↓
Dashboard
↓
Market
↓
Crypto Details
↓
Buy / Sell Simulation
↓
Portfolio Update
↓
AI Insights
```

---

## 📡 APIs Used

### CoinGecko API

Used for:

- Market listings
- Cryptocurrency pricing
- Market data
- Historical charts

Endpoints:

```text
GET /coins/markets
GET /coins/{id}/market_chart
```

### Groq AI

Used for:

- Crypto insights
- AI recommendations
- AI chat assistant

Model:

```text
llama-3.1-8b-instant
```

---

## ⚡ Key Highlights

- Real-time crypto market tracking
- Portfolio simulation engine
- AI-powered investment insights
- Interactive chat assistant
- Advanced animations
- User-friendly validation
- Typed error handling
- Clean architecture approach

---

## ✅ Current Status

### Completed

- Crypto Market Listing
- Search Functionality
- Pagination
- Portfolio Dashboard
- Buy/Sell Simulation
- AI Crypto Insights
- AI Chat Assistant
- Quantity Validation
- Interactive Charts
- Local Portfolio Storage
- Error Management
- Premium Animations

### In Progress

- Complete Domain Layer
- Use Case Layer
- Enhanced Testing

### Planned

- Real Authentication
- Offline Market Cache
- Session Persistence
- Improved AI Moderation
- Integration Testing
- Analytics & Monitoring

---

## ⚠️ Known Limitations

- Authentication is currently simulated
- Offline market cache is incomplete
- Domain/use-case layer migration is in progress
- Automated test coverage is limited
- AI key management requires production hardening

---

## 🚀 Future Roadmap

### Phase 1
- Fix routing inconsistencies
- Move remaining logic into providers
- Add widget and provider testing
- Secure AI key management

### Phase 2
- Introduce complete domain layer
- Add dependency injection improvements
- Enhance logging and telemetry
- Improve AI safety layer

### Phase 3
- Real authentication backend
- Offline sync support
- Full integration testing
- Enhanced portfolio analytics

---

## 👨‍💻 Developer

**Rahul Tiwari**

**Mobile Architect | Cloud & AI Enthusiast**

.NET • MAUI • React Native • Flutter • Azure • Firebase • AI

---

## 📄 License

Copyright © 2026 Rahul Tiwari

All Rights Reserved.

Unauthorized use, reproduction, modification, or distribution of this software is prohibited without prior written permission from the copyright holder.
