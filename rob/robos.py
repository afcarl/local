import sys
print('import robos')
if sys.platform == 'win32':
    print('importing windows')
    try:
        from rob_helpers_windows import *
    except ImportError as ex:
        print(ex)
else:
    print('importing linux')
    from rob_linux_helpers import *
