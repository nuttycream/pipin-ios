# pipin-ios
![Version](https://img.shields.io/badge/version-0.0.1-orange)  
A simple iOS application to communicate with a [pipin web server](https://github.com/nuttycream/pipin) running on a Raspberry Pi.

<p align="center">
    <img src="https://i.imgur.com/RRAMQNJ.png" alt="preview" width=25%>
</p>

> [!IMPORTANT]
> pipin-ios requires pipin 0.2 (unreleased as of 5/10/2025)

## Features
- Toggle individual pins (0-27)
- Wicked fast toggling through WebSockets
- Queue various actions
  - Toggle
  - Delay(ms)
  - Wait For High
  - Wait For Low
  - Pull Down
  - Pull Up
- Loop action sequences
- Dark/Light Mode

## Usage
- Run and build the xcode project
- Ensure pipin is running on the raspberry pi
- Enter the IP address and port of the pipin web server
- Press `Initialize` to enable the GPIO Pins
- bobs ur uncle

## Attribution
- Bryan Yao [GitHub](https://github.com/brayo)
- John Carter [GitHub](https://github.com/nuttycream)
- Jingxi Hu [GitHub](https://github.com/Heison0818)
