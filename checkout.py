import os
import time
import sys
import boto3


def main(args):
    asg_name = os.environ.get('ASG_NAME')
    assert asg_name is not None, 'Must set ASG_NAME in environment.'

    autoscaling = boto3.client('autoscaling')

    try: 
        refresh = autoscaling.describe_instance_refreshes(
            AutoScalingGroupName=asg_name, 
            MaxRecords=1
        )['InstanceRefreshes'][0]
    except KeyError:
        print('Trigger at least one Instance Refresh first.')
        sys.exit(os.EX_UNAVAILABLE)

    while refresh['Status'] not in ['Successful', 'Failed', 'Cancelled']: 
        print(
            f"Instance Refresh {refresh['Status']} "
            f"[{refresh.get('PercentageComplete', 0)}%]: "
            f"{refresh.get('StatusReason', '')}"
        )
        time.sleep(5)
        refresh = autoscaling.describe_instance_refreshes(
            AutoScalingGroupName=asg_name, 
            InstanceRefreshIds=[refresh['InstanceRefreshId']]
        )['InstanceRefreshes'][0]

    print(f"Instance Refresh {refresh['Status']} at {refresh['EndTime']}")


if __name__ == '__main__':
    main(args=[])
