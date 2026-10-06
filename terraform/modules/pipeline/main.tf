#Codestar connection

resource "aws_codestarconnections_connection" "this" {
    name = "todo-app-codestar-connection"
    provider_type = "GitHub"
}

#S3 bucket

resource "aws_s3_bucket" "pipeline_artifacts" {
    bucket = "todo-app-pipeline-artifacts-${var.aws_account_id}"
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
    bucket = aws_s3_bucket.pipeline_artifacts.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}

#Secret

resource "aws_secretsmanager_secret" "github_token" {
    name = "todo-app/github-token-6-10-2026"
}

resource "aws_secretsmanager_secret_version" "github_token" {
  secret_id = aws_secretsmanager_secret.github_token.id
  secret_string = var.github_token
}

#codepipeline and codebuild roles

resource "aws_iam_role" "codepipeline" {
    name = "${var.name}-codepipeline-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "codepipeline.amazonaws.com" }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy" "codepipeline" {
    name = "${var.name}-codepipeline-policy"
    role = aws_iam_role.codepipeline.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Action = ["s3:GetObject", "s3:PutObject", "s3:GetBucketVersioning"]
            Resource = ["${aws_s3_bucket.pipeline_artifacts.arn}", "${aws_s3_bucket.pipeline_artifacts.arn}/*"]
        },
        {
            Effect = "Allow"
            Action = ["codestar-connections:UseConnection"]
            Resource = aws_codestarconnections_connection.this.arn
        },
        {
            Effect = "Allow"
            Action = ["codebuild:BatchGetBuilds", "codebuild:StartBuild","logs:CreateLogStream"]
            Resource = "*"
        }]
    })
}

resource "aws_iam_role" "codebuild" {
  name = "${var.name}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = { Service = "codebuild.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  name = "${var.name}-codebuild-role"
  role = aws_iam_role.codebuild.id

policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.pipeline_artifacts.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage",
          "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.github_token.arn
      }
    ]
  })
}


#codebuild and pipeline

resource "aws_codebuild_project" "backend" {
    name = "${var.name}-backend-build"
    service_role = aws_iam_role.codebuild.arn

    source {
      type = "CODEPIPELINE"
      buildspec = "todo-app/backend/buildspec.yaml"
    }

    environment {
      compute_type = "BUILD_GENERAL1_SMALL"
      image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
      type = "LINUX_CONTAINER"
      privileged_mode = true

      environment_variable {
        name = "ECR_REPO_URI"
        value = "292578125952.dkr.ecr.ap-south-1.amazonaws.com/todo-app-backend"
      }

      environment_variable {
        name = "GITHUB_TOKEN"
        value = aws_secretsmanager_secret.github_token.arn
        type = "SECRETS_MANAGER"
      }
    }

    artifacts {
      type = "CODEPIPELINE"
    }
}

resource "aws_codebuild_project" "frontend" {
  name = "${var.name}-frontend-build"
  service_role = aws_iam_role.codebuild.arn

  source {
    type = "CODEPIPELINE"
    buildspec = "todo-app/frontend/buildspec.yaml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    type = "LINUX_CONTAINER"
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    privileged_mode = true

    environment_variable {
      name = "ECR_REPO_URI"
      value = "292578125952.dkr.ecr.ap-south-1.amazonaws.com/todo-app-frontend" 
    }

    environment_variable {
      name = "GITHUB_TOKEN"
      value = aws_secretsmanager_secret.github_token.arn
      type = "SECRETS_MANAGER"
    }
  }
}

resource "aws_codepipeline" "project" {
    name = "${var.name}-project-codepipeline"
    role_arn = aws_iam_role.codepipeline.arn

    artifact_store {
      location = aws_s3_bucket.pipeline_artifacts.bucket
      type = "S3"
    }

    stage {
      name = "Source"

      action {
        name = "Source"
        category = "Source"
        owner = "AWS"
        version = "1"
        provider = "CodeStarSourceConnection"
        output_artifacts = ["source_output"]

        configuration = {
            ConnectionArn = aws_codestarconnections_connection.this.arn
            FullRepositoryId = "Hasil-21/todo-app-infra-hasil"
            BranchName = "main"
        }
      }
    }

    stage {
      name = "Build-BE"

      action {
        name = "Build"
        category = "Build"
        owner = "AWS"
        version = 1
        provider = "CodeBuild"
        input_artifacts = ["source_output"]
        output_artifacts = ["build_output_BE"]

        configuration = {
          ProjectName = aws_codebuild_project.backend.name
        }
      }
    }

    stage {
      name = "Build-FE"

      action {
        name = "Build"
        category = "Build"
        version = 1
        owner = "AWS"
        provider = "CodeBuild"
        input_artifacts = ["source_output"]
        output_artifacts = ["build_output_FE"]

        configuration = {
          ProjectName = aws_codebuild_project.frontend.name
        } 
      }
    }
}