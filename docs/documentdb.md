# DocumentDB

As of June 2022, there are no docker containers available for documentdb, so in
GOV.UK Docker and in CI the app runs against a vanilla MongoDB 4.0 instance.

For most purposes this is okay, but if there are major Mongo or Mongoid gem
updates it would probably be wise to test them against an actual DocumentDB
cluster. This presents a few issues:

- As above, no docker containers for DocumentDB
- Also, it appears DocumentDB clusters *cannot* be allowed to listen to the
  internet. (Even if you add a security rule to that end, it will be ignored)

The clusters are set up so that they can be accessed by db_admin class machines,
so the solution is to use SSH tunnelling through the machine, and tell
authenticating proxy to run in direct connection mode (in which it simply
connects to the mongo uri supplied and does not attempt to determine topology
and connect to a preferred primary or secondary).

To set up the tunnel, you will need to find out:

- the hostname for the DocumentDB cluster. This should be in govuk-secrets
- the ssh command for connecting through the jumpbox to the db_admin machine.
  You can find that out by using the gds-cli:
  `gds govuk connect ssh -e integration db_admin` - as this runs, it will print
  out **Running Command:** followed by an ssh command. Take that command, and add
  ` -N -L 37017:<cluster hostname>:27107`

You should end up with something like this:

```
ssh -J yourname@jumpbox.integration.publishing.service.gov.uk \
  yourname@ip-10-1-0-1.eu-west-1.compute.internal -N -L \
  37017:authenticating-proxy-documentdb-integration.cluster.docdb.amazonaws.com:27017
```

Run that (it will block), and open another terminal. If you have mongo shell
installed, you can test your tunnel by running:

`mongo mongodb://localhost:37107`

...if it connects, the tunnel is set up correctly.

Now you'll need the username and password for the DocumentDB cluster (also in govuk-secrets)

Finally, you can run:

```
govuk-docker run
  -e TEST_MONGODB_URI=mongodb://<*documentdb_username*>:<*documentdb_password*>@host.docker.internal:37017/authenticating_proxy_test \
  -e GOVUK_UPSTREAM_URI=http://government-frontend.dev.gov.uk \
  -e MONGODB_DIRECT_CONNECTION=true authenticating-proxy-lite bundle exec rake
```

(host.docker.internal being docker's way of accessing the host machine, ie 
localhost)
