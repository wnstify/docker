# Watchtower
<p align="left">
  <img src="https://github.com/containrrr/watchtower/blob/main/logo.png" alt="Watchtower Logo" width="300">
</p>
[Watchtower](https://github.com/containrrr/watchtower) is a Docker application designed to automate the process of updating your Docker containers with the latest images. Containers, once deployed, can become outdated as new images are released. Traditionally, you would need to manually stop the running container, pull the latest image, and then restart the container using the new image. Watchtower automates this process.

The way Watchtower works is simple: it periodically checks the Docker Hub registry (or other registries you've set up) for new images of the containers that you're running. If it finds a newer image, it will automatically pull this image, gracefully shut down the existing container, and then start a new container with the updated image, while preserving the options and volumes from the original container.

For more information and configuration options, visit the official GitHub repository: [Watchtower on GitHub](https://github.com/containrrr/watchtower).
