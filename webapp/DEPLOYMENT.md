# AWS Amplify Gen 2 Deployment Guide

## Overview
This guide shows how to deploy the Kinesis Pipeline Web App using AWS Amplify Gen 2.

## Prerequisites
- AWS Account
- AWS CLI configured
- Node.js installed

## Method 1: AWS Console (Recommended)

### Step 1: Prepare Repository
1. Ensure your code is in a Git repository (GitHub, GitLab, etc.)
2. Make sure the repository is public or connected to AWS

### Step 2: AWS Amplify Console
1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Click "New app" → "Host web app"
3. Choose your Git provider and connect your repository
4. Select the branch to deploy (usually `main` or `master`)

### Step 3: Configure Build Settings
Use these build settings:

```yaml
version: 2
frontend:
  phases:
    preBuild:
      commands:
        - npm install
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .
    files:
      - '**/*'
      - '!node_modules/**/*'
      - '!amplify/**/*'
  cache:
    paths:
      - node_modules/**/*
```

### Step 4: Environment Variables
Add these environment variables in Amplify Console:
- `API_GATEWAY_URL`: Your API Gateway URL
- `NODE_ENV`: `production`

### Step 5: Deploy
1. Click "Save and deploy"
2. Amplify will build and deploy your app
3. You'll get a URL like: `https://main.xxxxx.amplifyapp.com`

## Method 2: Amplify CLI (Advanced)

### Step 1: Install Amplify CLI
```bash
npm install -g @aws-amplify/cli@latest
```

### Step 2: Configure Amplify
```bash
amplify configure
```

### Step 3: Initialize Amplify
```bash
cd webapp
amplify init
```

### Step 4: Add Hosting
```bash
amplify add hosting
```

### Step 5: Deploy
```bash
amplify publish
```

## Method 3: GitHub Actions (CI/CD)

### Step 1: Create GitHub Actions Workflow
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Amplify
on:
  push:
    branches: [ main ]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Deploy to Amplify
      uses: aws-actions/amplify-deploy@v1
      with:
        app-id: ${{ secrets.AMPLIFY_APP_ID }}
        branch-name: main
        region: us-east-1
```

### Step 2: Set GitHub Secrets
- `AMPLIFY_APP_ID`: Your Amplify app ID
- `AWS_ACCESS_KEY_ID`: AWS access key
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

## Environment Variables

Set these in Amplify Console:

| Variable | Value | Description |
|----------|-------|-------------|
| `API_GATEWAY_URL` | `https://your-api-gateway-url/submit` | Your API Gateway endpoint |
| `NODE_ENV` | `production` | Environment setting |

## Custom Domain (Optional)

1. Go to Amplify Console → Your App → Domain Management
2. Add your custom domain
3. Configure DNS settings
4. Wait for SSL certificate (up to 24 hours)

## Monitoring

- **Build Logs**: View in Amplify Console
- **Access Logs**: Available in CloudWatch
- **Performance**: Use AWS CloudWatch metrics

## Troubleshooting

### Common Issues:
1. **Build Fails**: Check build logs in Amplify Console
2. **Environment Variables**: Ensure they're set correctly
3. **API Gateway URL**: Verify the URL is accessible
4. **CORS Issues**: Check API Gateway CORS settings

### Support:
- [Amplify Documentation](https://docs.amplify.aws/)
- [Amplify Community](https://github.com/aws-amplify/amplify-js)
- [AWS Support](https://aws.amazon.com/support/)

## Next Steps

After deployment:
1. Test the web app functionality
2. Update the API Gateway URL if needed
3. Monitor performance and logs
4. Set up custom domain (optional)
5. Configure monitoring and alerts 