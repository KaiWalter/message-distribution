@minLength(1)
@maxLength(64)
@description('Name of the environment (which is used to generate a short unqiue hash used in all resources).')
param envName string

@minLength(1)
@maxLength(64)
@description('Name of the container app.')
param appName string

@minLength(1)
@description('Primary location for all resources')
param location string

param imageName string

module acafBase 'acafbase.bicep' = {
  name: 'acafBase-RecvStd'
  params: {
    appName: appName
    envName: envName
    location: location
    imageName: imageName
  }
}
