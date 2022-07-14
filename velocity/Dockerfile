FROM eclipse-temurin:17-jdk-alpine as velocity-builder
RUN apk --no-cache add git 
WORKDIR /build/

RUN git clone https://github.com/PaperMC/Velocity.git --depth=1

WORKDIR /build/Velocity
RUN ./gradlew --no-daemon shadowJar --stacktrace --info

FROM alpine as geyser-builder
RUN apk --no-cache add git maven

WORKDIR /build/
RUN git clone https://github.com/GeyserMC/Geyser.git --depth=1

WORKDIR /build/Geyser
RUN git submodule update --init
RUN mvn -B package
RUN rm -rf bootstrap/velocity/target/original*

FROM alpine as proxy-builder

WORKDIR /server/

COPY --from=velocity-builder /build/Velocity/proxy/build/libs/*all.jar proxy.jar
ADD velocity.toml /server/velocity.toml
RUN echo "UNUSED" > forwarding-secret

WORKDIR /server/plugins

COPY --from=geyser-builder /build/Geyser/bootstrap/velocity/target/*.jar Geyser.jar

RUN addgroup -g 1000 nonroot
RUN adduser -S -H -D -u 1000 nonroot nonroot
RUN chown -R nonroot:nonroot /server/
RUN chmod -R 777 /server/

FROM gcr.io/distroless/java17-debian11:nonroot
USER nonroot:nonroot

COPY --chown=nonroot:nonroot --from=proxy-builder /server/ /server/

WORKDIR /server/
ENTRYPOINT [ "java", "-Xms1G", "-Xmx1G", "-XX:+UseG1GC", "-XX:G1HeapRegionSize=4M", "-XX:+UnlockExperimentalVMOptions", "-XX:+ParallelRefProcEnabled", "-XX:+AlwaysPreTouch", "-XX:MaxInlineLevel=15", "-jar", "proxy.jar" ]