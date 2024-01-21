from datetime import datetime
import json
import requests
import numpy


class WeatherApi():

    class currentWeatherT():

        def __init__(
            self,
            temperature: float,
            windspeed: int,
            weathercode: int,
            wdesc: str,
            time: str
        ):
            self.temperature = temperature
            self.windspeed = windspeed
            self.weathercode = weathercode
            self.winddesc = wdesc
            self.time = time
    

    def __init__(self) -> None:
        self.currentWeather: currentWeatherT = None
        self.wcTable = numpy.array([
            'clear',
            'partlyxcloudy',
            'partlyxcloudy',
            'cloudy',
            'cloudy',
            'rain',
            'rain',
            'snow',
            'rain',
            'thunderstorm'
        ])


    def get(self):

        url = 'https://api.open-meteo.com/v1/forecast?latitude=53.95&longitude=-1.06&current_weather=true'

        response = requests.get(url).json()
        print(datetime.now().strftime("%H:%M:%S") + " Made api call")

        if 'error' not in response:
            with open('weather.json', 'w') as f:
                try:
                    json.dump(response, f)
                except Exception as e:
                    print(e)
                return response
        else:
            print(response)

    def parse(self, jsonResponse):

        wspeed = int(jsonResponse['current_weather']['windspeed'])

        if wspeed < 5:
            wdesc = 'Calm'
        elif wspeed < 20:
            wdesc = 'Low'
        elif wspeed < 38:
            wdesc = 'Mid'
        elif wspeed < 50:
            wdesc = 'High'
        else:
            wdesc = 'Warn'

        self.currentWeather = self.currentWeatherT(
            float(jsonResponse['current_weather']['temperature']),
            int(jsonResponse['current_weather']['windspeed']),
            int(jsonResponse['current_weather']['weathercode']),
            wdesc,
            jsonResponse['current_weather']['time']
        )
        

    def getData(self):
        response = self.get()
        self.parse(response)
        

if __name__ == "__main__":
    api = WeatherApi()
    api.getData()

    print('temp: %f' % api.currentWeather.temperature)
    print('weathercore: %f' %api.currentWeather.weathercode)
    print('time: %s' % api.currentWeather.time)
    