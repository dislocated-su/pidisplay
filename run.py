import signal

import sys
import os

sys.path.append(os.path.abspath(os.path.dirname(__file__) + '/build'))

from PiDisplay import PiDisplay

if __name__ == "__main__":
  display = PiDisplay()
  signal.signal(signal.SIGINT, display.exit_gracefully)
  signal.signal(signal.SIGTERM, display.exit_gracefully)
  if (not display.process()):
      display.print_help()
