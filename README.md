# HACMP High Availability Cluster Monitoring Process
I propbaly should start defining what HACMP means, but I will jump back to that later lets start with an example problem
Some application can only run in a single instance so to make it highly availble you need to be able to start up another instance in second data center if first data center goes down.
In modern world more and ore applications are self healing and work in microservice environments in a docker container managed by kubernetes, and you will be able to handle the application in that environment with the help of orchestration software like kubernetes.

But you will find situations, not often when you need some clustering solutions like veritas or IBM etc

Now I will descibe a light solution, not sofisticated but might be good enough for you to solve the problem

