#transfer data from S3 to EBS

library(aws.s3)
library(aws.ec2metadata)

#set credentials ----

#list IAM roles in instance
metadata$iam_role_names()

#get specified rolename (if only 1 leave at 1)
cred.role <- metadata$iam_role_names()[1]

#this works if running R from within an EC2 instance
Sys.setenv("AWS_ACCESS_KEY_ID" = metadata$iam_role(role = cred.role)$AccessKeyId,
           "AWS_SECRET_ACCESS_KEY" = metadata$iam_role(role = cred.role)$SecretAccessKey,
           #"AWS_DEFAULT_REGION" = "eu-west-1",
           "AWS_SESSION_TOKEN" = metadata$iam_role(role = cred.role)$Token)

#download ----

#list all buckets you have access to
bucketlist()


#list contents of a bucket
aws.s3::get_bucket(bucket = "data.defra.gov.uk", check_region = FALSE)$Contents

aws.s3::get_bucket(bucket = "ne-working", check_region = FALSE)

#dataframe of contents of a bucket
contents <- aws.s3::get_bucket_df(bucket = "ne-working", check_region = FALSE)

#save a file from S3 to project
save_object("enPeatDepthModel/scratch.Rmd", file = "scripts/scratch_cp.Rmd", bucket = "ne-stats-data")

#load into R ----

#load an object
get_object()

#upload ----
aws.s3::s3save()


####in terminal
#if terminal doesn't load, Tools>GlobalOptions>Terminal turn off websockets
#instance needs to have awscli installed: 
sudo apt-get install awscli 
aws configure
#(prob need to ssh into it as rstudio user doesn't have sudo access)
# pwd
# cd /home/rstudio/enPeatDepthModel/data
# pwd
aws s3 ls
#to copy entire folder
aws s3 sync s3://ne-working/research-evidence/NE20180227_BatConsPlans/ /home/rstudio/BatConsPlans_SW/data
aws s3 sync s3://ne-working/research-evidence/NE20180227_BatConsPlans/boundaries /home/rstudio/BatConsPlans_SW/data/boundaries
aws s3 sync s3://ne-working/research-evidence/NE20180227_BatConsPlans/terrain /home/rstudio/BatConsPlans_SW/data/predictors/terrain
aws s3 sync s3://ne-working/research-evidence/NE20180227_BatConsPlans/observations /home/rstudio/BatConsPlans_SW/data/observations
  