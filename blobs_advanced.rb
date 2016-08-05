#----------------------------------------------------------------------------------
# Microsoft Developer & Platform Evangelism
#
# Copyright (c) Microsoft Corporation. All rights reserved.
#
# THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
# EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
#-------------------------------------------------------------------------------
# The example companies, organizations, products, domain names,
# e-mail addresses, logos, people, places, and events depicted
# herein are fictitious.  No association with any real company,
# organization, product, domain name, email address, logo, person,
# places, or events is intended or should be inferred.
#-------------------------------------------------------------------------------
#
# Azure Storage Blob Sample - Demonstrate how to use the Blob Storage service.
# Blob storage stores unstructured data such as text, binary data, documents or
# media files.
# Blobs can be accessed from anywhere in the world via HTTP or HTTPS.
#
# Documentation References:
#  - What is a Storage Account - http://azure.microsoft.com/en-us/documentation/articles/storage-whatis-account/
#  - Getting Started with Blobs - https://azure.microsoft.com/en-us/documentation/articles/storage-ruby-how-to-use-blob-storage/
#  - Blob Service Concepts - http://msdn.microsoft.com/en-us/library/dd179376.aspx
#  - Blob Service REST API - http://msdn.microsoft.com/en-us/library/dd135733.aspx
#  - Blob Service Ruby API - http://azure.github.io/azure-storage-ruby/
#  - Storage Emulator - http://azure.microsoft.com/en-us/documentation/articles/storage-use-emulator/
#

require './random_string'

