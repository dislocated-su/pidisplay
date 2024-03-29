import os
import string
import time
import sys
from datetime import datetime
import math
from typing import Dict, List
from PIL import Image

if "PILED_EMULATE" in os.environ:
    from RGBMatrixEmulator import graphics
else:
    from rgbmatrix import graphics

from MatrixBase import MatrixBase
from weatherapi import WeatherApi
import cython

cdef extern from "math.h":
    double sin(double x)

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

        # Load fonts
        self.clockFont = graphics.Font()
        self.largeFont = graphics.Font()
        self.mediumFont = graphics.Font()
        self.smallFont = graphics.Font()

        self.clockFont.LoadFont("fonts/8x13B.bdf") # 9x18B.bdf
        self.largeFont.LoadFont("fonts/6x12.bdf")
        self.mediumFont.LoadFont("fonts/6x9.bdf")
        self.smallFont.LoadFont("fonts/4x6.bdf")

        self.whiteColor = graphics.Color(255,255,255)

        self.images = {}

        for file in os.listdir("./images"):
            filename = os.fsdecode(file)
            if filename.endswith(".png"):
                img = Image.open('./images/'+filename)
                img.thumbnail((15,18))
                self.images[os.path.splitext(filename)[0]] = img

        self.getData()
        self.kill_now = False

    def exit_gracefully(self,_signo, _stack_frame):
        print("\nStopping gracefully.")
        self.kill_now = True

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
        
        self.weatherIcon = self.images[rawWeatherDesc]

        if len(self.weatherData['winddesc']) == 3:
            self.windFont = self.mediumFont
        else:
            self.windFont = self.smallFont


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

        cdef int glyphPos[5]
        glyphPos[:] = [-16, 0, 16, 32, 48]

        while not self.kill_now:

            offscreen_canvas.Clear()

            colour = next(colorGen)
            now = datetime.now()
            clock_time = now.strftime("%H:%M:%S")

            cDay = now.strftime("%A")
            cDate = now.strftime("%d %b")
            
            # Time
            graphics.DrawText(offscreen_canvas, self.clockFont, 0, 14, colour, clock_time)

            # Date
            graphics.DrawText(offscreen_canvas, self.mediumFont, 0, 21, self.whiteColor, cDay)
            graphics.DrawText(offscreen_canvas, self.mediumFont, 0, 21 + 7, self.whiteColor, cDate)

            # Get weather data every hour
            if (now - self.callTimer).total_seconds() >= 3600:
                self.getData()

            # Draw weather icon, temperature
            offscreen_canvas.SetImage(self.weatherIcon.convert('RGB'), 1, 29)
            graphics.DrawText(offscreen_canvas, self.largeFont, 18, 38, self.whiteColor, str(self.weatherData['temperature']))
            
            # Draw degree symbol
            for pixel_x in range(1,4):
                for pixel_y in range(1,4):
                    if (pixel_x == 2 or pixel_y == 2) and pixel_x != pixel_y:
                        offscreen_canvas.SetPixel(pixel_x + 30, pixel_y + 29, 255, 255, 255)
            
            # Draw wind icon and wind description
            offscreen_canvas.SetImage(self.images['windy'].convert('RGB'), 35, 32)
            graphics.DrawText(offscreen_canvas, self.windFont, 47, 38, self.whiteColor, str(self.weatherData['winddesc'], encoding='utf-8'))

            # Draw weather description
            graphics.DrawText(offscreen_canvas, self.smallFont, 1, 48, self.whiteColor, str(self.weatherData['desc'], encoding='utf-8'))


            for mod in range(5):
                offscreen_canvas.SetImage(self.images['christmas'].convert('RGB'), glyphPos[mod], 51)

            j += 1
            if j == 20:
                j = 0
                i += 1
                
                for mod in range(5):
                    glyphPos[mod] = i + (mod * 16)

                if glyphPos[0] == 0:
                    i = -16

            offscreen_canvas = self.matrix.SwapOnVSync(offscreen_canvas)

        offscreen_canvas.Clear()
        offscreen_canvas = self.matrix.SwapOnVSync(offscreen_canvas)
