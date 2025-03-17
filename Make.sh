#!/bin/sh
#~ .NET Project
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME=`basename $0`

if [ -t 1 ]; then
    ANSI_RESET="$(tput sgr0)"
    ANSI_RED="`[ $(tput colors) -ge 16 ] && tput setaf 9 || tput setaf 1 bold`"
    ANSI_YELLOW="`[ $(tput colors) -ge 16 ] && tput setaf 11 || tput setaf 3 bold`"
    ANSI_MAGENTA="`[ $(tput colors) -ge 16 ] && tput setaf 13 || tput setaf 5 bold`"
    ANSI_PURPLE="$(tput setaf 5)"
    ANSI_CYAN="`[ $(tput colors) -ge 16 ] && tput setaf 14 || tput setaf 6 bold`"
fi

if [ "$@" = "--help" ] || [ "$@" = "-h" ]; then
    echo "Usage: $SCRIPT_NAME [target]..."
    echo
    echo "Targets:"
    echo "  clean      Clean all build artifacts"
    echo "  run        Run the project"
    echo "  test       Run tests"
    echo "  benchmark  Run benchmarks"
    echo "  examples   Compile examples"
    echo "  debug      Compile in debug mode"
    echo "  release    Compile in release mode"
    echo "  package    Package the project"
    echo "  publish    Publish the project"
    echo
    echo "Actions with '~' prefix are negated"
    echo
    echo "Examples:"
    echo "  make release         - Compile in release mode"
    echo "  make ~clean release  - Compile in release mode without cleaning"
    echo
    exit 0
fi


if ! [ -e "$SCRIPT_DIR/.meta" ]; then
    echo "${ANSI_RED}Meta file not found${ANSI_RESET}" >&2
    exit 113
fi

if ! command -v git >/dev/null; then
    echo "${ANSI_YELLOW}Missing git command${ANSI_RESET}"
fi


HAS_CHANGES=$( git status -s 2>/dev/null | wc -l )
if [ "$HAS_CHANGES" -gt 0 ]; then
    echo "${ANSI_YELLOW}Uncommitted changes present${ANSI_RESET}"
fi


PROJECT_NAME=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PROJECT_NAME:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PROJECT_NAME" = "" ]; then
    echo "${ANSI_PURPLE}Project name ........: ${ANSI_RED}not found${ANSI_RESET}"
    exit 113
fi
echo "${ANSI_PURPLE}Project name ........: ${ANSI_MAGENTA}$PROJECT_NAME${ANSI_RESET}"

GIT_VERSION=$( git tag --points-at HEAD | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sed -n 1p | sed 's/^v//g' | xargs )
GIT_INDEX=$( git rev-list --count HEAD )
GIT_HASH=$( git log -n 1 --format=%h )

if [ "$GIT_VERSION" != "" ]; then
    if [ "$HAS_CHANGES" -eq 0 ]; then
        GIT_VERSION_TEXT="$GIT_VERSION"
    else
        GIT_VERSION_TEXT="$GIT_VERSION+$GIT_HASH"
    fi
else
    GIT_VERSION_TEXT="0.0.0+$GIT_HASH"
fi

if [ "$GIT_VERSION" != "" ]; then
    echo "${ANSI_PURPLE}Git tag version .....: ${ANSI_MAGENTA}$GIT_VERSION${ANSI_RESET}"
else
    echo "${ANSI_PURPLE}Git tag version .....: ${ANSI_MAGENTA}-${ANSI_RESET}"
fi
echo "${ANSI_PURPLE}Git tag version text : ${ANSI_MAGENTA}$GIT_VERSION_TEXT${ANSI_RESET}"
echo "${ANSI_PURPLE}Git revision ........: ${ANSI_MAGENTA}$GIT_HASH${ANSI_PURPLE} (${ANSI_MAGENTA}$GIT_INDEX${ANSI_PURPLE})${ANSI_RESET}"

PROJECT_ENTRYPOINT=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PROJECT_ENTRYPOINT:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PROJECT_ENTRYPOINT" = "" ]; then  # auto-detect
    PROJECT_ENTRYPOINT=$( find "$SCRIPT_DIR/src" -type f -name "*.csproj" -print | sed -n 1p )
    PROJECT_ENTRYPOINT=$( echo "$PROJECT_ENTRYPOINT" | sed "s|$SCRIPT_DIR/||g" )
fi
if [ "$PROJECT_ENTRYPOINT" != "" ] && [ -e "$SCRIPT_DIR/$PROJECT_ENTRYPOINT" ]; then
    echo "${ANSI_PURPLE}Project entry point .: ${ANSI_MAGENTA}$PROJECT_ENTRYPOINT${ANSI_RESET}"
