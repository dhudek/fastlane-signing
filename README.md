# fastlane ruby signing. 

I have no idea what I'm doing, but needed a fastlane signing solution. some parts are missing due to not sharing sensitive data

## requirements
* android sdk tools
* x-code
* fastlane
* ruby 
* bundler

## installation 
* install ruby last tried compatible with ruby version 3.4.4
* gem install bundler
* bundle install 
* bundle exec fastlane sign_dis --verbose

### windows
* ridk exec pacman -S mingw-w64-x86_64-libffi
* ridk exec pacman -Syu
* ridk install 
* gem install bundler
* bundle config set path 'vendor/bundle'
* bundle install
* bundle exec fastlane sign_dis --verbose
