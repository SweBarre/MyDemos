# Simple manuscript for helm demo

## kubectl way
```bash
cd guestbook
ll
```
Here you see the yaml-files that build up our guestbook application

```bash
cat frontend-deployment.yaml
```
this is the frontend deployment definition, it uses an image named gb-frontend and is v4. It will also deploy two replicas of this deployment. we also create two labels for this deployment, guestbook and frontend. This makes it possible to target this deployment.

```bash
cat frontend-service.yaml
```
this is the service definition for our php frontend deployment, for this simple demo we use NodePort and use the deployments labels to target this service to the correct pods.


```bash
ll
```
as you can see we have a total of six yaml files, one deployment and one service, for each component that builds our application. So let's deploy our application using kubectl


```bash
kubectl apply -f frontend-deployment.yaml
kubectl get pods
```
as you can see we are now delpoying the frontend component, there's two pods currently beeing created because we specified two replicas in our deployment manifest. There will be a loadbalancing between them and it's all handled by k8s. But we can't reach this application yet. We need a service defined first

```bash
kubectl apply -f frontend-service.yaml
```
we now see that we have a service named frontend of the type NodePort, the pods port 80 is mapped to port XXXXX on each of the worker nodes in my cluster. You ususally would be using somekind of ingress service instead of nodeport but this is not covered in this demo though.

We now need to apply the rest of the components that build our application, the redis master and redis slave and of cource the services for them.
```bash
kubectl apply -f redis-master-deployment.yaml
kubectl apply -f redis-master-service.yaml
kubectl apply -f redis-slave-deployment.yaml
kubectl apply -f redis-slave-service.yaml

kubectl get pods
```
our pods are beeing created and as soon as have a state of "Running" we can point our brower to any worker nodes IP and the frontend-service mapped port to access our guestbook application.

**Wait for the pods to get the state 'Running'**

```bash
kubectl get service
```
notice the mapped TCP port for our service and open a browser and point it to http://worker-1.suse.lab:XXXXX
add some guest notes and the open a new tab, go to http://worker-2.suse.lab:XXXXX

we can now of cource do some changes to the frontend application, new image version, change the replicas or what ever.
This is not tracked in k8s though, and you will have to make sure to document each change so you can rollback etc.
If I change the image version of redis-slave for example, have this been tested with the current version of redis-master? Will they work together?
This is usually defined within a CI/CD pipeline though, and not applied manually as we do in this demo, but the complexity can get really high when dependencies and number of components gets increesed in our application.
But there is an esier way to handle this, and this is where helm comes in.
Lets tear down this application and get started with helm.

```bash
kubectl delete -f frontend-deployment.yaml
kubectl delete -f frontend-service.yaml
kubectl delete -f redis-slave-deployment.yaml
kubectl delete -f redis-slave-service.yaml
kubectl delete -f redis-master-service.yaml
kubectl delete -f redis-master-deployment.yaml
```
Let's take a look and see if all is cleaned up
```bash
kubectl get service
kubectl get pods
```

```bash
cd ..
```
## The helm way
```bash
ll guestbook-0.1.0
```
this is the content of this chart version, a Chart.yaml and a template sub-directory

```bash
cat guestbook-0.1.0/Chart.yaml
```
 The Chart.yaml holds the metadata of the chart, version, description, mainteners, etc.. There's a lot of data that can be defined here and it's all documented in the documentation.

```bash
ll guestbook-0.1.0/templates/
```
the templates sub-directory contains all the components that we used erlier. I've not changed them at all, it's excatly the same file as we used when deploying this application stack manually using kubectl
As you might have figured out is that we are not using any heml-chart repoistories in this demo, it's all local files.

Let's deploy this application now, so instead of using kubectl for each yaml file we use helm and point it to our chart directory
```bash
helm install guestbook-0.1.0
```
As you can see, helm creates a name for this release and this name will be used as target when we we change the application stack.
this name can be defined if you want by using the helm --name parameter.
Also notice the frontend service port if you want to test the application from your browser.
The pods names are built the same way as when we use the manual deployment with kubectl, that's because the names of the pods are defined in the actual yaml files and we have not changed that.

```bash
helm list
```
we can list all our deployed chards with helm list, we can see that this is release 1.
We talked erlier in the presentation that helm was more or less a template tool, but we've not really used that ability yet so let's take a look at that and get an understanding on what we can do.

It's as easy to tear down the complete application stack with helm as it is to deploy it
```bash
helm delete *<name of the release>*
kubectl get pods
```
as you can see (if we are quick enough) the pods are terminating.

### Version 0.2.0
So far we've justused the helm for installing a complete application stack but as I said in the presentation the helm command is more or less a powerfull template tool.

```bash
ll guestbook-0.2.0/
```
The Chart.yaml has just been updated with a new version number but in version 0.2.0 we see a new file that didn't exist in version 0.1.0, namely the values.yaml.
In this file we can define variables to be used in our yaml-files that resides in the templates directory

```bash
cat guestbook-0.2.0/values.yaml
```
I've just defined the replicas and image version for each component. You can define what ever variables you see fit for your application. These variables can then be used in your yaml-files in the templates directory.

```bash
cat guestbook-0.2.0/templates/frontend-deployment.yaml
```
*{{ .Release.Name }}* in the name is a variable that is not defined by me, it's the "random name" that tiller creates for your release when we install this (or defined with the --name parameter to the helm command). By using this I can easily identify what pods belongs to what chart when running a kubectl get pods.
I've also change the replicas and image version tag to use the variables defined in our values.yaml file.

the template command will render the output and replace all variables with the defined values.
```bash
helm template guestbook-0.2.0
```
So let's deploy this chart
```bash
helm install guestbook-0.2.0
```
Notice the random name given for the release and how this has been applied to each pod and service that builds up this release

```bash
helm list
```
we've just installed this chart, so the revision number for this release is one.
Let's do some small change, this could be a new image version or an updated secret (new certificate if we would run tls for example), but for this demo we'll just change the number of frontend replicas from 2 to 4
```bash
vi guestbook-0.2.0/values.yaml
```
and then upgrade the release with this new configuration
```bash
helm upgrade eloping-catfish guestbook-0.2.0
```
and the revision for this release is now 2 because we have changed the configuration.
```bash
helm list
```

if we want to rollback the release it's just running the rollback command and specify to what release you want to rollback to
```bash
helm rollback *<release name>* 1
```

```bash
and we are back to how the revision 1 looked like, with two frontend replicas
```

becaue we use the release name variable in our resource names and we can actually deploy several releases of the same chart and in the same namespace if we want or need too.
```bash
helm install guestbook-0.2.0
helm list
```

Let's clean up
```bash
helm delete <release name>
helm delete <release name>
```
