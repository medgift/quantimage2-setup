Setting up the QuantImage v2 platform
========================================================================
Open a Terminal in the current directory, and run the following command:

```./setup-quantimage2.sh```

This will clone all the required repositories, generate secrets automatically
and ask for passwords for the Keycloak authentication platform and a sample
user for QuantImage v2 & Kheops.

It will then build all the necessary Docker images and create all the
containers required to run the platform.


Updating QuantImage v2
========================================================================

Open a Terminal in the current directory, and run the following command:

```./update-quantimage2.sh```

This will pull the latest versions of the QuantImage v2 repositories
and rebuild the Docker containers accordingly.