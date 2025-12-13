"""
AWS Security Groups and NACLs Visualizer
Generates Mermaid sequence diagrams for AWS network security configuration
"""

import boto3
import json
from collections import defaultdict
from datetime import datetime
import argparse

class SecurityVisualizer:
    def __init__(self, region='us-east-1'):
        self.ec2 = boto3.client('ec2', region_name=region)
        try:
            self.elbv2 = boto3.client('elbv2', region_name=region)
        except:
            self.elbv2 = None
        try:
            self.rds = boto3.client('rds', region_name=region)
        except:
            self.rds = None
        try:
            self.lambda_client = boto3.client('lambda', region_name=region)
        except:
            self.lambda_client = None
        try:
            self.ecs = boto3.client('ecs', region_name=region)
        except:
            self.ecs = None
        try:
            self.eks = boto3.client('eks', region_name=region)
        except:
            self.eks = None
        self.region = region
        self.security_groups = {}
        self.nacls = {}
        self.vpcs = {}
        self.sg_to_components = defaultdict(list)  # Map SG ID to list of components
        self.components = {}  # Store component details
        
    def fetch_all_data(self):
        """Fetch all security groups, NACLs, VPCs, and components"""
        print("Fetching AWS resources...")
        
        # Fetch VPCs
        print("  - Fetching VPCs...")
        vpc_response = self.ec2.describe_vpcs()
        for vpc in vpc_response['Vpcs']:
            self.vpcs[vpc['VpcId']] = vpc
        
        # Fetch Security Groups
        print("  - Fetching Security Groups...")
        sg_response = self.ec2.describe_security_groups()
        for sg in sg_response['SecurityGroups']:
            self.security_groups[sg['GroupId']] = sg
        
        # Fetch Network ACLs
        print("  - Fetching Network ACLs...")
        nacl_response = self.ec2.describe_network_acls()
        for nacl in nacl_response['NetworkAcls']:
            self.nacls[nacl['NetworkAclId']] = nacl
        
        # Fetch components that use security groups
        print("  - Fetching EC2 instances...")
        self._fetch_ec2_instances()
        
        print("  - Fetching Load Balancers...")
        self._fetch_load_balancers()
        
        print("  - Fetching RDS instances...")
        self._fetch_rds_instances()
        
        print("  - Fetching Lambda functions...")
        self._fetch_lambda_functions()
        
        print("  - Fetching ECS services...")
        self._fetch_ecs_services()
        
        print("  - Fetching EKS clusters...")
        self._fetch_eks_clusters()
        
        print("  - Fetching VPC Endpoints (S3, ECR)...")
        self._fetch_vpc_endpoints()
        
        print(f"  ✓ Found {len(self.vpcs)} VPCs, {len(self.security_groups)} Security Groups, {len(self.nacls)} NACLs")
        print(f"  ✓ Found {len(self.components)} components attached to security groups")
    
    def _fetch_ec2_instances(self):
        """Fetch EC2 instances and map to security groups"""
        try:
            response = self.ec2.describe_instances()
            for reservation in response.get('Reservations', []):
                for instance in reservation.get('Instances', []):
                    instance_id = instance['InstanceId']
                    instance_name = self._get_resource_name(instance.get('Tags', []), instance_id)
                    instance_type = instance.get('InstanceType', 'unknown')
                    
                    component = {
                        'type': 'EC2',
                        'id': instance_id,
                        'name': instance_name,
                        'details': f"{instance_type} Instance"
                    }
                    self.components[instance_id] = component
                    
                    # Map security groups to this instance
                    for sg in instance.get('SecurityGroups', []):
                        sg_id = sg['GroupId']
                        self.sg_to_components[sg_id].append(component)
        except Exception as e:
            print(f"    Warning: Could not fetch EC2 instances: {e}")
    
    def _fetch_load_balancers(self):
        """Fetch Load Balancers (ALB, NLB, CLB) and map to security groups"""
        if not self.elbv2:
            return
        try:
            # Application and Network Load Balancers
            response = self.elbv2.describe_load_balancers()
            for lb in response.get('LoadBalancers', []):
                lb_arn = lb['LoadBalancerArn']
                lb_name = lb.get('LoadBalancerName', lb_arn.split('/')[-1])
                lb_type = lb.get('Type', 'ALB')
                
                component = {
                    'type': f'{lb_type}',
                    'id': lb_arn,
                    'name': lb_name,
                    'details': f"{lb_type} Load Balancer"
                }
                self.components[lb_arn] = component
                
                # Get security groups for ALB/NLB (they're in the load balancer description)
                for sg_id in lb.get('SecurityGroups', []):
                    self.sg_to_components[sg_id].append(component)
        except Exception as e:
            # ELBv2 might not be available
            if 'elbv2' not in str(e).lower():
                print(f"    Warning: Could not fetch Load Balancers: {e}")
        
        try:
            # Classic Load Balancers
            elb = boto3.client('elb', region_name=self.region)
            response = elb.describe_load_balancers()
            for lb in response.get('LoadBalancerDescriptions', []):
                lb_name = lb['LoadBalancerName']
                
                component = {
                    'type': 'CLB',
                    'id': lb_name,
                    'name': lb_name,
                    'details': 'Classic Load Balancer'
                }
                self.components[lb_name] = component
                
                for sg_id in lb.get('SecurityGroups', []):
                    self.sg_to_components[sg_id].append(component)
        except Exception as e:
            print(f"    Warning: Could not fetch Classic Load Balancers: {e}")
    
    def _fetch_rds_instances(self):
        """Fetch RDS instances and map to security groups"""
        if not self.rds:
            return
        try:
            response = self.rds.describe_db_instances()
            for db in response.get('DBInstances', []):
                db_id = db['DBInstanceIdentifier']
                db_engine = db.get('Engine', 'unknown')
                
                component = {
                    'type': 'RDS',
                    'id': db_id,
                    'name': db_id,
                    'details': f"{db_engine} Database"
                }
                self.components[db_id] = component
                
                for sg in db.get('VpcSecurityGroups', []):
                    sg_id = sg['VpcSecurityGroupId']
                    self.sg_to_components[sg_id].append(component)
        except Exception as e:
            print(f"    Warning: Could not fetch RDS instances: {e}")
    
    def _fetch_lambda_functions(self):
        """Fetch Lambda functions with VPC configuration"""
        if not self.lambda_client:
            return
        try:
            paginator = self.lambda_client.get_paginator('list_functions')
            for page in paginator.paginate():
                for func in page.get('Functions', []):
                    func_name = func['FunctionName']
                    vpc_config = func.get('VpcConfig')
                    
                    if vpc_config and vpc_config.get('SecurityGroupIds'):
                        component = {
                            'type': 'Lambda',
                            'id': func_name,
                            'name': func_name,
                            'details': 'Lambda Function'
                        }
                        self.components[func_name] = component
                        
                        for sg_id in vpc_config['SecurityGroupIds']:
                            self.sg_to_components[sg_id].append(component)
        except Exception as e:
            print(f"    Warning: Could not fetch Lambda functions: {e}")
    
    def _fetch_ecs_services(self):
        """Fetch ECS services and tasks with security groups"""
        if not self.ecs:
            return
        try:
            # List all clusters
            cluster_response = self.ecs.list_clusters()
            cluster_arns = cluster_response.get('clusterArns', [])
            
            for cluster_arn in cluster_arns:
                cluster_name = cluster_arn.split('/')[-1]
                
                # Get cluster details
                try:
                    cluster_details = self.ecs.describe_clusters(clusters=[cluster_arn])
                    cluster_info = cluster_details.get('clusters', [{}])[0]
                except:
                    cluster_info = {}
                
                # List services in cluster
                try:
                    services_response = self.ecs.list_services(cluster=cluster_arn)
                    service_arns = services_response.get('serviceArns', [])
                    
                    # Describe services (batch of 10)
                    for i in range(0, len(service_arns), 10):
                        batch = service_arns[i:i+10]
                        try:
                            services_details = self.ecs.describe_services(
                                cluster=cluster_arn,
                                services=batch
                            )
                            
                            for service in services_details.get('services', []):
                                service_name = service.get('serviceName', 'unknown')
                                service_id = f"{cluster_name}/{service_name}"
                                
                                component = {
                                    'type': 'ECS',
                                    'id': service_id,
                                    'name': service_name,
                                    'details': f"ECS Service in {cluster_name}"
                                }
                                self.components[service_id] = component
                                
                                # Get security groups from network configuration
                                network_config = service.get('networkConfiguration', {})
                                awsvpc_config = network_config.get('awsvpcConfiguration', {})
                                security_groups = awsvpc_config.get('securityGroups', [])
                                
                                for sg_id in security_groups:
                                    self.sg_to_components[sg_id].append(component)
                        except Exception as e:
                            print(f"    Warning: Could not fetch ECS service details: {e}")
                except Exception as e:
                    print(f"    Warning: Could not list ECS services in {cluster_name}: {e}")
                
                # Also check tasks for security groups (Fargate tasks)
                try:
                    tasks_response = self.ecs.list_tasks(cluster=cluster_arn)
                    task_arns = tasks_response.get('taskArns', [])
                    
                    # Describe tasks (batch of 100)
                    for i in range(0, len(task_arns), 100):
                        batch = task_arns[i:i+100]
                        try:
                            tasks_details = self.ecs.describe_tasks(
                                cluster=cluster_arn,
                                tasks=batch
                            )
                            
                            for task in tasks_details.get('tasks', []):
                                task_id = task.get('taskArn', '').split('/')[-1]
                                task_def_arn = task.get('taskDefinitionArn', '')
                                
                                # Get security groups from task attachments
                                attachments = task.get('attachments', [])
                                for attachment in attachments:
                                    if attachment.get('type') == 'ElasticNetworkInterface':
                                        details = attachment.get('details', [])
                                        for detail in details:
                                            if detail.get('name') == 'securityGroups':
                                                sg_ids = detail.get('value', '').split(',')
                                                component = {
                                                    'type': 'ECS',
                                                    'id': f"{cluster_name}/task-{task_id}",
                                                    'name': f"Task-{task_id[:8]}",
                                                    'details': f"ECS Task in {cluster_name}"
                                                }
                                                self.components[f"{cluster_name}/task-{task_id}"] = component
                                                
                                                for sg_id in sg_ids:
                                                    if sg_id:
                                                        self.sg_to_components[sg_id].append(component)
                        except Exception as e:
                            print(f"    Warning: Could not fetch ECS task details: {e}")
                except Exception as e:
                    pass  # Tasks might not be available
        except Exception as e:
            print(f"    Warning: Could not fetch ECS services: {e}")
    
    def _fetch_eks_clusters(self):
        """Fetch EKS clusters and node groups with security groups"""
        if not self.eks:
            return
        try:
            # List all clusters
            cluster_response = self.eks.list_clusters()
            cluster_names = cluster_response.get('clusters', [])
            
            for cluster_name in cluster_names:
                try:
                    # Get cluster details
                    cluster_details = self.eks.describe_cluster(name=cluster_name)
                    cluster_info = cluster_details.get('cluster', {})
                    
                    component = {
                        'type': 'EKS',
                        'id': cluster_name,
                        'name': cluster_name,
                        'details': 'EKS Cluster'
                    }
                    self.components[f"eks-{cluster_name}"] = component
                    
                    # Get security groups from cluster resources VPC config
                    resources_vpc_config = cluster_info.get('resourcesVpcConfig', {})
                    cluster_security_groups = resources_vpc_config.get('securityGroupIds', [])
                    
                    for sg_id in cluster_security_groups:
                        self.sg_to_components[sg_id].append(component)
                    
                    # List and describe node groups
                    try:
                        node_groups_response = self.eks.list_nodegroups(clusterName=cluster_name)
                        node_group_names = node_groups_response.get('nodegroups', [])
                        
                        for node_group_name in node_group_names:
                            try:
                                node_group_details = self.eks.describe_nodegroup(
                                    clusterName=cluster_name,
                                    nodegroupName=node_group_name
                                )
                                node_group_info = node_group_details.get('nodegroup', {})
                                
                                component = {
                                    'type': 'EKS',
                                    'id': f"{cluster_name}/{node_group_name}",
                                    'name': node_group_name,
                                    'details': f"EKS Node Group in {cluster_name}"
                                }
                                self.components[f"eks-{cluster_name}-{node_group_name}"] = component
                                
                                # EKS node groups don't directly expose security groups in the API
                                # We'll get them from EC2 instances that are part of the node group
                                # (handled in the EC2 instance fetch below)
                                
                            except Exception as e:
                                print(f"    Warning: Could not fetch EKS node group {node_group_name}: {e}")
                    except Exception as e:
                        print(f"    Warning: Could not list EKS node groups: {e}")
                    
                    # Also check EC2 instances that might be part of EKS (tagged with cluster name)
                    # This helps identify node group security groups
                    try:
                        instances_response = self.ec2.describe_instances(
                            Filters=[
                                {'Name': 'tag:eks:cluster-name', 'Values': [cluster_name]},
                                {'Name': 'instance-state-name', 'Values': ['running', 'stopped']}
                            ]
                        )
                        for reservation in instances_response.get('Reservations', []):
                            for instance in reservation.get('Instances', []):
                                instance_id = instance['InstanceId']
                                instance_name = self._get_resource_name(instance.get('Tags', []), instance_id)
                                
                                component = {
                                    'type': 'EKS',
                                    'id': f"{cluster_name}/node-{instance_id}",
                                    'name': f"{node_group_name or 'Node'}-{instance_id[:8]}",
                                    'details': f"EKS Node in {cluster_name}"
                                }
                                self.components[f"eks-{cluster_name}-{instance_id}"] = component
                                
                                # Map security groups
                                for sg in instance.get('SecurityGroups', []):
                                    sg_id = sg['GroupId']
                                    self.sg_to_components[sg_id].append(component)
                    except Exception as e:
                        pass  # EC2 instances might not be tagged or accessible
                        
                except Exception as e:
                    print(f"    Warning: Could not fetch EKS cluster {cluster_name}: {e}")
        except Exception as e:
            print(f"    Warning: Could not fetch EKS clusters: {e}")
    
    def _fetch_vpc_endpoints(self):
        """Fetch VPC Endpoints (S3, ECR, etc.) and map to security groups"""
        try:
            # Describe VPC endpoints
            paginator = self.ec2.get_paginator('describe_vpc_endpoints')
            for page in paginator.paginate():
                for endpoint in page.get('VpcEndpoints', []):
                    endpoint_id = endpoint['VpcEndpointId']
                    endpoint_type = endpoint.get('VpcEndpointType', 'Gateway')
                    service_name = endpoint.get('ServiceName', '')
                    
                    # Extract service type from service name
                    # Format: com.amazonaws.region.service-name
                    service_type = 'Unknown'
                    if 's3' in service_name.lower():
                        service_type = 'S3'
                    elif 'ecr' in service_name.lower() or 'ecr-dkr' in service_name.lower():
                        service_type = 'ECR'
                    elif 'ecr.api' in service_name.lower():
                        service_type = 'ECR API'
                    elif 'ec2' in service_name.lower():
                        service_type = 'EC2'
                    elif 'dynamodb' in service_name.lower():
                        service_type = 'DynamoDB'
                    elif 'logs' in service_name.lower():
                        service_type = 'CloudWatch Logs'
                    elif 'sns' in service_name.lower():
                        service_type = 'SNS'
                    elif 'sqs' in service_name.lower():
                        service_type = 'SQS'
                    else:
                        # Extract from service name
                        parts = service_name.split('.')
                        if len(parts) > 0:
                            service_type = parts[-1].replace('-', ' ').title()
                    
                    endpoint_name = self._get_resource_name(endpoint.get('Tags', []), endpoint_id)
                    
                    # Only Interface endpoints use security groups
                    # Gateway endpoints (S3, DynamoDB) don't use security groups
                    if endpoint_type == 'Interface':
                        component = {
                            'type': service_type,
                            'id': endpoint_id,
                            'name': endpoint_name,
                            'details': f"{service_type} VPC Endpoint"
                        }
                        self.components[endpoint_id] = component
                        
                        # Map security groups from endpoint
                        for sg in endpoint.get('Groups', []):
                            sg_id = sg.get('GroupId')
                            if sg_id:
                                self.sg_to_components[sg_id].append(component)
                    elif endpoint_type == 'Gateway':
                        # Gateway endpoints don't use security groups, but we can still track them
                        # They're important for understanding network architecture
                        component = {
                            'type': f'{service_type} Gateway',
                            'id': endpoint_id,
                            'name': endpoint_name,
                            'details': f"{service_type} Gateway Endpoint (no SG)"
                        }
                        self.components[endpoint_id] = component
                        # Note: Gateway endpoints don't have security groups
        except Exception as e:
            print(f"    Warning: Could not fetch VPC Endpoints: {e}")
    
    def _get_resource_name(self, tags, default_id):
        """Extract Name tag from resource tags"""
        for tag in tags:
            if tag.get('Key') == 'Name':
                return tag.get('Value', default_id)
        return default_id
    
    def _is_internet_cidr(self, cidr):
        """Check if CIDR represents internet/public access"""
        if not cidr:
            return False
        cidr_ip = cidr if isinstance(cidr, str) else cidr.get('CidrIp', '')
        return cidr_ip == '0.0.0.0/0' or cidr_ip.startswith('0.0.0.0')
    
    def _get_component_name(self, sg_id):
        """Get component names attached to a security group"""
        components = self.sg_to_components.get(sg_id, [])
        if not components:
            return None
        
        # Group by type
        by_type = defaultdict(list)
        for comp in components:
            by_type[comp['type']].append(comp['name'])
        
        # Format component list
        parts = []
        for comp_type, names in by_type.items():
            if len(names) == 1:
                parts.append(f"{comp_type}: {names[0]}")
            else:
                parts.append(f"{comp_type}: {names[0]} (+{len(names)-1})")
        
        return ", ".join(parts) if parts else None
    
    def generate_security_groups_diagram(self):
        """Generate Mermaid diagram for Security Groups"""
        mermaid = ["```mermaid", "graph TB"]
        
        # Group security groups by VPC
        vpc_sgs = defaultdict(list)
        for sg_id, sg in self.security_groups.items():
            vpc_id = sg.get('VpcId', 'default')
            vpc_sgs[vpc_id].append(sg_id)
        
        # Create nodes for each VPC
        for vpc_id, sg_ids in vpc_sgs.items():
            vpc_name = self.vpcs.get(vpc_id, {}).get('Tags', [{}])[0].get('Value', vpc_id) if vpc_id in self.vpcs else vpc_id
            mermaid.append(f"    subgraph VPC_{vpc_id.replace('-', '_')}[\"VPC: {vpc_name}\"]")
            
            for sg_id in sg_ids:
                sg = self.security_groups[sg_id]
                sg_name = sg.get('GroupName', sg_id)
                description = sg.get('Description', '').replace('"', "'")
                
                # Count rules
                ingress_count = len(sg.get('IpPermissions', []))
                egress_count = len(sg.get('IpPermissionsEgress', []))
                
                # Get attached components
                component_info = self._get_component_name(sg_id)
                component_text = f"<br/>Attached: {component_info}" if component_info else ""
                
                mermaid.append(f"        SG_{sg_id.replace('-', '_')}[\"SG: {sg_name}<br/>{sg_id}<br/>Ingress: {ingress_count} | Egress: {egress_count}{component_text}\"]")
            
            mermaid.append("    end")
        
        # Add Internet/User node
        mermaid.append("    Internet[\"Internet/User\"]")
        mermaid.append("")
        
        # Add connections based on security group references
        mermaid.append("    %% Security Group References")
        for sg_id, sg in self.security_groups.items():
            sg_name = sg_id.replace('-', '_')
            
            # Check ingress rules for SG references and CIDR blocks
            for rule in sg.get('IpPermissions', []):
                port_range = self._format_port_range(rule)
                protocol = rule.get('IpProtocol', '-1')
                
                # Check for CIDR blocks (Internet/User)
                for cidr in rule.get('IpRanges', []):
                    cidr_ip = cidr.get('CidrIp', '')
                    if self._is_internet_cidr(cidr_ip):
                        mermaid.append(f"    Internet -->|\"{protocol} {port_range}\"| SG_{sg_name}")
                    else:
                        # Specific CIDR - show as source
                        source_name = f"CIDR: {cidr_ip}"
                        mermaid.append(f"    CIDR_{cidr_ip.replace('.', '_').replace('/', '_')}[\"{source_name}\"]")
                        mermaid.append(f"    CIDR_{cidr_ip.replace('.', '_').replace('/', '_')} -->|\"{protocol} {port_range}\"| SG_{sg_name}")
                
                # Check for security group references
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    referenced_sg = user_id_group_pair.get('GroupId')
                    if referenced_sg and referenced_sg in self.security_groups:
                        ref_name = referenced_sg.replace('-', '_')
                        # Get source component name
                        source_components = self._get_component_name(referenced_sg)
                        source_label = f"{port_range}"
                        if source_components:
                            source_label = f"{source_components}<br/>{port_range}"
                        mermaid.append(f"    SG_{ref_name} -->|\"{source_label}\"| SG_{sg_name}")
            
            # Check egress rules for SG references and CIDR blocks
            for rule in sg.get('IpPermissionsEgress', []):
                port_range = self._format_port_range(rule)
                protocol = rule.get('IpProtocol', '-1')
                
                # Check for CIDR blocks (Internet/User)
                for cidr in rule.get('IpRanges', []):
                    cidr_ip = cidr.get('CidrIp', '')
                    if self._is_internet_cidr(cidr_ip):
                        mermaid.append(f"    SG_{sg_name} -->|\"{protocol} {port_range}\"| Internet")
                    else:
                        # Specific CIDR - show as destination
                        dest_name = f"CIDR: {cidr_ip}"
                        mermaid.append(f"    CIDR_{cidr_ip.replace('.', '_').replace('/', '_')}[\"{dest_name}\"]")
                        mermaid.append(f"    SG_{sg_name} -->|\"{protocol} {port_range}\"| CIDR_{cidr_ip.replace('.', '_').replace('/', '_')}")
                
                # Check for security group references
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    referenced_sg = user_id_group_pair.get('GroupId')
                    if referenced_sg and referenced_sg in self.security_groups:
                        ref_name = referenced_sg.replace('-', '_')
                        # Get destination component name
                        dest_components = self._get_component_name(referenced_sg)
                        dest_label = f"{port_range}"
                        if dest_components:
                            dest_label = f"{dest_components}<br/>{port_range}"
                        mermaid.append(f"    SG_{sg_name} -->|\"{dest_label}\"| SG_{ref_name}")
        
        mermaid.append("```")
        return "\n".join(mermaid)
    
    def generate_nacls_diagram(self):
        """Generate Mermaid diagram for Network ACLs"""
        mermaid = ["```mermaid", "graph TB"]
        
        # Group NACLs by VPC
        vpc_nacls = defaultdict(list)
        for nacl_id, nacl in self.nacls.items():
            vpc_id = nacl.get('VpcId', 'default')
            vpc_nacls[vpc_id].append(nacl_id)
        
        # Create nodes for each VPC
        for vpc_id, nacl_ids in vpc_nacls.items():
            vpc_name = self.vpcs.get(vpc_id, {}).get('Tags', [{}])[0].get('Value', vpc_id) if vpc_id in self.vpcs else vpc_id
            mermaid.append(f"    subgraph VPC_{vpc_id.replace('-', '_')}[\"VPC: {vpc_name}\"]")
            
            for nacl_id in nacl_ids:
                nacl = self.nacls[nacl_id]
                nacl_name = "Default" if nacl.get('IsDefault', False) else nacl_id
                
                # Count rules
                ingress_rules = [r for r in nacl.get('Entries', []) if not r.get('Egress', False)]
                egress_rules = [r for r in nacl.get('Entries', []) if r.get('Egress', False)]
                
                mermaid.append(f"        NACL_{nacl_id.replace('-', '_')}[\"NACL: {nacl_name}<br/>{nacl_id}<br/>Ingress: {len(ingress_rules)} | Egress: {len(egress_rules)}\"]")
            
            mermaid.append("    end")
        
        mermaid.append("```")
        return "\n".join(mermaid)
    
    def generate_sequence_diagram(self, source_sg_id=None, target_sg_id=None):
        """Generate Mermaid sequence diagram showing traffic flow"""
        mermaid = ["```mermaid", "sequenceDiagram"]
        
        if source_sg_id and target_sg_id:
            # Specific flow diagram
            source_sg = self.security_groups.get(source_sg_id)
            target_sg = self.security_groups.get(target_sg_id)
            
            if not source_sg or not target_sg:
                return "Error: Security groups not found"
            
            source_sg_name = source_sg.get('GroupName', source_sg_id)
            target_sg_name = target_sg.get('GroupName', target_sg_id)
            
            # Get component names
            source_components = self._get_component_name(source_sg_id)
            target_components = self._get_component_name(target_sg_id)
            
            source_label = f"{source_sg_name}<br/>{source_sg_id}"
            if source_components:
                source_label = f"{source_sg_name}<br/>{source_sg_id}<br/>({source_components})"
            
            target_label = f"{target_sg_name}<br/>{target_sg_id}"
            if target_components:
                target_label = f"{target_sg_name}<br/>{target_sg_id}<br/>({target_components})"
            
            mermaid.append(f"    participant Source as \"{source_label}\"")
            mermaid.append(f"    participant Target as \"{target_label}\"")
            mermaid.append("")
            
            # Check if source can reach target
            can_reach = False
            for rule in target_sg.get('IpPermissions', []):
                port_range = self._format_port_range(rule)
                protocol = rule.get('IpProtocol', '-1')
                
                # Check security group references
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    if user_id_group_pair.get('GroupId') == source_sg_id:
                        mermaid.append(f"    Source->>Target: {protocol} {port_range}")
                        can_reach = True
                
                # Check CIDR blocks
                for cidr in rule.get('IpRanges', []):
                    cidr_ip = cidr.get('CidrIp', '')
                    if self._is_internet_cidr(cidr_ip):
                        mermaid.append(f"    Note over Source: Internet/User can access")
                        mermaid.append(f"    Source->>Target: {protocol} {port_range}")
                        can_reach = True
            
            if not can_reach:
                mermaid.append("    Source-->>Target: ❌ Blocked")
        else:
            # General overview with components
            mermaid.append("    participant Internet as \"Internet/User\"")
            mermaid.append("    participant VPC")
            
            # Add security groups with component info
            for sg_id, sg in list(self.security_groups.items())[:10]:  # Limit to first 10 for readability
                sg_name = sg.get('GroupName', sg_id)
                components = self._get_component_name(sg_id)
                label = f"{sg_name}"
                if components:
                    label = f"{sg_name}<br/>({components})"
                mermaid.append(f"    participant SG_{sg_id.replace('-', '_')} as \"{label}\"")
            
            mermaid.append("")
            mermaid.append("    Internet->>VPC: Traffic")
            mermaid.append("    VPC->>SG_*: Filtered by Security Groups")
        
        mermaid.append("```")
        return "\n".join(mermaid)
    
    def generate_detailed_security_report(self):
        """Generate detailed security report with Mermaid diagrams"""
        report = []
        report.append("# AWS Security Groups and NACLs Visualization")
        report.append(f"\nGenerated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Region: {self.region}")
        report.append(f"\n## Summary")
        report.append(f"- VPCs: {len(self.vpcs)}")
        report.append(f"- Security Groups: {len(self.security_groups)}")
        report.append(f"- Network ACLs: {len(self.nacls)}")
        
        # Security Groups Diagram
        report.append("\n## Security Groups Overview")
        report.append(self.generate_security_groups_diagram())
        
        # NACLs Diagram
        report.append("\n## Network ACLs Overview")
        report.append(self.generate_nacls_diagram())
        
        # Detailed Security Groups
        report.append("\n## Security Groups Details")
        for sg_id, sg in self.security_groups.items():
            sg_name = sg.get('GroupName', 'N/A')
            vpc_id = sg.get('VpcId', 'N/A')
            description = sg.get('Description', 'N/A')
            
            report.append(f"\n### {sg_name} ({sg_id})")
            report.append(f"- VPC: {vpc_id}")
            report.append(f"- Description: {description}")
            
            # Attached Components
            components = self._get_component_name(sg_id)
            if components:
                report.append(f"\n**Attached Components:**")
                report.append(f"  - {components}")
            
            # Ingress Rules
            report.append("\n**Ingress Rules:**")
            for rule in sg.get('IpPermissions', []):
                protocol = rule.get('IpProtocol', '-1')
                port_range = self._format_port_range(rule)
                
                # CIDR blocks
                for cidr in rule.get('IpRanges', []):
                    cidr_ip = cidr.get('CidrIp', 'N/A')
                    source_name = "Internet/User" if self._is_internet_cidr(cidr_ip) else cidr_ip
                    report.append(f"  - Allow {protocol} {port_range} from {source_name}")
                
                # Security Group references
                for sg_ref in rule.get('UserIdGroupPairs', []):
                    ref_sg_id = sg_ref.get('GroupId', 'N/A')
                    ref_sg_name = self.security_groups.get(ref_sg_id, {}).get('GroupName', ref_sg_id) if ref_sg_id in self.security_groups else ref_sg_id
                    ref_components = self._get_component_name(ref_sg_id)
                    source_info = f"SG: {ref_sg_name} ({ref_sg_id})"
                    if ref_components:
                        source_info += f" - {ref_components}"
                    report.append(f"  - Allow {protocol} {port_range} from {source_info}")
            
            # Egress Rules
            report.append("\n**Egress Rules:**")
            for rule in sg.get('IpPermissionsEgress', []):
                protocol = rule.get('IpProtocol', '-1')
                port_range = self._format_port_range(rule)
                
                for cidr in rule.get('IpRanges', []):
                    cidr_ip = cidr.get('CidrIp', 'N/A')
                    dest_name = "Internet/User" if self._is_internet_cidr(cidr_ip) else cidr_ip
                    report.append(f"  - Allow {protocol} {port_range} to {dest_name}")
                
                for sg_ref in rule.get('UserIdGroupPairs', []):
                    ref_sg_id = sg_ref.get('GroupId', 'N/A')
                    ref_sg_name = self.security_groups.get(ref_sg_id, {}).get('GroupName', ref_sg_id) if ref_sg_id in self.security_groups else ref_sg_id
                    ref_components = self._get_component_name(ref_sg_id)
                    dest_info = f"SG: {ref_sg_name} ({ref_sg_id})"
                    if ref_components:
                        dest_info += f" - {ref_components}"
                    report.append(f"  - Allow {protocol} {port_range} to {dest_info}")
        
        # NACLs Details
        report.append("\n## Network ACLs Details")
        for nacl_id, nacl in self.nacls.items():
            vpc_id = nacl.get('VpcId', 'N/A')
            is_default = nacl.get('IsDefault', False)
            nacl_name = "Default NACL" if is_default else nacl_id
            
            report.append(f"\n### {nacl_name} ({nacl_id})")
            report.append(f"- VPC: {vpc_id}")
            report.append(f"- Default: {is_default}")
            
            # Ingress Rules
            ingress_rules = sorted([r for r in nacl.get('Entries', []) if not r.get('Egress', False)], 
                                 key=lambda x: x.get('RuleNumber', 0))
            report.append("\n**Ingress Rules:**")
            for rule in ingress_rules:
                rule_num = rule.get('RuleNumber', 'N/A')
                protocol = rule.get('Protocol', '-1')
                action = "ALLOW" if rule.get('RuleAction') == 'allow' else "DENY"
                cidr = rule.get('CidrBlock', 'N/A')
                port_range = self._format_nacl_port_range(rule)
                report.append(f"  - Rule {rule_num}: {action} {protocol} {port_range} from {cidr}")
            
            # Egress Rules
            egress_rules = sorted([r for r in nacl.get('Entries', []) if r.get('Egress', False)], 
                                 key=lambda x: x.get('RuleNumber', 0))
            report.append("\n**Egress Rules:**")
            for rule in egress_rules:
                rule_num = rule.get('RuleNumber', 'N/A')
                protocol = rule.get('Protocol', '-1')
                action = "ALLOW" if rule.get('RuleAction') == 'allow' else "DENY"
                cidr = rule.get('CidrBlock', 'N/A')
                port_range = self._format_nacl_port_range(rule)
                report.append(f"  - Rule {rule_num}: {action} {protocol} {port_range} to {cidr}")
        
        return "\n".join(report)
    
    def _format_port_range(self, rule):
        """Format port range for display"""
        protocol = rule.get('IpProtocol', '-1')
        if protocol == '-1':
            return "All Ports"
        
        from_port = rule.get('FromPort')
        to_port = rule.get('ToPort')
        
        if from_port is None or to_port is None:
            return "All Ports"
        
        if from_port == to_port:
            return f"Port {from_port}"
        else:
            return f"Ports {from_port}-{to_port}"
    
    def _format_nacl_port_range(self, rule):
        """Format port range for NACL display"""
        port_range = rule.get('PortRange', {})
        if not port_range:
            return "All Ports"
        
        from_port = port_range.get('From')
        to_port = port_range.get('To')
        
        if from_port is None or to_port is None:
            return "All Ports"
        
        if from_port == to_port:
            return f"Port {from_port}"
        else:
            return f"Ports {from_port}-{to_port}"


