ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = Hue
Hue_FILES = Tweak.xm
Hue_FRAMEWORKS = UIKit
Hue_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
