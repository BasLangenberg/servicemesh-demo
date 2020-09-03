# servicemesh-demo

A servicemesh demo using Hybrid services on Digital Ocean with Consul

# requirements

In order to run this demo, you need some stuff installed.

- kubectl
- helm (version 3)
- consul cli

Obviously, you also need a Digital Ocean account.

# demo steps

## spin up infrastructure

Make sure your API key for Digital Ocean is exported.

```shell
cd infra
terraform init
terraform plan # Optional
terraform apply
```

This will create all infrastructure necessary to follow along with the demo. Make sure to remove your infrastructure if you are not using it, since you pay by the hour.

## initial deployment of applications

We'll be using a set of fake services, written by [Nic Jackson](https://twitter.com/sheriffjackson) and are a nice way to demo the service mesh idea.

As we are using a physical DB server of which we cannot predict the IP. (in this example) Next to this being an example on how a service mesh can help out, we also need to use some cli magic to update the DB ip in all manifests.

Get the IP of the DB server.

```shell
doctl compute droplet list | grep DB
```

Use the found IP in the sed command to update the manifests

```shell
find k8s -name "*yaml" | xargs sed -i 's/0.0.0.0/REAL_IP/g' 
```

Now, fetch the Kubernetes configuration file

```shell
doctl kubernetes cluster kubeconfig save ams-cluster 
```

Now deploy the application

```shell
kubectl apply -f k8s/initial-setup.yaml
```

Now, we use a trick to access the web service within the container using a port-forward trick buildin to Kubernetes

```shell
kubectl port-forward web-6fb86c6f99-nx5fd 9090:9090
```

Open your browser and access [localhost:9090/ui](http://localhost:9090/ui) to access the web service. All services should be visible and report healthy.

## install consul with helm

```shell
helm repo add hashicorp https://helm.releases.hashicorp.com/
helm install consul hashicorp/consul -f helm/config.yaml
```

You can now port-forward, like with web

```shell
kubectl port-forward consul-server-0 8501:8501
```

Consul is now [locally accessible](https://localhost:8501/ui)

## inject consul connect sidecart in applications

Show diff to the potential audience! ;-)

```shell
kubectl apply -f k8s/add-connect.yaml
```

## reconfigure applications to only listen on localhost

Show diff to the potential audience! ;-)

```shell
kubectl apply -f k8s/local-listen.yaml
```

## setup service mesh connection

Show diff to the potential audience! ;-)

```shell
kubectl apply -f k8s/configure-connect.yaml
```

## acls

Use the consul console to add an acl for web -> app

## do same thing for DB

```shell
```

# rate service in FRA1

```shell
```

## setup federation

```shell
```

## mesh the rate service

```shell
```

## connect app to rate

```shell
```

## cleanup

```shell
```

# resources

I used the [consul on Kubernetes workshop](https://github.com/lkysow/consul-on-kubernetes-workshop) by [Luke Kysow](https://github.com/lkysow) as a convinient starting point
