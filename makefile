NAME := DefianceSign
PLATFORM := iphoneos
SCHEME := MapleSign
IPA_NAME := DefianceSign
TMP := $(TMPDIR)/$(NAME)
STAGE := $(TMP)/stage
APP := $(TMP)/Build/Products/Release-$(PLATFORM)

.PHONY: all clean $(IPA_NAME)

all: $(IPA_NAME)

clean:
	rm -rf "$(TMP)"
	rm -rf packages
	rm -rf Payload

deps:
	rm -rf deps || true
	mkdir -p deps
	curl -L -o deps/server.crt https://backloop.dev/backloop.dev-cert.crt || true
	curl -L -o deps/server.key1 https://backloop.dev/backloop.dev-key.part1.pem || true
	curl -L -o deps/server.key2 https://backloop.dev/backloop.dev-key.part2.pem || true
	cat deps/server.key1 deps/server.key2 > deps/server.pem 2>/dev/null || true
	rm -f deps/server.key1 deps/server.key2
	echo "*.backloop.dev" > deps/commonName.txt

$(IPA_NAME): deps
	xcodebuild \
	    -project DefianceSign.xcodeproj \
	    -scheme "$(SCHEME)" \
	    -configuration Release \
	    -arch arm64 \
	    -sdk $(PLATFORM) \
	    -derivedDataPath $(TMP) \
	    -skipPackagePluginValidation \
	    CODE_SIGNING_ALLOWED=NO \
	    ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	rm -rf Payload
	rm -rf "$(STAGE)/"
	mkdir -p "$(STAGE)/Payload"

	mv "$(APP)/DefianceSign.app" "$(STAGE)/Payload/DefianceSign.app"

	chmod -R 0755 "$(STAGE)/Payload/DefianceSign.app"

	cp deps/* "$(STAGE)/Payload/DefianceSign.app/" || true

	# Strip every signature (app + frameworks + dylibs) so signers start clean
	find "$(STAGE)/Payload/DefianceSign.app" \( -name "*.framework" -o -name "*.dylib" -o -name "DefianceSign" \) -exec codesign --remove-signature {} \; 2>/dev/null || true
	codesign --remove-signature "$(STAGE)/Payload/DefianceSign.app" 2>/dev/null || true
	rm -rf "$(STAGE)/Payload/DefianceSign.app"/_CodeSignature
	rm -rf "$(STAGE)/Payload/DefianceSign.app"/Frameworks/*/_CodeSignature
	find "$(STAGE)/Payload/DefianceSign.app" -depth -name "_CodeSignature" -type d -exec rm -rf {} + 2>/dev/null || true
	ln -sf "$(STAGE)/Payload" Payload
	
	mkdir -p packages
	zip -r9 "packages/$(IPA_NAME).ipa" Payload