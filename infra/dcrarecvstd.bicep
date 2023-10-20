@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string

param entityNameForScaling string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string
param acrPullId string
param kvGetId string

param daprApiToken string
param daprGrpcEndpoint string
param daprPort string

module daprBase 'dcrabase.bicep' = {
  name: 'dcraBase-RecvStd'
  params: {
    appName: appName
    entityNameForScaling: entityNameForScaling
    envName: envName
    location: location
    imageName: imageName
    kvGetId: kvGetId
    acrPullId: acrPullId
    daprApiToken: daprApiToken
    daprGrpcEndpoint: daprGrpcEndpoint
    daprPort: daprPort
  }
}
