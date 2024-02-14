@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string
param daprPubSubModel string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string
param acrPullId string
param kvGetId string

module daprBase 'daprbase.bicep' = {
  name: 'daprBase-Distributor'
  params: {
    appName: appName
    envName: envName
    instance: 'ingress'
    daprPubSubModel: daprPubSubModel
    location: location
    imageName: imageName
    kvGetId: kvGetId
    acrPullId: acrPullId
  }
}
