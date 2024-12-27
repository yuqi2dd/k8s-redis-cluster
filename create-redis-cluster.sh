#!/bin/bash

# 创建k8s资源
kubectl apply -f redis-configmap.yaml
kubectl apply -f redis-service.yaml

# 删除StatefulSet
echo "删除StatefulSet..."
kubectl delete statefulset redis-cluster

# 重新创建StatefulSet
echo "重新创建StatefulSet..."
kubectl apply -f redis-statefulset.yaml

# 等待所有pod就绪
echo "等待所有Redis pod就绪..."
kubectl wait --for=condition=Ready pod/redis-cluster-0
kubectl wait --for=condition=Ready pod/redis-cluster-1
kubectl wait --for=condition=Ready pod/redis-cluster-2
kubectl wait --for=condition=Ready pod/redis-cluster-3
kubectl wait --for=condition=Ready pod/redis-cluster-4
kubectl wait --for=condition=Ready pod/redis-cluster-5

# 获取所有pod的IP
echo "获取Pod IP..."
nodes=""
for i in $(seq 0 5); do
  ip=$(kubectl get pod redis-cluster-$i -o jsonpath='{.status.podIP}')
  nodes="$nodes $ip:6379"
done

# 创建集群
echo "创建Redis集群..."
kubectl exec -it redis-cluster-0 -- redis-cli --cluster create $nodes --cluster-replicas 1 --cluster-yes

echo "Redis集群创建完成!" 