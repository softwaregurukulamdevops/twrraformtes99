https://teams.microsoft.com/l/meetup-join/19%3ameeting_OWNkNjBkZWUtYWM1YS00Y2IwLWIyMDYtOWQ4MGU5MzExYWEw%40thread.v2/0?context=%7b%22Tid%22%3a%2224c341f8-8c8f-44ef-a388-6fa08c3eef6a%22%2c%22Oid%22%3a%22c5cbfd7e-d586-44a1-97c7-db23a22eafc9%22%7d



  - task: PowerShell@2
      displayName: 'Clean agent directories after successful build'
      condition: succeeded()
      inputs:
        targetType: 'inline'
        script: |
          Write-Host "Cleaning agent directories..."

          $dirs = @(
            "$env:BUILD_ARTIFACTSTAGINGDIRECTORY",
            "$env:BUILD_BINARIESDIRECTORY",
            "$env:BUILD_SOURCESDIRECTORY",
            "$env:BUILD_STAGINGDIRECTORY"
          )

          foreach ($dir in $dirs) {
            if (Test-Path $dir) {
              Write-Host "Removing: $dir"
              Remove-Item -Recurse -Force -Path $dir
            } else {
              Write-Host "Directory not found: $dir"
            }
          }
