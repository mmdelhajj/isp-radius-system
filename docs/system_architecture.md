# System Architecture and Technology Stack

## High-Level Architecture

The proposed system architecture is designed to be modular, scalable, and secure, following a microservices-oriented approach. This will allow for independent development, deployment, and scaling of different components of the system.

The core components of the architecture are:

*   **Web Frontend:** A modern, responsive web application for the Admin Control Panel (ACP), User Control Panel (UCP), and Reseller Portal.
*   **Backend API Gateway:** A single entry point for all frontend requests, which routes them to the appropriate microservices.
*   **Microservices:** A collection of independent services, each responsible for a specific business domain (e.g., user management, billing, RADIUS integration).
*   **RADIUS Server:** A dedicated FreeRADIUS server for handling authentication, authorization, and accounting.
*   **Database:** A relational database for storing all system data.
*   **Message Queue:** A message broker for asynchronous communication between microservices.
*   **Caching Layer:** A distributed cache to improve performance and reduce database load.




## Recommended Technology Stack

### Backend

*   **Programming Language:** Python 3.11
*   **Framework:** Flask
*   **API Gateway:** Nginx
*   **Microservices Communication:** REST APIs, gRPC
*   **Asynchronous Tasks:** Celery with RabbitMQ or Redis

### Frontend

*   **Framework:** React
*   **UI Library:** Material-UI or Ant Design
*   **State Management:** Redux or MobX

### Database

*   **Relational Database:** PostgreSQL or MySQL
*   **Caching:** Redis

### RADIUS Server

*   **Software:** FreeRADIUS

### Deployment

*   **Containerization:** Docker
*   **Orchestration:** Kubernetes
*   **CI/CD:** Jenkins, GitLab CI, or GitHub Actions

## Component Breakdown

### Web Frontend

The frontend will be a single-page application (SPA) built with React. It will provide a user-friendly interface for all user roles: administrators, resellers, and customers. The application will be designed to be fully responsive, ensuring a seamless experience on both desktop and mobile devices.

### Backend API Gateway

The API gateway will be the single entry point for all client requests. It will handle authentication, rate limiting, and request routing to the appropriate microservices. Nginx is a good choice for this component due to its high performance and reverse proxy capabilities.

### Microservices

Each microservice will be a self-contained application responsible for a specific business domain. This approach allows for independent development, deployment, and scaling of each service.

*   **User Service:** Manages user registration, authentication, and profile information.
*   **Billing Service:** Handles prepaid and postpaid billing, invoicing, and payment processing.
*   **RADIUS Service:** Integrates with the FreeRADIUS server to manage NAS devices, user profiles, and accounting.
*   **Service Plan Service:** Manages the creation and configuration of service plans.
*   **Reseller Service:** Provides the functionality for reseller management and multi-tenancy.
*   **Notification Service:** Sends email and SMS notifications to users.

### RADIUS Server

FreeRADIUS will be used as the RADIUS server. It is a mature and feature-rich open-source RADIUS server that is highly customizable and can be integrated with various databases and scripting languages.

### Database

A relational database like PostgreSQL or MySQL will be used to store all system data. A separate database schema will be used for each microservice to ensure data isolation. Redis will be used for caching frequently accessed data to improve performance.

### Message Queue

A message queue like RabbitMQ will be used for asynchronous communication between microservices. This will decouple the services and make the system more resilient to failures.

