Rancher Cluster Init Script
=====
This script is made for initializing a custom rancher cluster after installing it (no cloud provider).

Is based on the script "rancher2customnodecmd.sh" from superseb.
You must use it like this:

"sh RancherInit.sh host.yourdomain.com cluster-name super-admin-password"

-----
Fixes needed: After creating the cluster, and trying to get the nodeCommand for adding nodes, the parameter "--server" returns empty, as it should return "--server https://host.yourdomain.com".

I will be very thankful to anyone who can help me, as I could not found any documentation for Rancher's API.


