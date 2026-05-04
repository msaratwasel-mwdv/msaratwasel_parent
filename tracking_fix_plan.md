# خطة تنفيذية شاملة لإصلاح وتطوير منظومة تتبع الحافلات اللحظية (Real-time Tracking)

الهدف من هذه الخطة هو الانتقال بنظام التتبع في مشروع "مسارات واصل" من مجرد "نموذج أولي / محاكاة" إلى نظام **Production-Ready**، موثوق، ويعمل بشكل لحظي حقيقي بين السائق والسيرفر ولوحة التحكم.

## User Review Required

> [!CAUTION]
> تنفيذ هذه الخطة سيقوم بإلغاء التتبع "الوهمي" (Simulation) من تطبيق السائق واستبداله بالتتبع الحقيقي عبر الـ GPS. هذا يعني أن التطبيق سيطلب صلاحيات الموقع من السائق ولن يتحرك الباص على الخريطة إلا إذا تحرك هاتف السائق فعلياً.

> [!WARNING]
> في لوحة التحكم، سنحتاج لتثبيت حزم `laravel-echo` و `pusher-js` لربطها مع سيرفر Reverb الحالي. 

## Proposed Changes

---

### 1. تطبيق الجوال (Flutter) - طبقة التتبع الحقيقية

سنقوم بالتخلص من المؤقت الوهمي (`Timer.periodic`) وننتقل لقراءة حساسات הـ GPS في الهاتف.

#### [MODIFY] `pubspec.yaml`
- إضافة حزمة `geolocator: ^13.0.1` لقراءة الموقع الفعلي عبر الـ GPS.

#### [NEW] `lib/core/services/location_service.dart`
- إنشاء خدمة مخصصة مسؤولة عن:
  - طلب صلاحيات الموقع من السائق (`Always Allow`).
  - فتح قناة استماع (Stream) لتحديثات الموقع الفعلية `Geolocator.getPositionStream`.
  - تنعيم قراءات الموقع (إرسال البيانات فقط إذا تحرك السائق لمسافة معينة مثلاً 10 أمتار لتخفيف الضغط على السيرفر والبطارية).

#### [MODIFY] `route_navigation_screen.dart`
- استبدال الكود الوهمي `_startLocationUpdates()` لكي يعتمد على البيانات القادمة من الـ `LocationService` الحقيقية بدلاً من مصفوفة النقاط الصلبة `_getMuscatRoutePoints`.

---

### 2. الباك اند (Laravel) - طبقة التنبيهات والأمان

إصلاح العيب البرمجي الذي يمنع عمل الإشعارات اللحظية باقتراب الحافلة من منزل الطالب.

#### [MODIFY] `app/Http/Controllers/Api/BusLocationController.php`
- في دالة `checkProximityToHomes`:
  - الكود الحالي يبحث عن حقل خاطئ: `$guardian->home_latitude`.
  - **التعديل:** سيتم التبديل إلى الأعمدة الصحيحة والموجودة فعلياً في قاعدة البيانات (`$guardian->latitude` و `$guardian->longitude`).
  - هذا التعديل سيضمن أن يتم حساب المسافة وإرسال الـ Push Notifications بنجاح للأهالي.

---

### 3. لوحة تحكم الإدارة (React / Inertia) - التحديث اللحظي

تهيئة الواجهة الأمامية للاستماع لترددات السيرفر عبر WebSockets بدلاً من الاعتماد على عمل Refresh (تحديث يدوي) للصفحة.

#### [MODIFY] `package.json`
- تشغيل الأمر `npm install laravel-echo pusher-js` لتثبيت مكتبات الاستماع للـ WebSockets (المتوافقة مع Laravel Reverb).

#### [MODIFY] `resources/js/bootstrap.ts`
- إضافة وتهيئة إعدادات `window.Echo` مع بيانات الـ Reverb (المتوفرة في ملف `.env` مثل `VITE_REVERB_APP_KEY` و `VITE_REVERB_HOST`).

#### [MODIFY] `resources/js/Pages/Admin/Dashboard.tsx` (or `GoogleMapContainer.tsx`)
- تحويل خاصية `mapData` (التي تأتي كـ Props ثابتة عند التحميل) إلى `State` تفاعلية: `const [liveMapData, setLiveMapData] = useState(mapData)`.
- إضافة `useEffect` يستمع للقناة:
  ```javascript
  Echo.private(`bus.${busId}`)
      .listen('.bus.location.updated', (e) => {
          // تحديث مكان الماركر برمجياً
      });
  ```
- عند وصول موقع جديد، يتم تحديث مصفوفة الـ `liveMapData` تلقائياً ليتحرك الباص (Marker) فورياً على الخريطة.

## Verification Plan

### Automated Tests
- لا تنطبق اختبارات الوحدة هنا بسبب الاعتماد المباشر على حساسات الهواتف والاتصال اللحظي (WebSockets).

### Manual Verification
1. **تطبيق السائق:** تشغيل التطبيق والتأكد من أنه يطلب صلاحية الموقع (Location Permission)، ومراقبة الـ Console للتأكد من التقاط الإحداثيات الحقيقية وإرسالها للـ API.
2. **الباك اند:** مراقبة جداول الإشعارات وسجلات الـ Logs للتأكد من حساب المسافة (Haversine) وإرسال إشعار FCM بنجاح لولي الأمر عند الاقتراب من النطاق (2 كم).
3. **لوحة التحكم:** فتح الخريطة، وتحريك جهاز السائق (أو استخدام Mock Location في محاكي الأندرويد) والتأكد من أن العلامة (Marker) الخاصة بالحافلة تتحرك مباشرة على شاشة الإدارة دون الحاجة لضغط زر (F5).
