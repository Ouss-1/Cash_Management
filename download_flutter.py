import urllib.request
import zipfile
import os

url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.0-stable.zip"
file_name = "flutter.zip"
print("Downloading flutter...")
urllib.request.urlretrieve(url, file_name)
print("Extracting flutter...")
with zipfile.ZipFile(file_name, 'r') as zip_ref:
    zip_ref.extractall("flutter_sdk")
print("Done!")
