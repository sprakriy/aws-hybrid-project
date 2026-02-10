# 1. Get the Endpoint ID (starts with cvpn-endpoint-...)
ENDPOINT_ID=$(aws ec2 describe-client-vpn-endpoints --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' --output text --region us-east-1)

# 2. Export the config file
aws ec2 export-client-vpn-client-configuration \
    --client-vpn-endpoint-id $ENDPOINT_ID \
    --output text --region us-east-1 > rds-lab-vpn.ovpn
