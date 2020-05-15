# HACMP High Availability Cluster Monitoring Process
I propbaly should start defining what HACMP means, but I will jump back to that later lets start with an example problem
Some application can only run in a single instance so to make it highly availble you need to be able to start up another instance in second data center if first data center goes down.
In modern world more and ore applications are self healing and work in microservice environments in a docker container managed by kubernetes, and you will be able to handle the application in that environment with the help of orchestration software like kubernetes.

Sometime you have applications that can only run in one instance and you do not have clustering software or can run this in a Microservices environment with orchestration support with kubernetes.

Requirement definition;

Application can only have one instant running at any point in time
We must be able to handle a linux host failure
We must be able to handle a data center failure
We must be able to set the system in maintenance mode
Solution design

We use a heartbeat software to store heartbeats of a running instance of the application
We store heartbeats on a storage accessible by all hosts
Heartbeat software start application if it shall run on this host
If application is running on another host it will stop any local instances
We have a way to define maintenance by storing a maintenance state on the same storage as we store heartbeats which is available to all hosts
Solution technical design with a shared disk

We have two linux servers one in each data center (we have 2 data centers)
We have a heartbeat process installed as a service (daemon) on two linux servers
We have the application installed on both linux servers
We use a shared disk for heartbeats and maintenance information


Have a look at http://max.bback.se/index.php/2020/05/15/hacmp-high-availability-cluster-monitoring-process/ for a more visual description

