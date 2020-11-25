ovirt.create_k8s_env.yaml
--------
__Overview__  
Create [oVirt](https://www.ovirt.org) VMs for kubernetes environment,  
Make sure you update VMs params - under `with_items` - and `authorized_ssh_keys` before running the playbook. 


__Requirements__  
* python-ovirt-engine-sdk4


__Variables__  

| Name  | Description | Example
| -------------| ------------ | ------------ |
| engine | ovirt engine FQDN | engine.example.com
| cluster | ovirt cluster | Engineering
| template | ovirt template | CentOS_8_2_with_docker


__Usage Example__  
```shell
ansible-playbook ovirt.create_k8s_env.yaml \
    -e "engine=engine.example.com" \
    -e "cluster=Engineering" \
    -e "template=CentOS_8_2_with_docker" \
```

__Additional information__  
The ovirt-auth made by kerberos, see `ovirt_auth` module for more auth options.