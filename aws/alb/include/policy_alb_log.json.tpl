{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Allow update ALB log",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${bucket_name}/*",
      "Principal": {
        "AWS": [
          "${aws_elb_account_id}"
        ]
      }
    }
  ]
}
