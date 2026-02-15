FROM ruby:3.4-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libvulkan1 \
    mesa-vulkan-drivers \
    unzip \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile wgpu.gemspec ./
COPY lib/wgpu/version.rb lib/wgpu/version.rb

RUN bundle install

COPY . .

RUN bundle exec ruby ext/wgpu/extconf.rb

CMD ["bundle", "exec", "rake", "spec"]
