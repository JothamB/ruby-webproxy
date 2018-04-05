# WEBPROXY

Bridges traffic between website and a client.
Supprts HTTP as well as HTTPS connections.
To bridge HTTPS connection you have to provide private key and certificate for the client.
Use --verbose to print all the routed traffic to standard output.

### Install Requirements

```gem install colorize```

### Usage

```./webproxy.rb --website WebSite [--ssl --key /Path/To/Key --cert /Path/To/Cert] [--verbose]```

### Author

JothamB (C) 2018

### Licence

GPL. See COPYING for licensing details.