def main():
    parser = argparse.ArgumentParser(description='Visualize AWS Security Groups and NACLs')
    parser.add_argument('--region', default='us-east-1', help='AWS region (default: us-east-1)')
    parser.add_argument('--output', '-o', default='security-visualization.md', 
                       help='Output file (default: security-visualization.md)')
    parser.add_argument('--format', choices=['mermaid', 'report'], default='report',
                       help='Output format: mermaid (diagrams only) or report (full report)')
    parser.add_argument('--source-sg', help='Source Security Group ID for sequence diagram')
    parser.add_argument('--target-sg', help='Target Security Group ID for sequence diagram')
    
    args = parser.parse_args()
    
    try:
        visualizer = SecurityVisualizer(region=args.region)
        visualizer.fetch_all_data()
        
        if args.source_sg and args.target_sg:
            # Generate sequence diagram for specific flow
            output = visualizer.generate_sequence_diagram(args.source_sg, args.target_sg)
        elif args.format == 'mermaid':
            # Generate Mermaid diagrams only
            output = []
            output.append("# Security Groups Diagram")
            output.append(visualizer.generate_security_groups_diagram())
            output.append("\n# Network ACLs Diagram")
            output.append(visualizer.generate_nacls_diagram())
            output = "\n".join(output)
        else:
            # Generate full report
            output = visualizer.generate_detailed_security_report()
        
        # Write to file
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(output)
        
        print(f"\n✓ Visualization saved to {args.output}")
        print(f"  Format: {args.format}")
        print(f"  Region: {args.region}")
        
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == '__main__':
    exit(main())

