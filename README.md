# Project Beach Titan

Project Beach Titan is an iOS app designed to control a custom electric PVC beach cart via bluetooth Low Energy (and later GPS). The app sends both directional and speed data from an iOS device to a bluetooth receiver (Raspberry Pi 3 w/ NodeJS) to control the cart. The raspberry pi uses the data to control a linear actuator, for direction, and a DC motor, for power.
  
Current features include:
  
    Cruise: Allows the user to set the power level to a constant level without the need to interact with the app. 
    Power Limit: Allows the user to limit the max power allowed to the DC motor

Future enhancements will allow the cart to autonomously follow the user using a combination of GPS, bluetooth and/or Wifi.

Status:

iOS App: Successfully controlled multiple servo motors controlled by the Raspberry Pi via Bluetooth.

Beach Cart: Currently under design.

iPhone UI:

![Alt text](/beachTitanScreenshot.PNG?raw=true "Apple Watch")

Apple Watch UI:

![Alt text](/beachTitanAppleWatchScreenshot.PNG?raw=true "Apple Watch")


