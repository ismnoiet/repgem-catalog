#!/usr/bin/env bash
# Publishes the library to your local Maven (~/.m2) so another project can try it with mavenLocal():
#   implementation("com.github.ismnoiet:dragable-cards-android:1.0.0")
set -euo pipefail
cd "$(dirname "$0")/.."
./gradlew :dragablecards:publishToMavenLocal
echo "Published to ~/.m2. Add mavenLocal() to your repositories."