else
    echo "${ANSI_PURPLE}Project entry point .: ${ANSI_RED}not found${ANSI_RESET}" >&2
    exit 113
fi

PROJECT_OUTPUTTYPE=$( cat "$SCRIPT_DIR/$PROJECT_ENTRYPOINT" | grep -E "<OutputType>" | sed -n 1p | sed -E "s|.*<OutputType>(.*)</OutputType>.*|\1|g" | xargs | tr '[:upper:]' '[:lower:]' )
if [ "$PROJECT_OUTPUTTYPE" != "" ]; then
    echo "${ANSI_PURPLE}Project output type .: ${ANSI_MAGENTA}$PROJECT_OUTPUTTYPE${ANSI_RESET}"
else
    echo "${ANSI_PURPLE}Project output type .: ${ANSI_RED}cannot determine${ANSI_RESET}" >&2
    exit 113
fi

PROJECT_RUNTIMES=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PROJECT_RUNTIMES:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PROJECT_RUNTIMES" = "" ]; then
    PROJECT_RUNTIMES=current
fi
echo "${ANSI_PURPLE}Project runtimes ....: ${ANSI_MAGENTA}$PROJECT_RUNTIMES${ANSI_RESET}"


DOCKER_FILE="$(find "$SCRIPT_DIR/src" -type f -name "Dockerfile" -print | sed -n 1p)"

PACKAGE_LINUX_DOCKER=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PACKAGE_LINUX_DOCKER:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PACKAGE_LINUX_DOCKER" = "" ] && [ "$DOCKER_FILE" != "" ]; then
    PACKAGE_LINUX_DOCKER=$PROJECT_NAME
fi
if [ "$PACKAGE_LINUX_DOCKER" != "" ]; then
    if [ "$DOCKER_FILE" != "" ]; then
        echo "${ANSI_PURPLE}Docker source .......: ${ANSI_MAGENTA}$DOCKER_FILE${ANSI_RESET}"
    else
        echo "${ANSI_PURPLE}Docker source .......: ${ANSI_RED}not found${ANSI_RESET}" >&2
        exit 113
    fi
    echo "${ANSI_PURPLE}Docker local image ..: ${ANSI_MAGENTA}$PACKAGE_LINUX_DOCKER${ANSI_RESET}"

    PUBLISH_LINUX_DOCKER=$( cat "$SCRIPT_DIR/.meta.private" 2>/dev/null | grep -E "^PUBLISH_LINUX_DOCKER:" | sed  -n 1p | cut -d: -sf2- | xargs )
    if [ "$PUBLISH_LINUX_DOCKER" != "" ]; then
        if [ "$PACKAGE_LINUX_DOCKER" = "" ]; then
            echo "${ANSI_PURPLE}Docker remote image .: ${ANSI_RED}not found${ANSI_RESET}" >&2
            exit 113
        fi

        DOCKER_IMAGE_ID=$( echo "$PUBLISH_LINUX_DOCKER" | cut -d/ -f1 )
        DOCKER_IMAGE_NAME=$( echo "$PUBLISH_LINUX_DOCKER" | cut -d/ -sf2 )
        if [ "$DOCKER_IMAGE_ID" != "" ] && [ "$DOCKER_IMAGE_NAME" = "" ]; then
            DOCKER_IMAGE_NAME="$PACKAGE_LINUX_DOCKER"
        fi
        if [ "$DOCKER_IMAGE_ID" != "" ] && [ "$DOCKER_IMAGE_NAME" != "" ]; then
            echo "${ANSI_PURPLE}Docker remote image .: ${ANSI_MAGENTA}$DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME${ANSI_RESET}"
        else
            echo "${ANSI_PURPLE}Docker remote image .: ${ANSI_RED}not found${ANSI_RESET}" >&2
            exit 113
        fi
    fi
fi


