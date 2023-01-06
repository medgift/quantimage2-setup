Pre-requisites for running a local instance of QuantImage v2
========================================================================

Software to install
************************************************************************
The following software needs to be installed in order to set up a local instance
of QuantImage v2:
    
- [Git](https://github.com/git-guides/install-git) for cloning the repositories
- [Docker](https://docs.docker.com/install) (Docker Desktop `>=3.4` 
or Docker Engine `>=v20.10`, with Compose V2 enabled) for running the containers

Hosts file configuration
************************************************************************
In order to run the platform locally, the following entry needs to be added to 
your "hosts" file (`/etc/hosts` on Linux, `C:\Windows\System32\drivers\etc\hosts` 
on Windows):

```127.0.0.1 keycloak```

If the line specifying `127.0.0.1 localhost` exists in the hosts file, `keycloak`
can simply be appended to the end of that line.

Browser configuration
************************************************************************
Because of restrictions regarding third-party cookies in modern browsers, 
especially for unsecured HTTP connections, problems can appear with the Keycloak
client library which checks for authentication state using an `iframe` and
cookies. To avoid issues while testing the platform on `localhost`, please use
**Firefox** as a browser and disable the **"Enhanced Tracking Protection"** 
feature for both `localhost` and `keycloak` hosts.

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