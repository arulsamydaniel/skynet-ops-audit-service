# Use a lightweight Node.js base image
FROM node:18-alpine

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production

# Copy the rest of your application code
COPY . .

# Expose the port the app runs on (defaults to 3000)
EXPOSE 3000

# Command to run the application
CMD ["node", "index.js"]