param sites_funchttpaca9_name string = 'funchttpaca9'
param managedEnvironments_funcappenv_externalid string = '/subscriptions/853049fd-4889-45b6-aad9-f3f54421399c/resourceGroups/kw-messdist-rg/providers/Microsoft.App/managedEnvironments/cae-ggnx3xbeyyqzy'

resource sites_funchttpaca9_name_resource 'Microsoft.Web/sites@2022-09-01' = {
  name: sites_funchttpaca9_name
  location: 'North Europe'
  kind: 'functionapp'
  properties: {
    managedEnvironmentId: managedEnvironments_funcappenv_externalid
    storageAccountRequired: false
    siteConfig:{
      linuxFxVersion: 'DOCKER|ancientitguy/azurefunctionsimage:latest'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=stggnx3xbeyyqzy;AccountKey=yJd/E/UH9Qf33ag112VbFLyL2E2SpawXqbXQ03WSql/ituV7/xw4Rrxoz4rRDbaoSWfidY/papmV+AStffjGNw=='
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'ancientitguy'
        }
      ]
}
  }
}

// {
//   kind: 'functionapp,linux,container,azurecontainerapps'
//   location: 'northeurope'
//   properties: {
//     siteConfig: {
//       linuxFxVersion: 'DOCKER|ancientitguy/azurefunctionsimage:latest'
//       appSettings: [
//         {
//           name: 'AzureWebJobsStorage'
//           value: 'DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=stggnx3xbeyyqzy;AccountKey=yJd/E/UH9Qf33ag112VbFLyL2E2SpawXqbXQ03WSql/ituV7/xw4Rrxoz4rRDbaoSWfidY/papmV+AStffjGNw=='
//         }
//         {
//           name: 'DOCKER_REGISTRY_SERVER_URL'
//           value: 'ancientitguy'
//         }
//       ]
//     }
//     name: 'azurefunctionsimage'
//     managedEnvironmentId: '/subscriptions/853049fd-4889-45b6-aad9-f3f54421399c/resourceGroups/kw-messdist-rg/providers/Microsoft.App/managedEnvironments/cae-ggnx3xbeyyqzy'
//   }
// }

// resource sites_funchttpaca9_name_web 'Microsoft.Web/sites/config@2022-09-01' = {
//   parent: sites_funchttpaca9_name_resource
//   name: 'web'
//   location: 'North Europe'
//   properties: {
//     linuxFxVersion: 'DOCKER|docker.io/ancientitguy/azurefunctionsimage:latest'
//     appSettings: [
//       {
//         name: 'AzureWebJobsStorage'
//         value: ''
//       }
//       {
//         name: 'DOCKER_REGISTRY_SERVER_URL'
//         value: ''
//       }
//       {
//         name: 'WEBSITE_AUTH_ENCRYPTION_KEY'
//         value: ''
//       }
//       {
//         name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
//         value: ''
//       }
//     ]
//     metadata: []
//     scmType: 'None'
//   }
// }


