# Task: Driver Navigation Flow & Sync Update

- [ ] **Step 1: Domain & Data Layer Updates**
    - [ ] Update `RouteRepository` to include `notifyParentNearHouse`.
    - [ ] Update `RouteRepositoryImpl` with the API call.
- [ ] **Step 2: UI Redesign - Route Navigation Screen**
    - [ ] Add "Trip Type" (ذهاب / عودة) badge.
    - [ ] Replace action button with "Near House" (بجوار المنزل).
    - [ ] Implement 2-minute Waiting Timer.
    - [ ] Implement "Immediate Advance" to next student route on map.
    - [ ] Add "Waiting Student Card" (Floating card).
    - [ ] Remove manual boarding/absence buttons from Map screen.
- [ ] **Step 3: Attendance Management - My Students Panel**
    - [ ] Verify/Create "My Students" (طلابي) screen.
    - [ ] Add manual attendance/absence buttons with role-based authority.
- [ ] **Step 4: Safety & Sync - End Trip Screen**
    - [ ] Implement strict occupancy check (must be zero to end).
    - [ ] Ensure real-time sync with Supervisor app.
- [ ] **Step 5: Verification**
    - [ ] Manual test of the full flow (Go & Return).
