# VPC Configuration
The module define a simple vpc in specified region, it provides public and private networks, the default setting have a internet gateway and the route for public subnet traffic go through internet.

## Required Parameter
- region
- availability zones
- vpc cidr block
- public subnets cidr block
- private subnets cidr block
- project name