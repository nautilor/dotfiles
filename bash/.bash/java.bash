_detect_java_pm() {
  if   [[ -f gradlew ]];         then echo gradle-wrapper
  elif [[ -f pom.xml ]];         then echo maven
  elif [[ -f build.gradle ]];    then echo gradle
  elif [[ -f build.gradle.kts ]]; then echo gradle-kts
  else echo unknown
  fi
}

_detect_java_framework() {
  if [[ -f pom.xml ]]; then
    if grep -q "spring-boot" pom.xml 2>/dev/null;         then echo springboot
    elif grep -q "quarkus" pom.xml 2>/dev/null;           then echo quarkus
    elif grep -q "micronaut" pom.xml 2>/dev/null;         then echo micronaut
    else echo maven
    fi
  elif [[ -f build.gradle ]] || [[ -f build.gradle.kts ]]; then
    local gradle_file="build.gradle"
    [[ -f build.gradle.kts ]] && gradle_file="build.gradle.kts"
    if grep -q "spring-boot" "$gradle_file" 2>/dev/null;  then echo springboot
    elif grep -q "quarkus" "$gradle_file" 2>/dev/null;    then echo quarkus
    elif grep -q "micronaut" "$gradle_file" 2>/dev/null;  then echo micronaut
    else echo gradle
    fi
  else
    echo unknown
  fi
}

_gradle_cmd() {
  [[ -f gradlew ]] && echo "./gradlew" || echo "gradle"
}

function jd() {
  local framework=$(_detect_java_framework)
  local gradle=$(_gradle_cmd)

  case $framework in
    springboot) 
      if [[ -f pom.xml ]]; then mvn spring-boot:run
      else $gradle bootRun
      fi ;;
    quarkus)
      if [[ -f pom.xml ]]; then mvn quarkus:dev
      else $gradle quarkusDev
      fi ;;
    micronaut)
      if [[ -f pom.xml ]]; then mvn mn:run
      else $gradle run
      fi ;;
    maven)  mvn exec:java ;;
    gradle*) $gradle run ;;
    *)      echo "No recognizable Java project found" && return 1 ;;
  esac
}

function jb() {
  local framework=$(_detect_java_framework)
  local gradle=$(_gradle_cmd)

  case $framework in
    springboot)
      if [[ -f pom.xml ]]; then mvn package -DskipTests
      else $gradle bootJar
      fi ;;
    quarkus)
      if [[ -f pom.xml ]]; then mvn package
      else $gradle build
      fi ;;
    micronaut)
      if [[ -f pom.xml ]]; then mvn package
      else $gradle assemble
      fi ;;
    maven)  mvn package ;;
    gradle*) $gradle build ;;
    *)      echo "No recognizable Java project found" && return 1 ;;
  esac
}

function jt() {
  local framework=$(_detect_java_framework)
  local gradle=$(_gradle_cmd)

  case $framework in
    maven|springboot|quarkus|micronaut)
      [[ -f pom.xml ]] && mvn test || $gradle test ;;
    gradle*) $gradle test ;;
    *)      echo "No recognizable Java project found" && return 1 ;;
  esac
}
