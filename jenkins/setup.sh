#!/bin/bash

# Jenkins Setup Script for Library of Alexandria
# This script helps set up Jenkins with required plugins and configurations

set -e

echo "🚀 Setting up Jenkins for Library of Alexandria..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Jenkins is running
check_jenkins() {
    echo -e "${YELLOW}Checking Jenkins status...${NC}"
    if ! curl -s http://localhost:8080 > /dev/null; then
        echo -e "${RED}❌ Jenkins is not running on localhost:8080${NC}"
        echo "Please start Jenkins first:"
        echo "  - Docker: docker run -p 8080:8080 -p 50000:50000 jenkins/jenkins:lts"
        echo "  - Service: sudo systemctl start jenkins"
        exit 1
    fi
    echo -e "${GREEN}✅ Jenkins is running${NC}"
}

# Install required plugins
install_plugins() {
    echo -e "${YELLOW}Installing required Jenkins plugins...${NC}"
    
    JENKINS_URL="http://localhost:8080"
    
    # List of required plugins
    PLUGINS=(
        "pipeline-stage-view"
        "docker-workflow"
        "maven-plugin"
        "git"
        "workspace-cleanup"
        "sonar"
        "dependency-check-jenkins-plugin"
        "htmlpublisher"
        "slack"
        "email-ext"
        "junit"
        "jacoco"
        "performance"
        "ssh-agent"
        "publish-over-ssh"
        "build-timeout"
        "timestamper"
        "ws-cleanup"
        "ant"
        "gradle"
        "workflow-aggregator"
        "github-branch-source"
        "pipeline-github-lib"
        "pipeline-graph-analysis"
        "blueocean"
    )
    
    echo "Required plugins:"
    printf '%s\n' "${PLUGINS[@]}"
    
    echo ""
    echo "🔧 Please install these plugins manually in Jenkins:"
    echo "1. Go to: Manage Jenkins → Manage Plugins"
    echo "2. Go to 'Available' tab"
    echo "3. Search and install each plugin from the list above"
    echo "4. Restart Jenkins after installation"
}

# Create sample job configuration
create_sample_job() {
    echo -e "${YELLOW}Creating sample job configuration...${NC}"
    
    cat > jenkins-job-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.41">
  <description>Library of Alexandria CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger plugin="github@1.34.1">
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
    <hudson.model.ParametersDefinitionProperty>
      <parameterDefinitions>
        <hudson.model.ChoiceParameterDefinition>
          <name>ENVIRONMENT</name>
          <description>Target environment for deployment</description>
          <choices class="java.util.Arrays$ArrayList">
            <a class="string-array">
              <string>dev</string>
              <string>staging</string>
              <string>production</string>
            </a>
          </choices>
        </hudson.model.ChoiceParameterDefinition>
        <hudson.model.BooleanParameterDefinition>
          <name>SKIP_TESTS</name>
          <description>Skip test execution</description>
          <defaultValue>false</defaultValue>
        </hudson.model.BooleanParameterDefinition>
      </parameterDefinitions>
    </hudson.model.ParametersDefinitionProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.87">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.2">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/Robin-Trimpeneers/LibraryOfAlexandria.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

    echo -e "${GREEN}✅ Created jenkins-job-config.xml${NC}"
    echo "Import this configuration in Jenkins:"
    echo "1. Go to: New Item → Pipeline"
    echo "2. Name: 'Library-of-Alexandria'"
    echo "3. Configure → Pipeline → Pipeline script from SCM"
    echo "4. Repository URL: https://github.com/Robin-Trimpeneers/LibraryOfAlexandria.git"
    echo "5. Script Path: Jenkinsfile"
}

# Setup credentials template
setup_credentials() {
    echo -e "${YELLOW}Setting up credentials template...${NC}"
    
    cat > jenkins-credentials-setup.md << 'EOF'
# Jenkins Credentials Setup

Configure these credentials in Jenkins (Manage Jenkins → Manage Credentials → Global → Add Credentials):

## 1. Database Credentials
- ID: `mysql-credentials`
- Type: Username with password
- Username: `appuser`
- Password: `[your-mysql-password]`

## 2. JWT Secret
- ID: `jwt-secret`
- Type: Secret text
- Secret: `[your-jwt-secret-key-min-32-chars]`

## 3. Google API Key
- ID: `google-api-key`
- Type: Secret text
- Secret: `[your-google-books-api-key]`

## 4. Docker Hub Credentials
- ID: `docker-hub-credentials`
- Type: Username with password
- Username: `[your-dockerhub-username]`
- Password: `[your-dockerhub-password]`

## 5. SonarQube Token
- ID: `sonar-token`
- Type: Secret text
- Secret: `[your-sonarqube-token]`

## 6. Server Configurations
- ID: `dev-server-config`
- Type: Username with password
- Username: `[dev-server-host-or-ip]`
- Password: `[ssh-password-or-key]`

- ID: `staging-server-config`
- Type: Username with password
- Username: `[staging-server-host-or-ip]`
- Password: `[ssh-password-or-key]`

- ID: `prod-server-config`
- Type: Username with password
- Username: `[prod-server-host-or-ip]`
- Password: `[ssh-password-or-key]`
EOF

    echo -e "${GREEN}✅ Created jenkins-credentials-setup.md${NC}"
}

# Setup global tools
setup_tools() {
    echo -e "${YELLOW}Setting up global tools configuration...${NC}"
    
    cat > jenkins-tools-setup.md << 'EOF'
# Jenkins Global Tools Configuration

Configure these tools in Jenkins (Manage Jenkins → Global Tool Configuration):

## Maven Configuration
- Name: `Maven-3.9.4`
- Install automatically: ✅
- Version: 3.9.4

## JDK Configuration
- Name: `JDK-21`
- Install automatically: ✅
- Installer: Install from adoptium.net
- Version: jdk-21+35

## Docker
- Ensure Docker is installed on Jenkins server
- Add jenkins user to docker group:
  ```bash
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins
  ```

## SonarQube Scanner (if using SonarQube)
- Name: `SonarQube Scanner`
- Install automatically: ✅
- Version: Latest

## Git
- Name: `Default`
- Path to Git executable: `git`
EOF

    echo -e "${GREEN}✅ Created jenkins-tools-setup.md${NC}"
}

# Main execution
main() {
    echo "🏛️ Library of Alexandria - Jenkins Setup"
    echo "========================================"
    
    check_jenkins
    install_plugins
    create_sample_job
    setup_credentials
    setup_tools
    
    echo ""
    echo -e "${GREEN}🎉 Jenkins setup completed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Install the required plugins listed above"
    echo "2. Configure global tools (see jenkins-tools-setup.md)"
    echo "3. Add credentials (see jenkins-credentials-setup.md)"
    echo "4. Create a new pipeline job using the generated configuration"
    echo "5. Test the pipeline with a sample build"
    echo ""
    echo "📚 Documentation: jenkins/README.md"
    echo "🚀 Happy building!"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi