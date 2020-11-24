# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Waterloo Travel Diary' do
  use_frameworks!

  pod 'AWSS3'
  pod 'AWSCore'
  pod 'AWSCognito'
  # Pods for Waterloo Travel Diary
  
  plugin 'cocoapods-keys', {
  :keys => [
    "CognitoIdentityPoolID",
  ]}

  target 'Waterloo Travel DiaryTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Waterloo Travel DiaryUITests' do
    # Pods for testing
  end

end
