import argparse
import os
import sys

sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/..'))
from rgbmatrix import RGBMatrix, RGBMatrixOptions

class MatrixBase(object):

    def __init__(self, *args, **kwargs):
        self.parser = argparse.ArgumentParser()

        self.parser.add_argument("--led-slowdown-gpio", action="store", help="Slow down writing to GPIO. Range: 0..4. Default: 4", default=4, type=int)
        # Add max brightness
        # Add animation speed
    
    def run(self):
        pass

    def process(self):

        options = RGBMatrixOptions()

        options.rows = 64
        options.cols = 64
        options.chain_length = 1
        options.parallel = 1
        options.hardware_mapping = 'adafruit-hat'   # For use with the adafruit bonnet
        
        self.args = self.parser.parse_args()
        
        options.gpio_slowdown = self.args.led_slowdown_gpio

        self.matrix = RGBMatrix(options=options)

        try:
            # Start loop
            print("Press CTRL-C to stop")
            self.run()
        except KeyboardInterrupt:
            print("Exiting\n")
            sys.exit(0)

        return True