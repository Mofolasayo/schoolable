# Mobile App Design System & Plan (ARP)

## Design Philosophy
"Sleek, Intuitive, Soft Minimalist."
- **Visuals**: Rounded components, soft shadows, vibrant but professional colors.
- **Typography**: Inter (or system default sans-serif), clean hierarchy.
- **Interaction**: Smooth transitions, clear feedback, bottom navigation.

## Color Palette
Consistent with the Web Dashboard (Slate/Indigo theme) but with added vibrancy.

### Primary
- **Primary**: `#575FF4` (Indigo 500) - Main actions, active states.
- **Primary Dark**: `#4248C7` (Indigo 700) - Pressed states.
- **Primary Light**: `#EEF2FF` (Indigo 50) - Backgrounds for active items.

### Accents
- **Teal**: `#14B8A6` (Teal 500) - Success, positive trends.
- **Purple**: `#A855F7` (Purple 500) - Insights, special features.
- **Amber**: `#F59E0B` (Amber 500) - Warnings, pending states.
- **Rose**: `#F43F5E` (Rose 500) - Errors, negative trends.

### Neutrals (Slate)
- **Background**: `#F8FAFC` (Slate 50) - Main scaffold background.
- **Surface**: `#FFFFFF` (White) - Cards, sheets, bottom nav.
- **Text Main**: `#0F172A` (Slate 900) - Headings, primary text.
- **Text Muted**: `#64748B` (Slate 500) - Secondary text, captions.
- **Border**: `#E2E8F0` (Slate 200) - Dividers, outlines.

## Typography
- **Headings**: Bold, Slate 900.
- **Body**: Regular/Medium, Slate 900.
- **Captions**: Regular, Slate 500.

## Components

### Buttons
- **Primary**: Solid Indigo 500, White text, Rounded-xl (12px).
- **Secondary**: Outline Slate 200, Slate 900 text, Rounded-xl.
- **Ghost**: Transparent, Indigo 500 text.

### Cards
- White background, Rounded-2xl (16px).
- Soft shadow: `BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))`.
- Border: 1px solid Slate 100 (optional).

### Inputs
- Filled (Slate 50) or Outlined (Slate 200).
- Rounded-xl (12px).
- Focus: Indigo 500 ring.

---

## Screen Specifications

### 1. Login & Onboarding
- **Login**: Clean, centered white card on soft gradient background. Email/Password fields. "Sign In" large primary button.
- **Onboarding**: Carousel with illustrations.
    - Slide 1: "Track Your Impact" (KPIs).
    - Slide 2: "Easy Attendance" (GPS + Selfie).
    - Slide 3: "Stay Connected" (Team Chat).

### 2. Home Screen
- **Header**: "Hello, [Name]", Profile pic, Notification bell.
- **KPI Summary**: Horizontal scroll or 2x2 Grid.
    - Cards: Task Score, Attendance, Compliance, Feedback.
    - Visual: Icon + Value + Label + Mini trend indicator.
- **Quick Actions**: Row of pill buttons (Check-in, View Tasks, Messages).
- **Today's Tasks**: List of top 3 pending tasks.
    - Row: Checkbox | Title + Due Time | Status Chip.

### 3. Task Management
- **List View**: Filter chips (All, Pending, Completed).
- **Task Card**: Title, Description snippet, Due Date, Priority Badge, Progress bar.
- **Detail View**:
    - Large Title, Status.
    - Description.
    - Attachments list.
    - "Submit Proof" button (opens bottom sheet for Photo/Note).

### 4. Attendance Check-in
- **Main**: Large circular "Check In" button (pulsing effect if not checked in).
- **Map**: Mini map preview showing current location pin.
- **Camera**: Full-screen camera view with overlay for selfie.
- **History**: List of recent logs (Date, Time, Status pill).

### 5. In-House Communication (Chat)
- **Channel List**: #general, #announcements, Direct Messages.
- **Chat View**:
    - Bubbles: User (Right, Indigo), Others (Left, Slate 100).
    - Input: Rounded text field with attachment/mic icons.

### 6. Profile & KPI
- **Header**: Large avatar, Name, Role, Department.
- **Performance Graph**: Line chart showing KPI score over last 6 weeks.
- **Breakdown**: List of categories with progress bars.

---

## Implementation Plan
1.  **Theme Setup**: Update `app_colors.dart` and `main.dart` theme.
2.  **Login View**: Create `LoginView`.
3.  **Home View**: Revamp `HomeView` with new widgets.
4.  **Navigation**: Ensure Bottom Nav is set up in a `DashboardView` (shell).
