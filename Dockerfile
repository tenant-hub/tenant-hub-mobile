# ---- Build Stage ----
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

COPY . .

RUN dart run build_runner build --delete-conflicting-outputs
RUN flutter build web --release

# ---- Runtime Stage ----
FROM nginx:alpine AS runtime

COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 5174

CMD ["nginx", "-g", "daemon off;"]
