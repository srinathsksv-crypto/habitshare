@echo off
"D:\App Development\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore android\app\release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass habitshare123 -keypass habitshare123 -dname "CN=HabitShare, OU=Development, O=HabitShare, L=City, S=State, C=US"
if %errorlevel% neq 0 (
  echo Failed to generate key
) else (
  echo Successfully generated key
  "D:\App Development\Android Studio\jbr\bin\keytool.exe" -list -v -keystore android\app\release-keystore.jks -alias upload -storepass habitshare123 > key_output.txt
)
