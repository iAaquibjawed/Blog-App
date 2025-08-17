# Use Ruby 3.1.3 to match your Gemfile
FROM ruby:3.1.3-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install gems (remove deployment mode to avoid platform issues)
RUN bundle lock --add-platform aarch64-linux && \
    bundle lock --add-platform x86_64-linux && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy package.json if you have one (for JavaScript dependencies)
COPY package*.json ./
RUN npm install

# Copy the rest of the application
COPY . .

# Skip asset precompilation during build - do it at runtime instead
# RUN SECRET_KEY_BASE=dummy_secret_for_precompile \
#     SKIP_PROMETHEUS=true \
#     RAILS_ENV=production \
#     bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Create a non-root user
RUN useradd -m -u 1001 rails
USER rails

# Start the Rails server (precompile assets first if needed)
CMD ["sh", "-c", "bundle exec rails assets:precompile && bundle exec rails server -b 0.0.0.0 -p 3000"]