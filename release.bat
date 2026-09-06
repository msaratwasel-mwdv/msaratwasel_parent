@echo off
set "TARGET=%1"

if "%TARGET%"=="prod" goto deploy_prod
if "%TARGET%"=="production" goto deploy_prod

:deploy_alpha
echo ======================================================
echo   Deploying msaratwasel_parent to CLOSED TESTING (alpha)...
echo ======================================================
git push origin main
echo.
echo [OK] Pushed to main branch!
echo GitHub Actions is now deploying to Closed Testing (alpha).
goto end

:deploy_prod
echo ======================================================
echo   Deploying msaratwasel_parent to PRODUCTION...
echo ======================================================
git push origin main:production
echo.
echo [OK] Pushed to production branch!
echo GitHub Actions is now deploying directly to Google Play Production.
goto end

:end
