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
        self.region = region
        self.security_groups = {}
        self.nacls = {}
        self.vpcs = {}
        
    def fetch_all_data(self):
        """Fetch all security groups, NACLs, and VPCs"""
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
        
        print(f"  ✓ Found {len(self.vpcs)} VPCs, {len(self.security_groups)} Security Groups, {len(self.nacls)} NACLs")
    
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
                
                mermaid.append(f"        SG_{sg_id.replace('-', '_')}[\"SG: {sg_name}<br/>{sg_id}<br/>Ingress: {ingress_count} | Egress: {egress_count}\"]")
            
            mermaid.append("    end")
        
        # Add connections based on security group references
        mermaid.append("")
        mermaid.append("    %% Security Group References")
        for sg_id, sg in self.security_groups.items():
            sg_name = sg_id.replace('-', '_')
            
            # Check ingress rules for SG references
            for rule in sg.get('IpPermissions', []):
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    referenced_sg = user_id_group_pair.get('GroupId')
                    if referenced_sg and referenced_sg in self.security_groups:
                        ref_name = referenced_sg.replace('-', '_')
                        port_range = self._format_port_range(rule)
                        mermaid.append(f"    SG_{ref_name} -->|\"{port_range}\"| SG_{sg_name}")
            
            # Check egress rules for SG references
            for rule in sg.get('IpPermissionsEgress', []):
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    referenced_sg = user_id_group_pair.get('GroupId')
                    if referenced_sg and referenced_sg in self.security_groups:
                        ref_name = referenced_sg.replace('-', '_')
                        port_range = self._format_port_range(rule)
                        mermaid.append(f"    SG_{sg_name} -->|\"{port_range}\"| SG_{ref_name}")
        
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
            
            source_name = source_sg.get('GroupName', source_sg_id)
            target_name = target_sg.get('GroupName', target_sg_id)
            
            mermaid.append(f"    participant Source as \"{source_name}<br/>{source_sg_id}\"")
            mermaid.append(f"    participant Target as \"{target_name}<br/>{target_sg_id}\"")
            mermaid.append("")
            
            # Check if source can reach target
            can_reach = False
            for rule in target_sg.get('IpPermissions', []):
                for user_id_group_pair in rule.get('UserIdGroupPairs', []):
                    if user_id_group_pair.get('GroupId') == source_sg_id:
                        port_range = self._format_port_range(rule)
                        protocol = rule.get('IpProtocol', '-1')
                        mermaid.append(f"    Source->>Target: {protocol} {port_range}")
                        can_reach = True
            
            if not can_reach:
                mermaid.append("    Source-->>Target: ❌ Blocked")
        else:
            # General overview
            mermaid.append("    participant Internet")
            mermaid.append("    participant VPC")
            
            # Add security groups
            for sg_id, sg in list(self.security_groups.items())[:10]:  # Limit to first 10 for readability
                sg_name = sg.get('GroupName', sg_id)
                mermaid.append(f"    participant SG_{sg_id.replace('-', '_')} as \"{sg_name}\"")
            
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
            
            # Ingress Rules
            report.append("\n**Ingress Rules:**")
            for rule in sg.get('IpPermissions', []):
                protocol = rule.get('IpProtocol', '-1')
                port_range = self._format_port_range(rule)
                
                # CIDR blocks
                for cidr in rule.get('IpRanges', []):
                    report.append(f"  - Allow {protocol} {port_range} from {cidr.get('CidrIp', 'N/A')}")
                
                # Security Group references
                for sg_ref in rule.get('UserIdGroupPairs', []):
                    ref_sg_id = sg_ref.get('GroupId', 'N/A')
                    ref_sg_name = self.security_groups.get(ref_sg_id, {}).get('GroupName', ref_sg_id) if ref_sg_id in self.security_groups else ref_sg_id
                    report.append(f"  - Allow {protocol} {port_range} from SG: {ref_sg_name} ({ref_sg_id})")
            
            # Egress Rules
            report.append("\n**Egress Rules:**")
            for rule in sg.get('IpPermissionsEgress', []):
                protocol = rule.get('IpProtocol', '-1')
                port_range = self._format_port_range(rule)
                
                for cidr in rule.get('IpRanges', []):
                    report.append(f"  - Allow {protocol} {port_range} to {cidr.get('CidrIp', 'N/A')}")
                
                for sg_ref in rule.get('UserIdGroupPairs', []):
                    ref_sg_id = sg_ref.get('GroupId', 'N/A')
                    ref_sg_name = self.security_groups.get(ref_sg_id, {}).get('GroupName', ref_sg_id) if ref_sg_id in self.security_groups else ref_sg_id
                    report.append(f"  - Allow {protocol} {port_range} to SG: {ref_sg_name} ({ref_sg_id})")
        
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

