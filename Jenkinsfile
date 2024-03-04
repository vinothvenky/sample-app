pipeline {

    agent any

    environment{

        AWS_ACCESS_KEY_ID     = credentials('AWS_ACCESS_KEY_ID')

        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')

        ECS_CLUSTER = 'pythonappsample'

        ECS_SERVICE = 'pythonsampleappsvc'

    }

    stages {

        stage('Checkout') {

            steps {

                git branch: 'main', url: 'https://github.com/yourrepo/sample-app.git'

            }

        }

        stage('build') {

            steps {

                sh 'aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 339712891234.dkr.ecr.us-east-1.amazonaws.com'

                sh 'docker build -t python-app .'

                sh 'docker tag python-app:latest 339712891234.dkr.ecr.us-east-1.amazonaws.com/python-app:latest'

                sh 'docker push 339712891234.dkr.ecr.us-east-1.amazonaws.com/python-app:latest'

            }

        }

        stage('deploy to ecs') {

            steps {

                withAWS(credentials: 'awscreds',region: 'us-east-1'){

                    sh 'aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --force-new-deployment'

                }

            }

        }

    }

}