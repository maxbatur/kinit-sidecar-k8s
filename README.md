## kinit-sidecar-k8s
This is vanilla kubernetes version of kinit-sidecar. Migrated kinit-sidecar from OpenShift/CentOS   to K8S/Alpine

## How to run

    $ git clone https://github.com/maxbatur/kinit-sidecar-k8s.git
    $ cd kinit-sidecar-k8s
    $ ./build-images.sh
    $ cd k8s
    $ ./demo-auth-k8s.sh

## How it works
`demo-auth-k8s.sh` - script creates two pods with two containers in each of them.
First pod is KDC server (`kdc` container) and KAdmin server (`kadmin` container).
Second pod has two containers:
1. `kinit-sidecar` container receives keytab from kdc and creates kerberos ticket cache from it that is shared with `example-app` container via shared memory store (/dev/shm).
2. `example-app` runs client app that is actually a simple sh script that shows shared cached kerberos tickets with klist.  That is, if you have valid ticket cache you've been authenticated and will see valid kerberos tickets.

``` 
*** checking if authenticated
Ticket cache: FILE:/dev/shm/ccache
Default principal: example@EXAMPLE.COM

Valid starting     Expires            Service principal
01/21/24 23:27:48  01/22/24 11:27:48  krbtgt/EXAMPLE.COM@EXAMPLE.COM
        renew until 01/22/24 23:27:48
``` 
Sidecar container will refresh tickets at specified interval.
See related links for more details.

## Related links
* https://www.redhat.com/en/blog/kerberos-sidecar-container
* https://medium.com/microsoftazure/connect-azure-kubernetes-java-applications-to-sql-with-kerberos-integrated-authentication-88dfa3fa382c