PACKAGE_LINUX_APPIMAGE=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PACKAGE_LINUX_APPIMAGE:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PACKAGE_LINUX_APPIMAGE" = "" ]; then  # auto-detect
    if [ -d "$SCRIPT_DIR/packaging/linux-appimage" ] && [ -d "$SCRIPT_DIR/packaging/linux-deb" ]; then
        PACKAGE_LINUX_APPIMAGE=$(basename "$SCRIPT_DIR/packaging/linux-deb/usr/share/applications"/*.desktop .desktop)
    fi
fi
if [ "$PACKAGE_LINUX_APPIMAGE" != "" ]; then
    echo "${ANSI_PURPLE}AppImage ............: ${ANSI_MAGENTA}$PACKAGE_LINUX_APPIMAGE${ANSI_RESET}"

    PUBLISH_LINUX_APPIMAGE=$( cat "$SCRIPT_DIR/.meta.private" 2>/dev/null | grep -E "^PUBLISH_LINUX_APPIMAGE:" | sed  -n 1p | cut -d: -sf2- | xargs )
    if [ "$PUBLISH_LINUX_APPIMAGE" = "" ]; then
        echo "${ANSI_PURPLE}AppImage remote .....: ${ANSI_MAGENTA}(not configured)${ANSI_RESET}" >&2
    else
        echo "${ANSI_PURPLE}AppImage remote .....: ${ANSI_MAGENTA}$PUBLISH_LINUX_APPIMAGE${ANSI_RESET}"
    fi
fi


PACKAGE_LINUX_DEB=$( cat "$SCRIPT_DIR/.meta" | grep -E "^PACKAGE_LINUX_DEB:" | sed  -n 1p | cut -d: -sf2- | xargs )
if [ "$PACKAGE_LINUX_DEB" = "" ]; then  # auto-detect
    if [ -d "$SCRIPT_DIR/packaging/linux-deb" ]; then
        PACKAGE_LINUX_DEB=$PROJECT_NAME
    fi
fi
if [ "$PACKAGE_LINUX_DEB" != "" ]; then
    echo "${ANSI_PURPLE}Debian package ......: ${ANSI_MAGENTA}$PACKAGE_LINUX_DEB${ANSI_RESET}"

    PUBLISH_LINUX_DEB=$( cat "$SCRIPT_DIR/.meta.private" 2>/dev/null | grep -E "^PUBLISH_LINUX_DEB:" | sed  -n 1p | cut -d: -sf2- | xargs )
    if [ "$PUBLISH_LINUX_DEB" = "" ]; then
        echo "${ANSI_PURPLE}Debian package remote: ${ANSI_MAGENTA}(not configured)${ANSI_RESET}" >&2
    else
        echo "${ANSI_PURPLE}Debian package remote: ${ANSI_MAGENTA}$PUBLISH_LINUX_APPIMAGE${ANSI_RESET}"
    fi
fi


prereq_compile() {
    if ! command -v dotnet >/dev/null; then
        echo "${ANSI_RED}Missing dotnet command${ANSI_RESET}" >&2
        exit 113
    fi
}

prereq_package() {
    if [ "$PACKAGE_LINUX_DOCKER" != "" ]; then
        if ! command -v docker >/dev/null; then
            echo "${ANSI_RED}Missing docker command${ANSI_RESET}" >&2
            exit 113
        fi
    fi

    if [ "$PACKAGE_LINUX_APPIMAGE" != "" ]; then
        if ! [ -d "$SCRIPT_DIR/packaging/linux-appimage" ]; then
            echo "${ANSI_RED}Missing linux-appimage directory${ANSI_RESET}" >&2
            exit 113
        fi
        if ! [ -d "$SCRIPT_DIR/packaging/linux-deb" ]; then
            echo "${ANSI_RED}Missing linux-deb directory${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v appimagetool-x86_64.AppImage >/dev/null; then
            echo "${ANSI_RED}Missing appimagetool-x86_64.AppImage${ANSI_RESET}" >&2
            exit 113
        fi
    fi

    if [ "$PACKAGE_LINUX_DEB" != "" ]; then
        if ! [ -d "$SCRIPT_DIR/packaging/linux-deb" ]; then
            echo "${ANSI_RED}Missing linux-deb directory${ANSI_RESET}" >&2
            exit 113
        fi
        if ! [ -e "$SCRIPT_DIR/packaging/linux-deb/usr/share/applications"/*.desktop ]; then
            echo "${ANSI_RED}Missing desktip file${ANSI_RESET}" >&2
            exit 113
        fi
        if ! [ -e "$SCRIPT_DIR/packaging/linux-deb/usr/share/icons/hicolor/128x128/apps"/*.png ]; then
            echo "${ANSI_RED}Missing icon files${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v dpkg-deb >/dev/null; then
            echo "${ANSI_RED}Missing dpkg-deb command (dpkg-deb package)${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v fakeroot >/dev/null; then
            echo "${ANSI_RED}Missing fakeroot command${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v gzip >/dev/null; then
            echo "${ANSI_RED}Missing gzip command${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v lintian >/dev/null; then
            echo "${ANSI_RED}Missing lintian command (lintian package)${ANSI_RESET}" >&2
            exit 113
        fi
        if ! command -v strip >/dev/null; then
            echo "${ANSI_RED}Missing strip command${ANSI_RESET}" >&2
            exit 113
        fi
    fi
}

make_clean() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ CLEAN ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━┛${ANSI_RESET}"
    echo

    find "$SCRIPT_DIR/bin" -mindepth 1 -delete 2>/dev/null || true
    find "$SCRIPT_DIR/build" -mindepth 1 -delete 2>/dev/null || true
    rmdir "$SCRIPT_DIR/bin" 2>/dev/null || true
    rmdir "$SCRIPT_DIR/build" 2>/dev/null || true

    find "$SCRIPT_DIR/src" -type d \( -name "bin" -or -name "obj" \) -exec rm -rf "{}" + 2>/dev/null || true
    find "$SCRIPT_DIR/tests" -type d \( -name "bin" -or -name "obj" \) -exec rm -rf "{}" + 2>/dev/null || true
    find "$SCRIPT_DIR/tests" -type d -name "BenchmarkDotNet.Artifacts" -exec rm -rf "{}" + 2>/dev/null || true
    find "$SCRIPT_DIR/examples" -type d \( -name "bin" -or -name "obj" \) -exec rm -rf "{}" + 2>/dev/null || true
}

make_run() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ RUN ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━┛${ANSI_RESET}"
    echo

    echo "${ANSI_MAGENTA}$(basename $PROJECT_ENTRYPOINT)${ANSI_RESET}"
    if [ "$PROJECT_OUTPUTTYPE" = "exe" ] || [ "$PROJECT_OUTPUTTYPE" = "winexe" ]; then
        dotnet run --project "$SCRIPT_DIR/$PROJECT_ENTRYPOINT"
    else
        echo "${ANSI_RED}Nothing to run${ANSI_RESET}" >&2
        exit 113
    fi
}

make_test() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ TEST ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━┛${ANSI_RESET}"
    echo

    ANYTHING_DONE=0

    for PROJECT_FILE in $(find "$SCRIPT_DIR/tests" -name "*.csproj"); do
        IS_TEST=$(cat "$PROJECT_FILE" | grep -E "MSTest.Sdk" | wc -l)
        if [ $IS_TEST -eq 0 ]; then continue; fi

        ANYTHING_DONE=1
        echo "${ANSI_MAGENTA}$(basename $PROJECT_FILE)${ANSI_RESET}"

        dotnet test -p:TestingPlatformCaptureOutput=false \
                    -l "console;verbosity=detailed"       \
                    --verbosity detailed                  \
                    "$PROJECT_FILE"                       || exit 113
        echo
    done

    if [ "$ANYTHING_DONE" -eq 0 ]; then
        echo "${ANSI_RED}No test project found${ANSI_RESET}" >&2
        exit 113
    fi
}

make_benchmark() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ BENCHMARK ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━━━━━┛${ANSI_RESET}"
    echo

    ANYTHING_DONE=0

    for PROJECT_FILE in $(find "$SCRIPT_DIR/tests" -name "*.csproj"); do
        IS_BENCHMARK=$(cat "$PROJECT_FILE" | grep -E "BenchmarkDotNet" | wc -l)
        if [ $IS_BENCHMARK -eq 0 ]; then continue; fi

        ANYTHING_DONE=1
        echo "${ANSI_MAGENTA}$(basename $PROJECT_FILE)${ANSI_RESET}"

        cd "$( dirname "$PROJECT_FILE" )"
        dotnet run --configuration "Release" --project "$PROJECT_FILE" || exit 113
        cd "$SCRIPT_DIR"
        echo
    done

    if [ "$ANYTHING_DONE" -eq 0 ]; then
        echo "${ANSI_RED}No benchmark project found${ANSI_RESET}" >&2
        exit 113
    fi
}

make_examples() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ EXAMPLES ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━━━━┛${ANSI_RESET}"
    echo

    ANYTHING_DONE=0

    for PROJECT_FILE in $(find "$SCRIPT_DIR/examples" -name "*.csproj"); do
        ANYTHING_DONE=1

        echo "${ANSI_MAGENTA}$(basename $PROJECT_FILE) ($(basename $(dirname $PROJECT_FILE)))${ANSI_RESET}"

        mkdir -p "$SCRIPT_DIR/bin/examples/$EXAMPLE_PROJECT_DIR"
        dotnet build "$PROJECT_FILE" --configuration Release --output "$SCRIPT_DIR/bin/examples/$EXAMPLE_PROJECT_DIR"
        echo
    done

    if [ "$ANYTHING_DONE" -eq 0 ]; then
        echo "${ANSI_RED}No example project found${ANSI_RESET}" >&2
        exit 113
    fi
}

make_debug() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ DEBUG ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━┛${ANSI_RESET}"
    echo

    echo "${ANSI_MAGENTA}$(basename $PROJECT_ENTRYPOINT)${ANSI_RESET}"

    mkdir -p "$SCRIPT_DIR/bin"
    dotnet build "$SCRIPT_DIR/$PROJECT_ENTRYPOINT" --configuration Debug --output "$SCRIPT_DIR/bin"
}

make_release() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ RELEASE ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━━━┛${ANSI_RESET}"
    echo

    if [ "$GIT_VERSION" != "" ]; then
        ASSEMBLY_VERSION="$GIT_VERSION.$GIT_INDEX"
    else
        ASSEMBLY_VERSION="0.0.0.$GIT_INDEX"
    fi

    mkdir -p "$SCRIPT_DIR/bin"
    for RUNTIME in $PROJECT_RUNTIMES; do
        echo "${ANSI_MAGENTA}$(basename $PROJECT_ENTRYPOINT) ($RUNTIME)${ANSI_RESET}"

        PUBLISH_EXTRA_ARGS=
        if [ "$PROJECT_OUTPUTTYPE" = "exe" ] || [ "$PROJECT_OUTPUTTYPE" = "winexe" ]; then
            PUBLISH_EXTRA_ARGS="$PUBLISH_EXTRA_ARGS --self-contained true -p:PublishSingleFile=true -p:PublishReadyToRun=true"
        elif [ "$PROJECT_OUTPUTTYPE" = "library" ]; then  # libraries cannot be published as a single file
            PUBLISH_EXTRA_ARGS="$PUBLISH_EXTRA_ARGS --self-contained false -p:PublishSingleFile=false -p:GenerateDocumentationFile=true"
        else
            echo "${ANSI_RED}Cannot compile project type'$PROJECT_OUTPUTTYPE'${ANSI_RESET}" >&2
            exit 113
        fi
        if [ "$RUNTIME" = "current" ]; then
            PUBLISH_EXTRA_ARGS="$PUBLISH_EXTRA_ARGS --use-current-runtime"
            PUBLISH_OUTPUT_DIR="$SCRIPT_DIR/bin"
        else
            PUBLISH_EXTRA_ARGS="$PUBLISH_EXTRA_ARGS --runtime $RUNTIME"
            PUBLISH_OUTPUT_DIR="$SCRIPT_DIR/bin/$RUNTIME"
        fi

        dotnet publish "$SCRIPT_DIR/$PROJECT_ENTRYPOINT"                          \
            --configuration Release                                               \
            -p:AssemblyVersion=$ASSEMBLY_VERSION -p:FileVersion=$ASSEMBLY_VERSION \
            -p:Version=$ASSEMBLY_VERSION+$GIT_HASH                                \
            $PUBLISH_EXTRA_ARGS --output "$PUBLISH_OUTPUT_DIR"                    \
        && echo "${ANSI_CYAN}$SCRIPT_DIR/bin${ANSI_RESET}"
        echo
    done
}

make_package() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ PACKAGE ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━━━┛${ANSI_RESET}"
    echo

    ANYTHING_DONE=0

    if [ "$PACKAGE_LINUX_DOCKER" != "" ]; then
        ANYTHING_DONE=1
        echo "${ANSI_MAGENTA}docker${ANSI_RESET}"

        if [ "$GIT_VERSION" != "" ]; then
            docker build \
                -t $PACKAGE_LINUX_DOCKER:$GIT_VERSION \
                -t $PACKAGE_LINUX_DOCKER:latest \
                -t $PACKAGE_LINUX_DOCKER:unstable \
                -f "$DOCKER_FILE" .  || exit 113
            echo "${ANSI_CYAN}$PACKAGE_LINUX_DOCKER:$GIT_VERSION $PACKAGE_LINUX_DOCKER:latest $PACKAGE_LINUX_DOCKER:unstable${ANSI_RESET}"

            mkdir -p "$SCRIPT_DIR/dist"
            docker save \
                $PACKAGE_LINUX_DOCKER:$GIT_VERSION \
                | gzip > ./dist/$PACKAGE_LINUX_DOCKER.$GIT_VERSION.tgz || exit 113
            echo "${ANSI_CYAN}dist/$PACKAGE_LINUX_DOCKER-$GIT_VERSION.tgz${ANSI_RESET}"
        else
            docker build \
                -t $PACKAGE_LINUX_DOCKER:unstable \
                -f "$DOCKER_FILE" . || exit 113
            echo "${ANSI_CYAN}$PACKAGE_LINUX_DOCKER:unstable${ANSI_RESET}"
        fi
        echo
    fi

    if [ "$PACKAGE_LINUX_APPIMAGE" != "" ]; then
        for RUNTIME in $PROJECT_RUNTIMES; do
            case $RUNTIME in
                linux-x64)   APPIMAGE_ARCHITECTURE=x86_64 ;;
                linux-arm64) APPIMAGE_ARCHITECTURE=aarch64 ;;
                *)           continue ;;
            esac

            ANYTHING_DONE=1
            echo "${ANSI_MAGENTA}appimage ($RUNTIME: $APPIMAGE_ARCHITECTURE)${ANSI_RESET}"

            APPIMAGE_NAME_CURR="$PROJECT_NAME-$GIT_VERSION_TEXT-$APPIMAGE_ARCHITECTURE.AppImage"

            mkdir -p "$SCRIPT_DIR/build/AppImage-$RUNTIME"
            find "$SCRIPT_DIR/build/AppImage-$RUNTIME" -mindepth 1 -delete

            cp "$SCRIPT_DIR/packaging/linux-appimage/AppRun" "$SCRIPT_DIR/build/AppImage-$RUNTIME/" || exit 113

            mkdir -p "$SCRIPT_DIR/build/AppImage-$RUNTIME/opt/$PROJECT_NAME"
            rsync -a "$SCRIPT_DIR/bin/linux-x64/" "$SCRIPT_DIR/build/AppImage-$RUNTIME/opt/$PROJECT_NAME/" || exit 113

            rsync -a "$SCRIPT_DIR/packaging/linux-deb/usr/" "$SCRIPT_DIR/build/AppImage-$RUNTIME/usr/" || exit 113

            cp "$SCRIPT_DIR/packaging/linux-deb/usr/share/applications"/*.desktop "$SCRIPT_DIR/build/AppImage-$RUNTIME/" || exit 113
            cp "$SCRIPT_DIR/packaging/linux-deb/usr/share/icons/hicolor/128x128/apps"/*.png "$SCRIPT_DIR/build/AppImage-$RUNTIME/" || exit 113
            cp "$SCRIPT_DIR/packaging/linux-deb/usr/share/icons/hicolor/128x128/apps"/*.png "$SCRIPT_DIR/build/AppImage-$RUNTIME/.DirIcon" || exit 113

            if [ -e "$SCRIPT_DIR/packaging/linux-deb/etc/" ]; then
                rsync -a "$SCRIPT_DIR/packaging/linux-deb/etc/" "$SCRIPT_DIR/build/AppImage-$RUNTIME/etc/" || exit 113
            fi

            mkdir -p "dist"
            rm "dist/$APPIMAGE_NAME_CURR" 2>/dev/null
            ARCH=$APPIMAGE_ARCHITECTURE appimagetool-x86_64.AppImage "$SCRIPT_DIR/build/AppImage-$RUNTIME/" "dist/$APPIMAGE_NAME_CURR" || exit 113

            case $RUNTIME in
                linux-x64)   APPIMAGE_NAME_AMD64=$APPIMAGE_NAME_CURR ;;
                linux-arm64) APPIMAGE_NAME_ARM64=$APPIMAGE_NAME_CURR ;;
                *)           continue ;;
            esac

            echo "${ANSI_CYAN}dist/$APPIMAGE_NAME_CURR${ANSI_RESET}"
            echo
        done
    fi

    if [ "$PACKAGE_LINUX_DEB" != "" ]; then
        for RUNTIME in $PROJECT_RUNTIMES; do
            case $RUNTIME in
                linux-x64)   DEB_ARCHITECTURE=amd64 ;;
                linux-arm64) DEB_ARCHITECTURE=arm64 ;;
                *)           continue ;;
            esac

            ANYTHING_DONE=1
            echo "${ANSI_MAGENTA}deb ($RUNTIME: $DEB_ARCHITECTURE)${ANSI_RESET}"

            if [ "$GIT_VERSION" != "" ]; then
                DEB_VERSION=$GIT_VERSION
                DEB_PACKAGE_NAME="${PROJECT_NAME}_${GIT_VERSION_TEXT}_${DEB_ARCHITECTURE}"
            else
                DEB_VERSION=0.0.0
                DEB_PACKAGE_NAME="${PROJECT_NAME}_${GIT_VERSION_TEXT}_${DEB_ARCHITECTURE}"
            fi

            mkdir -p "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME"
            find "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/" -mindepth 1 -delete

            rsync -a "$SCRIPT_DIR/packaging/linux-deb/DEBIAN/" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN/" || exit 113
            sed -i "s/<DEB_VERSION>/$DEB_VERSION/" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN/control" || exit 113
            sed -i "s/<DEB_ARCHITECTURE>/amd64/" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN/control" || exit 113

            rsync -a "$SCRIPT_DIR/packaging/linux-deb/usr/" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/usr/" || exit 113

            mkdir -p  "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/opt/$PROJECT_NAME/"
            rsync -a "$SCRIPT_DIR/bin/linux-x64/" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/opt/$PROJECT_NAME/" || exit 113

            if [ -e "$SCRIPT_DIR/packaging/linux-deb/copyright" ]; then
                mkdir -p "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/usr/share/doc/$PROJECT_NAME/"
                cp "$SCRIPT_DIR/packaging/linux-deb/copyright" "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/usr/share/doc/$PROJECT_NAME/copyright" || exit 113
            fi

            find "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/" -type d -exec chmod 755 {} + || exit 113
            find "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/" -type f -exec chmod 644 {} + || exit 113
            find "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/opt/" -type f -name "$PROJECT_NAME" -exec chmod 755 {} + || exit 113
            chmod 755 "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN"/config || exit 113
            chmod 755 "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN"/p*inst || exit 113
            chmod 755 "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/DEBIAN"/p*rm || exit 113

            fakeroot dpkg-deb -Z gzip --build "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME/" > /dev/null || exit 113
            mv "$SCRIPT_DIR/build/$DEB_PACKAGE_NAME.deb" "dist/$DEB_PACKAGE_NAME.deb" || exit 113
            lintian --suppress-tags dir-or-file-in-opt,embedded-library "dist/$DEB_PACKAGE_NAME.deb"

            case $RUNTIME in
                linux-x64)   DEB_PACKAGE_AMD64=$DEB_PACKAGE_NAME.deb ;;
                linux-arm64) DEB_PACKAGE_ARM64=$DEB_PACKAGE_NAME.deb ;;
                *)           continue ;;
            esac

            echo "${ANSI_CYAN}dist/$DEB_PACKAGE_NAME.deb${ANSI_RESET}"
            echo
        done
    fi

    if [ "$ANYTHING_DONE" -eq 0 ]; then
        echo "${ANSI_RED}Nothing to package${ANSI_RESET}" >&2
        exit 113
    fi
}

make_publish() {
    echo
    echo "${ANSI_MAGENTA}┏━━━━━━━━━┓${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┃ PUBLISH ┃${ANSI_RESET}"
    echo "${ANSI_MAGENTA}┗━━━━━━━━━┛${ANSI_RESET}"
    echo

    ANYTHING_DONE=0

    if [ "$PUBLISH_LINUX_DOCKER" != "" ]; then
        ANYTHING_DONE=1
        echo "${ANSI_MAGENTA}docker${ANSI_RESET}"

        if [ "$GIT_VERSION" != "" ]; then
            docker tag \
                $PACKAGE_LINUX_DOCKER:$GIT_VERSION \
                $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:$GIT_VERSION || exit 113
            docker push \
                $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:$GIT_VERSION || exit 113
            echo "${ANSI_CYAN}$DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:$GIT_VERSION${ANSI_RESET}"
            echo

            docker tag \
                $PACKAGE_LINUX_DOCKER:latest \
                $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:latest || exit 113
            docker push \
                $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:latest || exit 113
            echo "${ANSI_CYAN}$DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:latest${ANSI_RESET}"
            echo
        fi

        docker tag \
            $PACKAGE_LINUX_DOCKER:unstable \
            $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:unstable || exit 113
        docker push \
            $DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:unstable || exit 113
            echo "${ANSI_CYAN}$DOCKER_IMAGE_ID/$DOCKER_IMAGE_NAME:unstable${ANSI_RESET}"
        echo
    fi

    if [ "$PUBLISH_LINUX_APPIMAGE" != "" ]; then
        for RUNTIME in $PROJECT_RUNTIMES; do
            case $RUNTIME in
                linux-x64)   APPIMAGE_NAME_CURR=$APPIMAGE_NAME_AMD64 ;;
                linux-arm64) APPIMAGE_NAME_CURR=$APPIMAGE_NAME_ARM64 ;;
                *)           continue ;;
            esac

            ANYTHING_DONE=1
            echo "${ANSI_MAGENTA}appimage ($RUNTIME)${ANSI_RESET}"

            rsync --no-g --no-o --progress --chmod=D755,F644  "dist/$APPIMAGE_NAME_CURR" $PUBLISH_LINUX_APPIMAGE || exit 113
            echo "${ANSI_CYAN}$PUBLISH_LINUX_APPIMAGE${ANSI_RESET}"
            echo
        done
    fi

    if [ "$PUBLISH_LINUX_DEB" != "" ]; then
        for RUNTIME in $PROJECT_RUNTIMES; do
            case $RUNTIME in
                linux-x64)   DEB_ARCHITECTURE=amd64 ; DEB_PACKAGE_CURR=$DEB_PACKAGE_AMD64 ;;
                linux-arm64) DEB_ARCHITECTURE=arm64 ; DEB_PACKAGE_CURR=$DEB_PACKAGE_ARM64 ;;
                *)           continue ;;
            esac

            ANYTHING_DONE=1
            echo "${ANSI_MAGENTA}deb ($RUNTIME: $DEB_ARCHITECTURE)${ANSI_RESET}"

            PUBLISH_LINUX_DEB_CURR="$( echo "$PUBLISH_LINUX_DEB" | sed "s/<DEB_ARCHITECTURE>/$DEB_ARCHITECTURE/g" )"

            rsync --no-g --no-o --progress "dist/$DEB_PACKAGE_CURR" $PUBLISH_LINUX_DEB_CURR || exit 113
            echo "${ANSI_CYAN}$PUBLISH_LINUX_DEB_CURR${ANSI_RESET}"
            echo
        done
    fi

    if [ "$ANYTHING_DONE" -eq 0 ]; then
        echo "${ANSI_RED}Nothing to publish${ANSI_RESET}" >&2
        exit 113
    fi
}


if [ "$1" = "" ]; then ACTIONS="all"; else ACTIONS="$@"; fi

TOKENS=" "
NEGTOKENS=
PREREQ_COMPILE=0
PREREQ_PACKAGE=0
for ACTION in $ACTIONS; do
    case $ACTION in
        all)        TOKENS="$TOKENS clean release"                      ; PREREQ_COMPILE=1                    ;;
        clean)      TOKENS="$TOKENS clean"                                                                    ;;
        run)        TOKENS="$TOKENS run"                                ; PREREQ_COMPILE=1                    ;;
        test)       TOKENS="$TOKENS clean test"                         ; PREREQ_COMPILE=1                    ;;
        benchmark)  TOKENS="$TOKENS clean benchmark"                    ; PREREQ_COMPILE=1                    ;;
        examples)   TOKENS="$TOKENS clean examples"                     ; PREREQ_COMPILE=1                    ;;
        debug)      TOKENS="$TOKENS clean debug"                        ; PREREQ_COMPILE=1                    ;;
        release)    TOKENS="$TOKENS clean test release"                 ; PREREQ_COMPILE=1                    ;;
        package)    TOKENS="$TOKENS clean test release package"         ; PREREQ_COMPILE=1 ; PREREQ_PACKAGE=1 ;;
        publish)    TOKENS="$TOKENS clean test release package publish" ; PREREQ_COMPILE=1 ; PREREQ_PACKAGE=1 ;;
        ~clean)     NEGTOKENS="$NEGTOKENS clean"     ;;
        ~run)       NEGTOKENS="$NEGTOKENS run"       ;;
        ~test)      NEGTOKENS="$NEGTOKENS test"      ;;
        ~benchmark) NEGTOKENS="$NEGTOKENS benchmark" ;;
        ~examples)  NEGTOKENS="$NEGTOKENS examples"  ;;
        ~debug)     NEGTOKENS="$NEGTOKENS debug"     ;;
        ~release)   NEGTOKENS="$NEGTOKENS release"   ;;
        ~package)   NEGTOKENS="$NEGTOKENS package"   ;;
        ~publish)   NEGTOKENS="$NEGTOKENS publish"   ;;
        *)         echo "Unknown action $ACTION" >&2 ; exit 113 ;;
    esac
done

if [ $PREREQ_COMPILE -ne 0 ]; then prereq_compile; fi
if [ $PREREQ_PACKAGE -ne 0 ]; then prereq_package; fi

NEGTOKENS=$( echo $NEGTOKENS | xargs | tr ' ' '\n' | awk '!seen[$0]++' | xargs )  # remove duplicates
TOKENS=$( echo $TOKENS | xargs | tr ' ' '\n' | awk '!seen[$0]++' | xargs )  # remove duplicates

for NEGTOKEN in $NEGTOKENS; do  # remove tokens we specifically asked not to have
    TOKENS=$( echo $TOKENS | tr ' ' '\n' | grep -v $NEGTOKEN | xargs )
done

if [ "$TOKENS" != "" ]; then
    echo "${ANSI_PURPLE}Make targets ........: ${ANSI_MAGENTA}$TOKENS${ANSI_RESET}"
else
    echo "${ANSI_PURPLE}Make targets ........: ${ANSI_RED}not found${ANSI_RESET}"
    exit 113
fi
echo

for TOKEN in $TOKENS; do
    case $TOKEN in
        clean)     make_clean     || exit 113 ;;
        run)       make_run       || exit 113 ;;
        test)      make_test      || exit 113 ;;
        benchmark) make_benchmark || exit 113 ;;
        examples)  make_examples  || exit 113 ;;
        debug)     make_debug     || exit 113 ;;
        release)   make_release   || exit 113 ;;
        package)   make_package   || exit 113 ;;
        publish)   make_publish   || exit 113 ;;
        *)         echo "Unknown token $TOKEN" >&2 ; exit 113 ;;
    esac
done

exit 0
