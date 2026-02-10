# Get your endpoint ID first
ENDPOINT_ID=$(aws ec2 describe-client-vpn-endpoints --query 'ClientVpnEndpoints[0].ClientVpnEndpointId' --output text --region us-east-1)

# Check active connections
aws ec2 describe-client-vpn-connections --client-vpn-endpoint-id $ENDPOINT_ID --region us-east-1
