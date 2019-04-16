properties([buildDiscarder(logRotator(numToKeepStr: '8'))])

def label = "petclinic-${UUID.randomUUID().toString()}"

def projectname = "spring-petclinic-microservices"

def revision = "2.1.3-SNAPSHOT"
def dockerTag = env.BRANCH_NAME
def targetNS = "preprod"
def changeCause = "date"

def credentials = [usernamePassword(credentialsId: 'jcsirot.docker.devoxxfr.chelonix.org', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]

def deptrackApiKey = [string(credentialsId: 'deptrackapikey', variable:'DEPTRACK_APIKEY')]

podTemplate(label: label, yaml: """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: ci-jenkins
  containers:
  - name: docker
    image: docker:19.03-rc
    command: ['cat']
    tty: true
    volumeMounts:
    - name: dockersock
      mountPath: /var/run/docker.sock
  volumes:
  - name: dockersock
    hostPath:
      path: /var/run/docker.sock
"""
  ) {

  node(label) {
    checkout scm
    container('docker') {
      stage("Build images") {
        sh "docker version"
        sh "docker build -t builder:${BUILD_TAG} --target builder --build-arg REVISION=${revision} ."
        sh "docker build -t base:${BUILD_TAG} --target base --build-arg REVISION=${revision} ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-admin-server:${dockerTag} -f spring-petclinic-admin-server/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=9090 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-customers-service:${dockerTag} -f spring-petclinic-customers-service/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8081 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-vets-service:${dockerTag} -f spring-petclinic-vets-service/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8081 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-visits-service:${dockerTag} -f spring-petclinic-visits-service/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8081 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-config-server:${dockerTag} -f spring-petclinic-config-server/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8888 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-discovery-server:${dockerTag} -f spring-petclinic-discovery-server/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8761 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-api-gateway:${dockerTag} -f spring-petclinic-api-gateway/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=8081 ."
        sh "docker build -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-hystrix-dashboard:${dockerTag} -f spring-petclinic-hystrix-dashboard/Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg EXPOSED_PORT=7979 ."

        dir("docker/grafana") {
          sh "docker build -f Dockerfile -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-grafana:${dockerTag} ."
        }
        dir("docker/prometheus") {
          sh "docker build -f Dockerfile -t docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-prometheus:${dockerTag} ."
        }
      }
      stage("OWASP Dependency-Track") {
        withCredentials(deptrackApiKey) {        
          sh "docker build -f deptrack.Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg DEPTRACK_MAVEN_GOAL='org.cyclonedx:cyclonedx-maven-plugin:makeAggregateBom' --build-arg DEPTRACK_HOST_URL=${env.DEPTRACK_HOST_URL} --build-arg DEPTRACK_PROJECT_NAME=${projectname} --build-arg DEPTRACK_APIKEY=${DEPTRACK_APIKEY} ."
        }
      }
      stage("Sonar Analysis") {
        withSonarQubeEnv('sonarqube') {
          sh "docker build -f sonar.Dockerfile --build-arg BASE_ID=${BUILD_TAG} --build-arg REVISION=${revision} --build-arg SONAR_MAVEN_GOAL=${SONAR_MAVEN_GOAL} --build-arg SONAR_HOST_URL=${SONAR_HOST_URL} --build-arg SONAR_AUTH_TOKEN=${SONAR_AUTH_TOKEN} ."
        }
      }
      stage("Push images") {
        withCredentials(credentials) {
          sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASSWORD} docker.devoxxfr.chelonix.org"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-admin-server:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-customers-service:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-vets-service:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-visits-service:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-config-server:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-discovery-server:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-api-gateway:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-hystrix-dashboard:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-grafana:${dockerTag}"
          sh "docker push docker.devoxxfr.chelonix.org/jcsirot/spring-petclinic-prometheus:${dockerTag}"
        }
      }
      if (env.TAG_NAME != null) {
        if (env.TAG_NAME ==~ /v[0-9]\.[0-9]\.[0-9]/) {
          stage ("Deploy to Prod") {
            echo "Deploying app to production"
            targetNS = "prod"
          }
        } else {
          stage ("Deploy to Preprod") {
            echo "Deploying app to pre-production"
          }
        }
      } else {
        /*
        this is an upgrade deployment process
        you need to install the helm chart first for "prod and preprod"
        helm install --name petclinic-preprod helm/charts/spring-petclinic-microservices \
                     -f deployment-configs/preprod/values.yaml '--namespace=petclinic-preprod' \
                     --set 'image.tag=2.1.3-compose-SNAPSHOT'
        
        */
        sh """
          wget -O kubectl https://storage.googleapis.com/kubernetes-release/release/v1.14.0/bin/linux/amd64/kubectl
          chmod +x ./kubectl
        """
        sh """
          wget -qO- https://kubernetes-helm.storage.googleapis.com/helm-v2.13.1-linux-amd64.tar.gz | tar xvz
          ./linux-amd64/helm version
          echo "targetNS:${targetNS}"
          ./linux-amd64/helm upgrade ${targetNS} helm/charts/spring-petclinic-microservices -f deployment-configs/${targetNS}/values.yaml --namespace=petclinic-${targetNS} --set image.tag=${dockerTag} --set image.changeCause=${changeCause}
        """
        echo "Skipping app deployment since no tag has been found"
      }
    }
  }
}
