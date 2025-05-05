# alterseccomp
Add seccomp policy just in time

## Guide

Start the `audit_seccomp` gadget in a separate terminal and keep it running in the background:
```
$ kubectl-gadget run audit_seccomp
K8S.NODE                K8S.NAMESPACE           K8S.PODNAME             K8S.CONTAINERNAME      COMM               PID        TID CODE           SYSCALL
```

Run a test workload:
```
$ kubectl debug node/aks-userpool-19827012-vmss000000 -it --image=busybox
/ # grep ^Seccomp: /proc/self/status
Seccomp:	0
/ # mkdir /a /b && mount --bind /a /b
mount: mounting /a on /b failed: Permission denied
/ # 
```
The line `Seccomp: 0` tells that pods don't have a seccomp policy by default on my cluster.
The `audit_seccomp` gadget didn't pick up any event.

Now, deploy alterseccomp:
```
$ kubectl apply -f deploy.yaml
namespace/alterseccomp created
serviceaccount/alterseccomp created
clusterrole.rbac.authorization.k8s.io/alterseccomp-cluster-role created
clusterrolebinding.rbac.authorization.k8s.io/alterseccomp-cluster-role-binding created
$ kubectl get pod -n alterseccomp
NAME                 READY   STATUS    RESTARTS   AGE
alterseccomp-28xrp   1/1     Running   0          32s
alterseccomp-ww8z2   1/1     Running   0          32s
```

Run the test workload again:
```
$ kubectl debug node/aks-userpool-19827012-vmss000000 -it --image=busybox
/ # grep ^Seccomp: /proc/self/status
Seccomp:	2
/ # mkdir /a /b && mount --bind /a /b
mount: permission denied (are you root?)
/ # 
```

This time, the line `Seccomp: 2` tells that there is a seccomp policy. It was added by alterseccomp:
```
$ kubectl logs -n alterseccomp alterseccomp-ww8z2
Seccomp flags updated: [SECCOMP_FILTER_FLAG_LOG]
Seccomp config is nil. Creating one from containerd.
```

And the `audit_seccomp` gives this event:
```
K8S.NODE                K8S.NAMESPACE           K8S.PODNAME             K8S.CONTAINERNAME      COMM               PID        TID CODE           SYSCALL       
aks-userpoo…-vmss000000 default                 node-debugg…00000-4t9bn debugger               mount           155432     155432 …OMP_RET_ERRNO SYS_MOUNT     
```