# Blob Advanced Samples
class BlobAdvancedSamples
  # Runs all samples for Azure Storage Blob service.
  def run_all_samples(client)
    puts "\n\nAzure Storage Blob advanced sample - Starting."

    blob_service = Azure::Storage::Blob::BlobService.new(client: client)

    puts "\n\n* List containers *\n"
    list_containers(blob_service)

    puts "\n\n* Set Cors *\n"
    cors_rules(blob_service)

    puts "\n\n* Block blob operations*\n"
    block_blob_operations(blob_service)

    puts "\n\n* Copy blob*\n"
    copy_blob(blob_service)

    puts "\n\n* Set Service properties*\n"
    service_properties(blob_service)

    puts "\n\n* Container metadata and properties*\n"
    container_metadata_and_properties(blob_service)

    puts "\n\n* Container access policy*\n"
    container_acl(blob_service)

    puts "\n\n* Blob properties*\n"
    blob_properties(blob_service)

    puts "\n\n* Blob metadata*\n"
    blob_metadata(blob_service)

    puts "\n\nAzure Storage Blob advanced sample - Completed."

  rescue Azure::Core::Http::HTTPError => ex
    if AzureConfig::IS_EMULATED
      puts 'Error occurred in the sample. If you are using the emulator, '\
      "please make sure the emulator is running. #{ex}"
    else
      puts 'Error occurred in the sample. Please make sure the account name'\
      " and key are correct. #{ex}"
    end
  end

  def list_containers(blob_service)
    container_prefix = 'containersample' + RandomString.random_name

    # Create containers
    for i in 0..4
      container_name = container_prefix + i.to_s
      puts "Create a container with name #{container_name}"
      blob_service.create_container(container_name)
    end

    # List all the blobs in the container
    puts "List containers with prefix #{container_prefix}"
    containers = blob_service.list_containers(prefix: container_prefix)
    containers.each do |container|
      puts "Container Name: #{container.name}"
    end

    # Delete the containers
    puts 'Delete Containers'
    for i in 0..4
      container_name = container_prefix + i.to_s
      blob_service.delete_container(container_name)
    end
  end

  def cors_rules(blob_service)
    cors_rule = Azure::Storage::Service::CorsRule.new
    cors_rule.allowed_origins = ['*']
    cors_rule.allowed_methods = %w(POST GET)
    cors_rule.allowed_headers = ['*']
    cors_rule.exposed_headers = ['*']
    cors_rule.max_age_in_seconds = 3600

    puts 'Get Service Properties'

    original_service_properties = blob_service.get_service_properties

    puts 'Overwrite Cors Rules'

    service_properties = Azure::Storage::Service::StorageServiceProperties.new
    service_properties.cors.cors_rules = [cors_rule]

    blob_service.set_service_properties(service_properties)

    puts 'Revert Cors Rules back the original ones'
    # reverting cors rules back to the original ones
    blob_service.set_service_properties(original_service_properties)

    puts 'CORS sample completed'
  end

  # Block Blob Operations
  def block_blob_operations(blob_service)
    file_to_upload = 'HelloWorld.png'
    blob_name = file_to_upload

    block_size = 1024

    # Create an page blob service object
    container_name = 'blockblobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"

    blob_service.create_container(container_name)

    blocks = []

    # Read the file
    puts 'Upload file to block blob'
    File.open file_to_upload, 'rb' do |file|
      while (file_bytes = file.read(block_size))

        block_id = Base64.strict_encode64(RandomString.random_name)
        blob_service.put_blob_block(container_name,
                                    blob_name,
                                    block_id,
                                    file_bytes)

        blocks << [block_id]
      end
    end

    puts 'Commit blocks'
    blob_service.commit_blob_blocks(container_name, blob_name, blocks)

    puts 'List blocks in block blob'
    list_blocks = blob_service.list_blob_blocks(container_name, blob_name)

    list_blocks[:committed].each { |block| puts "Block #{block.name}" }

    puts 'Delete container'
    blob_service.delete_container(container_name)
  end

  def copy_blob(blob_service)
    file_to_upload = 'HelloWorld.png'
    source_blob_name = file_to_upload
    container_name = 'blockblobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Upload file as a block blob
    puts 'Upload BlockBlob'

    # Get full path on drive to file_to_upload
    content = IO.binread(File.expand_path(file_to_upload))
    blob_service.create_block_blob(container_name, source_blob_name, content)

    target_blob_name = 'target.png'
    puts 'Copy blob'
    blob_service.copy_blob(container_name, target_blob_name, container_name,
                           source_blob_name)

    puts 'Get target blob'
    target_blob_properties = blob_service.get_blob_properties(container_name,
                                                              target_blob_name)

    puts 'Copy properties status: ' + target_blob_properties
                                      .properties[:copy_status]

    if target_blob_properties.properties[:copy_status] == 'pending'
      puts 'Abort copy'
      blob_service.abort_copy_blob(container_name, target_blob_name, copy_id)
    end

    # Delete the container
    puts 'Delete Container'
    blob_service.delete_container(container_name)
  end

  def service_properties(blob_service)
    # get service properties
    puts 'Get Service Properties'

    original_properties = blob_service.get_service_properties

    # set service properties
    puts 'Overwrite Service Properties'

    properties = Azure::Storage::Service::StorageServiceProperties.new
    properties.logging.delete = true
    properties.logging.read = true
    properties.logging.write = true
    properties.logging.retention_policy.enabled = true
    properties.logging.retention_policy.days = 10

    blob_service.set_service_properties properties

    # reverting service properties back to the original ones
    puts 'Revert Service Properties back the original ones'
    blob_service.set_service_properties original_properties

    puts 'Service Properties sample completed'
  end

  def container_metadata_and_properties(blob_service)
    # Create an page blob service object
    container_name = 'blobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"

    blob_service.create_container(container_name)

    container_metadata = { 'MetadataKey1' => 'MetaDataValue1',
                           'MetadataKey2' => 'MetaDataValue2' }

    blob_service.set_container_metadata container_name, container_metadata

    puts 'Get container metadata'
    result = blob_service.get_container_metadata container_name

    puts "Metadata:\n"
    result.metadata.each do |key, value|
      puts "#{key}: #{value}\n"
    end

    puts 'Get container porperties'
    result = blob_service.get_container_properties container_name

    puts "Container properties:\n"
    result.properties.each do |key, value|
      puts "#{key}: #{value}\n"
    end

    puts 'Delete container'
    blob_service.delete_container(container_name)

    puts 'Container metadata and properties sample completed'
  end

  def container_acl(blob_service)
    container_name = 'blobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"

    blob_service.create_container(container_name)

    puts 'Set container acl'
    public_access_level = 'container'
    blob_service.set_container_acl container_name, public_access_level

    puts 'Get container acl'
    result = blob_service.get_container_acl container_name

    puts "access level: #{result[0].public_access_level}"

    puts 'Delete container'
    blob_service.delete_container(container_name)

    puts 'Container acl sample completed'
  end

  def blob_properties(blob_service)
    blob = 'HelloWorld.png'
    container_name = 'blockblobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Upload file as a block blob
    puts 'Create blob'
    blob_service.create_block_blob(container_name, blob,
                                   IO.binread(File.expand_path(blob)))

    puts 'Get blob properties'
    result = blob_service.get_blob_properties(container_name, blob)

    puts "Blob Properties:\n"
    result.properties.each do |key, value|
      puts "#{key}: #{value}\n"
    end

    properties = {
      content_type: 'application/my-special-format',
      content_encoding: 'utf-16',
      content_language: 'klingon',
      cache_control: 'max-age=1296000'
    }

    puts 'Set blob properties'
    blob_service.set_blob_properties(container_name, blob, properties)

    puts 'Delete blob'
    blob_service.delete_blob(container_name, blob)

    puts 'Blob properties sample completed'
  end

  def blob_metadata(blob_service)
    file_to_upload = 'HelloWorld.png'
    blob_name = file_to_upload
    container_name = 'blobcontainer' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"

    blob_service.create_container(container_name)

    metadata = { 'MetadataKey1' => 'MetaDataValue1',
                 'MetadataKey2' => 'MetaDataValue2' }

    # Upload file as a block blob
    puts 'Create blob'
    blob_service.create_block_blob(container_name, blob_name,
                                   IO.binread(File.expand_path(file_to_upload)))

    puts 'Set blob metadata'
    blob_service.set_blob_metadata container_name, blob_name, metadata

    puts 'Get blob metadata'
    result = blob_service.get_blob_metadata container_name, blob_name

    puts "Metadata:\n"
    result.metadata.each do |key, value|
      puts "#{key}: #{value}\n"
    end

    puts 'Delete blob'
    blob_service.delete_blob(container_name, blob_name)

    puts 'Delete container'
    blob_service.delete_container(container_name)

    puts 'Blob metadata sample completed'
  end
end
