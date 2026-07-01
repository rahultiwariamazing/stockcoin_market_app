# 🚀 CryptoInsight

An AI-powered cryptocurrency portfolio tracking and market intelligence application built with Flutter.

CryptoInsight helps users monitor cryptocurrency markets, simulate trading strategies, track portfolio performance, visualize price trends, and receive AI-generated investment insights through an intelligent chat-based assistant.

---

## 📖 Overview

CryptoInsight delivers a modern cryptocurrency analytics experience by combining real-time market tracking, portfolio simulation, interactive charts, and AI-assisted decision support into a single mobile application.

The application is designed using a scalable feature-based architecture with a clear separation between presentation, business logic, repositories, and services, making it easy to maintain and extend.

---

## ✨ Features

### 📊 Crypto Market Tracking

- Live cryptocurrency market data
- CoinGecko API integration
- Market rankings and pricing insights
- Coin search functionality
- Infinite scrolling and pagination
- Detailed market metrics

### 💼 Portfolio Management

- Buy crypto simulation
- Sell crypto simulation
- Portfolio holdings management
- Investment tracking
- Profit & Loss calculations
- Ownership validation before selling
- Portfolio performance dashboard

### 📈 Advanced Price Charts

- 24-Hour Market Trends
- 7-Day Price History
- 30-Day Price History
- Interactive chart visualizations
- Historical performance tracking

### 🤖 AI-Powered Market Intelligence

- AI-generated cryptocurrency analysis
- Market sentiment summaries
- Risk and opportunity insights
- Educational investment guidance
- Real-time AI recommendations
- Groq AI integration

### 💬 AI Assistant

- Dedicated AI chat experience
- Context-aware crypto discussions
- Suggested prompts and quick actions
- Typing indicators
- Auto-scroll conversations
- Safety filtering and content moderation

### 🎨 Premium User Experience

- Buy/Sell particle animations
- Animated portfolio updates
- Responsive layouts
- Smooth navigation
- User-friendly feedback messages
- Graceful error handling

### ✅ Validation & Safety

- Quantity validation
- Portfolio ownership checks
- Sell quantity protection
- Input validation
- Safe AI content generation
- Error recovery mechanisms

---

## 🏗️ Architecture

### Current Architecture

```text
Presentation Layer
        ↓
Providers
        ↓
Repositories
        ↓
Services
        ↓
External APIs / Local Storage
```

### Target Architecture

```text
Presentation Layer
        ↓
Providers
        ↓
Use Cases
        ↓
Repositories
        ↓
Services
        ↓
External APIs / Local Storage
```

### Architectural Principles

- Feature-Based Architecture
- Provider State Management
- Repository Pattern
- Service Layer Abstraction
- Typed Error Handling
- Modular Design
- Scalable Code Organization

---

## 📱 Application Modules

### 🔐 Authentication

- Login flow
- Session handling
- Access control
- User onboarding preparation

### 🏠 Portfolio Dashboard

- Portfolio valuation
- Holdings overview
- Investment summary
- Performance tracking

### 📈 Market Explorer

- Cryptocurrency listings
- Market data
- Search functionality
- Pagination support

### 📄 Coin Details

- Coin information
- Historical charting
- AI-powered insights
- Buy/Sell simulation

### 🤖 AI Insights

- AI crypto assistant
- Market analysis
- Educational guidance
- Intelligent recommendations

### 👤 Profile & Settings

- User preferences
- App information
- Future account management support

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

docs/
├── PROJECT_DETAILS.md
└── architecture/
```

---

## 🔄 Application Flow

```text
Login
↓
Portfolio Dashboard
↓
Market Explorer
↓
Coin Details
↓
Buy / Sell Simulation
↓
Portfolio Update
↓
AI Insights
↓
Investment Analysis
```

---

## 🌐 External Integrations

### CoinGecko API

Used for:

- Market listings
- Cryptocurrency pricing
- Historical market data
- Price chart generation

Key Endpoints:

```text
GET /coins/markets
GET /coins/{id}/market_chart
```

### Groq AI

Used for:

- Market intelligence
- AI-generated analysis
- Investment insights
- Conversational crypto assistant

Model:

```text
llama-3.1-8b-instant
```

---

## 🛠 Technology Stack

### Mobile Development

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

## 📊 Key Highlights

✅ Real-time crypto market tracking

✅ Portfolio simulation engine

✅ AI-powered investment insights

✅ Interactive AI chat assistant

✅ Advanced chart visualizations

✅ Premium animations

✅ Typed error handling

✅ Clean and scalable architecture

✅ Responsive mobile experience

✅ Extensible code structure

---

## 🚧 Project Status

### Completed

- Cryptocurrency Market Listing
- Coin Search
- Pagination
- Portfolio Dashboard
- Buy/Sell Simulation
- AI Insights
- AI Assistant Chat
- Interactive Charts
- Portfolio Storage
- Validation Layer
- Error Handling
- Premium Animations

### In Progress

- Complete Domain Layer
- Use Case Layer
- Enhanced Testing Coverage

### Planned

- Real Authentication
- Offline Market Caching
- Session Synchronization
- Enhanced AI Moderation
- Analytics & Monitoring
- Performance Optimization

---

## ⚠️ Known Limitations

- Authentication is currently simulated
- Offline caching is partially implemented
- Domain layer migration is ongoing
- Automated test coverage is limited
- AI configuration requires production-grade secret management

---

## 🚀 Future Roadmap

### Phase 1

- Routing improvements
- Provider optimization
- Widget testing
- Provider testing
- Secure API key management

### Phase 2

- Full Domain Layer
- Dependency Injection enhancement
- Structured logging
- Telemetry support
- AI safety improvements

### Phase 3

- Production authentication
- Offline synchronization
- Comprehensive integration testing
- Advanced portfolio analytics
- Multi-device support

---

## 📚 Documentation

Detailed technical documentation is available in:

```text
docs/PROJECT_DETAILS.md
```

Documentation includes:

- Architecture Overview
- Module Breakdown
- Data Flow
- API Integration
- State Management
- Feature Analysis
- Security Review
- Future Roadmap

---

## 👨‍💻 Developer

**Rahul Tiwari**

Mobile Application Architect | Cloud & AI Enthusiast

**Technology Stack**

```text
.NET • MAUI • React Native • Flutter • Azure • Firebase • AI
```

---

## 📄 License

Copyright © 2026 Rahul Tiwari

All Rights Reserved.

Unauthorized use, modification, reproduction, distribution, or commercial exploitation of this software is prohibited without prior written permission from the copyright holder.
