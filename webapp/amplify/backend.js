// Amplify Gen 2 Backend Configuration
// This file defines the backend resources for the web app

export const backend = {
  name: 'kinesis-webapp-backend',
  
  // Define hosting configuration
  hosting: {
    name: 'webapp-hosting',
    type: 'static',
    config: {
      sourcePath: '.',
      buildPath: '.',
      buildCommand: 'npm run build',
      startCommand: 'npm start'
    }
  }
};

export default backend; 