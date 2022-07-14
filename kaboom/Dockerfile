FROM eclipse-temurin:17-jdk-alpine as scissors-builder
RUN apk --no-cache add git
WORKDIR /build/
# Spigot requires you to specify your identity in git
RUN git config --global user.email "you@example.com"
RUN git config --global user.name "Your Name"
RUN git clone https://github.com/AtlasMediaGroup/Scissors.git -b "1.19" --depth=1

WORKDIR /build/Scissors
RUN ./gradlew --no-daemon applyPatches --stacktrace --info
RUN ./gradlew --no-daemon createReobfPaperclipJar --stacktrace --info

FROM eclipse-temurin:17-jre-alpine as scissors-patcher
WORKDIR /patcher/

COPY --from=scissors-builder /build/Scissors/build/libs/*paperclip*.jar /patcher/paperclip.jar
RUN java -Dpaperclip.patchonly=true -jar paperclip.jar

FROM eclipse-temurin:17-jdk-alpine as essentials-builder
RUN apk --no-cache add git

WORKDIR /build/
RUN git clone https://github.com/EssentialsX/Essentials/ -b "2.x" --depth=1

WORKDIR /build/Essentials/
RUN ./gradlew --no-daemon EssentialsX:shadowJar

FROM eclipse-temurin:17-jdk-alpine as fawe-builder
RUN apk --no-cache add git

WORKDIR /build/
RUN git clone https://github.com/IntellectualSites/FastAsyncWorldEdit.git --depth=1

WORKDIR /build/FastAsyncWorldEdit
RUN ./gradlew --no-daemon build --stacktrace --info

# Via still build with Java 8, for backwards compatibility with older servers
FROM eclipse-temurin:8-jdk-alpine as viaversion-builder
RUN apk --no-cache add git

WORKDIR /build/
RUN git clone https://github.com/ViaVersion/ViaVersion.git -b "dev" --depth=1 

WORKDIR /build/ViaVersion
RUN ./gradlew --no-daemon viaversion-bukkit:build --stacktrace --info

FROM eclipse-temurin:17-jdk-alpine as viabackwards-builder
RUN apk --no-cache add git

WORKDIR /build/
RUN git clone https://github.com/ViaVersion/ViaBackwards.git -b "dev" --depth=1

WORKDIR /build/ViaBackwards
RUN ./gradlew --no-daemon viabackwards-bukkit:build --stacktrace --info

FROM alpine as viarewind-builder
RUN apk --no-cache add git maven

WORKDIR /build/
# For some reason ViaRewind doesn't use the development branch for development
# like the rest of the Via family and instead push to master
RUN git clone https://github.com/ViaVersion/ViaRewind.git --depth=1

WORKDIR /build/ViaRewind
RUN mvn package
RUN rm -rfv all/target/original*.jar

FROM alpine as kaboom-builder
RUN apk --no-cache add git maven

WORKDIR /build/
RUN git clone https://github.com/kaboomserver/extras.git --depth=1
RUN git clone https://github.com/kaboomserver/commandspy.git --depth=1
RUN git clone https://github.com/kaboomserver/icontrolu.git --depth=1
RUN git clone https://github.com/kaboomserver/weapons.git --depth=1
RUN git clone https://github.com/kaboomserver/particletrails.git --depth=1

WORKDIR /build/extras
RUN mvn -B package

WORKDIR /build/commandspy
RUN mvn -B package

WORKDIR /build/icontrolu
RUN mvn -B package

WORKDIR /build/weapons
RUN mvn -B package

WORKDIR /build/particletrails
RUN mvn -B package

# We want to copy our configuration files from the official kaboom repo
FROM alpine as kaboom-server-repo
RUN apk --no-cache add git

WORKDIR /build/
RUN git clone https://github.com/kaboomserver/server.git --depth=1

FROM alpine as server-builder

WORKDIR /server/

RUN addgroup -g 1000 nonroot
RUN adduser -S -H -D -u 1000 nonroot nonroot
RUN chown -R nonroot:nonroot /server/
RUN chmod -R 777 /server/

COPY --from=scissors-patcher /patcher/paperclip.jar /server/server.jar
COPY --from=scissors-patcher /patcher/libraries/ /server/libraries/
COPY --from=scissors-patcher /patcher/versions/ /server/versions/
COPY --from=scissors-patcher /patcher/cache/ /server/cache/

WORKDIR /server/plugins
# We want to copy the official configurations
COPY --chown=nonroot:nonroot --from=kaboom-server-repo /build/server/plugins/ /server/plugins/

# This is ran on the proxy to prevent IP leaks
RUN rm -rf Geyser.jar

COPY --from=viaversion-builder /build/ViaVersion/build/libs/*.jar ViaVersion.jar
COPY --from=viabackwards-builder /build/ViaBackwards/build/libs/*.jar ViaBackwards.jar
COPY --from=viarewind-builder /build/ViaRewind/all/target/*.jar ViaRewind.jar

COPY --from=essentials-builder /build/Essentials/Essentials/build/libs/*.jar Essentials.jar

COPY --from=fawe-builder /build/FastAsyncWorldEdit/worldedit-bukkit/build/libs/FastAsyncWorldEdit*.jar FastAsyncWorldEdit.jar

COPY --from=kaboom-builder /build/extras/target/Extras.jar Extras.jar
COPY --from=kaboom-builder /build/commandspy/target/CommandSpy.jar CommandSpy.jar
COPY --from=kaboom-builder /build/icontrolu/target/iControlU.jar iControlU.jar
COPY --from=kaboom-builder /build/weapons/target/Weapons.jar Weapons.jar
COPY --from=kaboom-builder /build/particletrails/target/ParticleTrails.jar ParticleTrails.jar

WORKDIR /server/
COPY --chown=nonroot:nonroot --from=kaboom-server-repo /build/server/*.yml /server/
COPY --chown=nonroot:nonroot --from=kaboom-server-repo /build/server/*.properties /server/
COPY --chown=nonroot:nonroot --from=kaboom-server-repo /build/server/server-icon.png /server/

FROM gcr.io/distroless/java17-debian11:nonroot
USER nonroot:nonroot

COPY --from=server-builder --chown=nonroot:nonroot /server/ /server/
WORKDIR /server/

ENTRYPOINT ["java", "-Xms5G", "-Xmx5G", "-XX:+UseG1GC", "-XX:+ParallelRefProcEnabled", "-XX:MaxGCPauseMillis=200", "-XX:+UnlockExperimentalVMOptions", "-XX:+DisableExplicitGC", "-XX:+AlwaysPreTouch", "-XX:G1NewSizePercent=30", "-XX:G1MaxNewSizePercent=40", "-XX:G1HeapRegionSize=8M", "-XX:G1ReservePercent=20", "-XX:G1HeapWastePercent=5", "-XX:G1MixedGCCountTarget=4", "-XX:InitiatingHeapOccupancyPercent=15", "-XX:G1MixedGCLiveThresholdPercent=90", "-XX:G1RSetUpdatingPauseTimePercent=5", "-XX:SurvivorRatio=32", "-XX:+PerfDisableSharedMem", "-XX:MaxTenuringThreshold=1", "-Dusing.aikars.flags=https://mcflags.emc.gs", "-Daikars.new.flags=true", "-Dcom.mojang.eula.agree=true", "-jar", "server.jar", "--nogui", "--noconsole"]