# Use an official Node.js runtime as the base image
FROM node:14

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json  to the container
COPY package.json ./

# Install dependencies
RUN npm install

# Copy the appfiles to the container
COPY dist/ ./dist/
COPY server.js ./

# Specify the port on which the server is to be runtime
ENV PORT=80

# Expose the port on which the app will runtime
EXPOSE 80

# Set the command to run your app when the continer starts
CMD [ "node", "server.js" ]