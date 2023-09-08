#!/usr/bin/env bash

CF_VERSION='3.38.0'
LOMBOK_VERSION='1.18.28'
SLF4J_VERSION='2.0.7'
ERRORPRONE_JAVAC_VERSION='9+181-r4173-1'

# prefer javac from $JAVA_HOME, if it is set
export PATH="$JAVA_HOME/bin:$PATH"

type javac

function dl-artifact {
  local group="$1"
  local artifact="$2"
  local version="$3"
  if [[ ! -e "$artifact-$version.jar" ]]; then
    local url="https://repo1.maven.org/maven2/$group/$artifact/$version/$artifact-$version.jar"
    echo "Downloading $url"
    curl -Lf "$url" -o tmp
    mv tmp "$artifact-$version.jar"
  fi
}

dl-artifact "org/checkerframework" "checker-qual" "$CF_VERSION"
dl-artifact "org/checkerframework" "checker" "$CF_VERSION"
dl-artifact "org/projectlombok" "lombok" "$LOMBOK_VERSION"
dl-artifact "org/slf4j" "slf4j-api" "$SLF4J_VERSION"
dl-artifact "com/google/errorprone" "javac" "$ERRORPRONE_JAVAC_VERSION"

CF_CP="checker-$CF_VERSION.jar:lombok-$LOMBOK_VERSION.jar"
export CLASSPATH="checker-qual-$CF_VERSION.jar:lombok-$LOMBOK_VERSION.jar:slf4j-api-$SLF4J_VERSION.jar"

PROCESSORS=(
  'org.checkerframework.checker.nullness.NullnessChecker'
  'org.checkerframework.checker.resourceleak.ResourceLeakChecker'
  'lombok.launch.AnnotationProcessorHider$AnnotationProcessor'
  'lombok.launch.AnnotationProcessorHider$ClaimingProcessor' # optional
)

COMMA_SEPARATED_PROCESSORS="$(IFS=, ; echo "${PROCESSORS[*]}")"

JAVAC_ARGV=(
### JAVA 8
#  -J-Xbootclasspath/p:"javac-$ERRORPRONE_JAVAC_VERSION.jar"

### JAVA 9+
  -J-ea
  -J--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED
  -J--add-exports=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED
  -J--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED

#  -J-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=5005
  -d /tmp
  -processorpath "$CLASSPATH:$CF_CP"
  -processor "$COMMA_SEPARATED_PROCESSORS"
)

echo "Compiling..."
set -ex
exec find src/main/java -iname '*.java' -exec javac "${JAVAC_ARGV[@]}" {} +
