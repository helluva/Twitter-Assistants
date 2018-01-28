from pynput.keyboard import Key, Listener

import ResponseTest

#press cmd key to have bot reply top all unanswered tweets
def on_press(key):
    print('{0} pressed'.format(
        key))
    if key == Key.cmd:
        ResponseTest.run_reply_cycle()

def on_release(key):
    print('{0} release'.format(
        key))
    if key == Key.ctrl:
        # Stop listener
        return False

# Collect events until released
with Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()