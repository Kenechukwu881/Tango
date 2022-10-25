/* terraform {

  backend "s3" {

    # Replace this with your bucket name!

    bucket         = "tango-s3"
    key            = "terraform.tfstate"
    region         = "us-east-1"

    # Replace this with your DynamoDB table name!

    dynamodb_table = "tango_dynamodb"
    encrypt        = false
  }
} */