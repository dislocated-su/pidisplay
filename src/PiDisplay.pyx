#!/usr/bin/env python
import os
import string
import time
import sys
from datetime import datetime
import math
from typing import Dict, List
from PIL import Image


from rgbmatrix import RGBMatrix, RGBMatrixOptions, graphics

from MatrixBase import MatrixBase
from weatherapi import WeatherApi
import cython

cdef extern from "math.h":
    double sin(double x)

import signal

class Resources():

    def __init__(
        self, clockFont: graphics.Font,
        largeFont: graphics.Font, 
        mediumFont: graphics.Font,
        smallFont: graphics.Font,
        whiteColor: graphics.Color,
        images: Dict):

            self.clockFont = clockFont
            self.largeFont = largeFont
            self.mediumFont = mediumFont
            self.smallFont = smallFont
            self.clockFont = clockFont
            self.whiteColor = whiteColor
            self.images = images

weatherData = cython.struct( 
    temperature=cython.int,
    windspeed=cython.int,
    winddesc=cython.p_char,
    desc=cython.p_char
)

class PiDisplay(MatrixBase):

    self.weatherIcon: Image.Image
    self.weatherData: cython.struct

    def __init__(self, *args, **kwargs):
        super(PiDisplay,self).__init__(*args, **kwargs)

        # Init API

        # Load fonts
        clockFont = graphics.Font()
        largeFont = graphics.Font()
        mediumFont = graphics.Font()
        smallFont = graphics.Font()

        clockFont.LoadFont("fonts/8x13B.bdf") # 9x18B.bdf
        largeFont.LoadFont("fonts/6x12.bdf")
        mediumFont.LoadFont("fonts/6x9.bdf")
        smallFont.LoadFont("fonts/4x6.bdf")

        whiteColor = graphics.Color(255,255,255)

        images = {}

        for file in os.listdir("./images"):
            filename = os.fsdecode(file)
            if filename.endswith(".png"):
                img = Image.open('./images/'+filename)
                img.thumbnail((15,18))
                images[os.path.splitext(filename)[0]] = img

        self.resources = Resources(
            clockFont,
            largeFont,
            mediumFont,
            smallFont,
            whiteColor,
            images
        )

        self.getData()
        self.kill_now = False

    def exit_gracefully(self,_signo, _stack_frame):
        self.kill_now = True
        print("Stopped gracefully.")
        sys.exit(0)

    def getData(self):
        self.callTimer = datetime.now()

        weather = WeatherApi()

        weather.getData()

        rawWeatherDesc = weather.wcTable[int(str(weather.currentWeather.weathercode)[:1])]
        weatherDesc = rawWeatherDesc.replace('x', ' ').capitalize()

        self.weatherData = weatherData(
            temperature= (int(weather.currentWeather.temperature)),
            windspeed=weather.currentWeather.windspeed,
            winddesc=bytes(weather.currentWeather.winddesc, 'utf-8'),
            desc = bytes(weatherDesc, 'utf-8')
        )
        
        self.weatherIcon = self.resources.images[rawWeatherDesc]

        if len(self.weatherData['winddesc']) == 3:
            self.windFont = self.resources.mediumFont
        else:
            self.windFont = self.resources.smallFont


    def rgb_generator(self):
        i: cython.int = 0
        freq: cython.double = .0005
        alpha: cython.double = 0.75

        while True:
            r = sin(freq * i) * 127 + 128
            g = sin(freq * i + ((2 * 3.14) / 3)) * 127 + 128
            b = sin(freq * i + ((4 * 3.14) / 3)) * 127 + 128
            
            i += 1

            yield graphics.Color(r,g,b)


        

    def run(self):
        offscreen_canvas = self.matrix.CreateFrameCanvas()
        colorGen = self.rgb_generator()

        i: cython.int = -16
        j: cython.int = 0
        x1: cython.int = i
        x2: cython.int = i + 16
        x3: cython.int = i + 32
        x4: cython.int = i + 48
        x5: cython.int = i + 64

        while not self.kill_now:


            # serve_once()

            offscreen_canvas.Clear()

            colour = next(colorGen)
            now = datetime.now()
            clock_time = now.strftime("%H:%M:%S")

            cDay = now.strftime("%A")
            cDate = now.strftime("%B %d")
            
            # Time
            graphics.DrawText(offscreen_canvas, self.resources.clockFont, 0, 14, colour, clock_time)

            # Date
            graphics.DrawText(offscreen_canvas, self.resources.mediumFont, 0, 21, self.resources.whiteColor, cDay)
            graphics.DrawText(offscreen_canvas, self.resources.mediumFont, 0, 21 + 7, self.resources.whiteColor, cDate)

            # Get weather data every hour
            if (now - self.callTimer).total_seconds() >= 3600:
                self.getData()

            # Draw weather icon, temperature
            offscreen_canvas.SetImage(self.weatherIcon.convert('RGB'), 1, 29)
            graphics.DrawText(offscreen_canvas, self.resources.largeFont, 18, 38, self.resources.whiteColor, str(self.weatherData['temperature']))
            
            # Draw degree symbol
            for pixel_x in range(1,4):
                for pixel_y in range(1,4):
                    if (pixel_x == 2 or pixel_y == 2) and pixel_x != pixel_y:
                        offscreen_canvas.SetPixel(pixel_x + 30, pixel_y + 29, 255, 255, 255)
            
            # Draw wind icon and wind description
            offscreen_canvas.SetImage(self.resources.images['windy'].convert('RGB'), 35, 32)
            graphics.DrawText(offscreen_canvas, self.windFont, 47, 38, self.resources.whiteColor, str(self.weatherData['winddesc'], encoding='utf-8'))

            # Draw weather description
            graphics.DrawText(offscreen_canvas, self.resources.smallFont, 1, 48, self.resources.whiteColor, str(self.weatherData['desc'], encoding='utf-8'))


            offscreen_canvas.SetImage(self.resources.images['dynamite'].convert('RGB'), x1,51)
            offscreen_canvas.SetImage(self.resources.images['dynamite'].convert('RGB'), x2,51)
            offscreen_canvas.SetImage(self.resources.images['dynamite'].convert('RGB'), x3,51)
            offscreen_canvas.SetImage(self.resources.images['dynamite'].convert('RGB'), x4,51)
            offscreen_canvas.SetImage(self.resources.images['dynamite'].convert('RGB'), x5,51)
            
            j += 1
            if j == 20:
                j = 0
                i += 1
                
                x1 = i
                x2 = i + 16
                x3 = i + 32
                x4 = i + 48
                x5 = i + 64

                if x1 == 0:
                    i = -16


            offscreen_canvas = self.matrix.SwapOnVSync(offscreen_canvas)

        offscreen_canvas.Clear()
        offscreen_canvas = self.matrix.SwapOnVSync(offscreen_canvas)


# Main function
if __name__ == "__main__":
  display = PiDisplay()
  if (not display.process()):
      display.print_help()