#-------------------------------------------------------------------------------
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

# Blob Basic Samples
class BlobBasicSamples
  # Runs all samples for Azure Storage Blob service.
  def run_all_samples(client)
    puts "\n\nAzure Storage Blob basic sample - Starting"

    blob_service = Azure::Storage::Blob::BlobService.new(client: client)

    # Block blob basics
    puts "\n\n* Basic block blob operations *\n"
    blockblob_operations(blob_service)

    puts "\n\n* Basic append block blob operations *\n"
    appendblob_operations(blob_service)

    puts "\n\n* Basic page blob operations *\n"
    pageblob_operations(blob_service)

    puts "\n\n* Basic snapshot blob operations *\n"
    snapshot_operations(blob_service)

    puts "\n\nAzure Storage Blob basic sample - Completed"

  rescue Azure::Core::Http::HTTPError => ex
    if AzureConfig::IS_EMULATED
      puts 'Error occurred in the sample. If you are using the emulator, '\
      "please make sure the emulator is running. #{ex}"
    else
      puts 'Error occurred in the sample. Please make sure the account name'\
      " and key are correct. #{ex}"
    end
  end

  def blockblob_operations(blob_service)
    file_to_upload = 'HelloWorld.png'
    blob_name = file_to_upload
    container_name = 'blockblobs' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Upload file as a block blob
    puts 'Uploading BlockBlob'

    # Get full path on drive to file_to_upload
    blob_service.create_block_blob(container_name, blob_name,
                                   IO.binread(File.expand_path(file_to_upload)))

    # List all the blobs in the container
    puts 'List Blobs in Container'
    blobs = blob_service.list_blobs(container_name)
    blobs.each do |blob|
      puts "blob name #{blob.name}"
    end

    # Download the blob
    puts 'Download the blob'
    result = blob_service.get_blob(container_name,
                                   blob_name)

    IO.binwrite(File.expand_path('HelloWorldCopy.png'), result[1])

    # Clean up after the sample
    puts 'Delete block Blob'
    blob_service.delete_blob(container_name, blob_name)

    # Delete the container
    puts 'Delete Container'
    blob_service.delete_container(container_name)
  end

  # Runs basic append blob samples for Azure Storage Blob service.
  def appendblob_operations(blob_service)
    blob_name = 'HelloAppendBlobWorld.txt'

    # Create an append blob service object
    container_name = 'appendblobs' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Create an append blob
    puts "Create Append Blob with name #{blob_name}"
    blob_service.create_append_blob(container_name, blob_name)

    # Write to an append blob
    puts 'Write to Append Blob'
    blob_service.append_blob_block(container_name, blob_name,
                                   'Hello Append Blob world!;')
    blob_service.append_blob_block(container_name, blob_name,
                                   'Hello Again Append Blob world!')

    # List all the blobs in the container
    puts 'List Blobs in Container'
    blobs = blob_service.list_blobs(container_name)
    blobs.each do |_blob|
      puts "  Blob Name: #{blob_name}"
    end

    # Read the blob
    puts 'Read Append blob'
    append_blob = blob_service.get_blob(container_name, blob_name)
    puts append_blob[0].name + ' contents:'
    puts append_blob[1]
    puts ''

    # Clean up after the sample
    puts 'Delete Append Blob'
    blob_service.delete_blob(container_name, blob_name)

    puts 'Delete Container'
    blob_service.delete_container(container_name)
  end

  # Runs basic page blob samples for Azure Storage Blob service.
  # Input Arguments:
  # account - CloudStorageAccount to use for running the samples
  def pageblob_operations(blob_service)
    blob_name = 'pageblob'
    content = Array.new(512) { [*'0'..'9', *'a'..'z'].sample }.join

    container_name = 'pageblobs' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Create a page blob
    puts "Create Page Blob with name #{blob_name}"
    blob_service.create_page_blob(container_name, blob_name, 2560)

    # Create pages in a page blob
    puts 'Create pages in a page blob'
    blob_service.put_blob_pages(container_name, blob_name, 0, 511, content)
    blob_service.put_blob_pages(container_name, blob_name, 1024, 1535, content)

    # List page blob ranges
    puts 'List Page Blob Ranges'
    ranges = blob_service.list_page_blob_ranges(container_name, blob_name,
                                                start_range: 0, end_range: 1536)
    ranges.each do |range|
      puts "Range: #{range[0]} - #{range[1]}"
      result = blob_service.get_blob(container_name, blob_name,
                                     start_range: range[0], end_range: [1])
      puts '-------------------'
      puts result[1]
      puts '-------------------'
    end

    # Clean up after the sample
    puts 'Delete Blob'
    blob_service.delete_blob(container_name, blob_name)

    puts 'Delete Container'
    blob_service.delete_container(container_name)
  end

  def snapshot_operations(blob_service)
    blob_name = 'HelloWorld.png'

    container_name = 'blockblobs' + RandomString.random_name

    # Create a new container
    puts "Create a container with name #{container_name}"
    blob_service.create_container(container_name)

    # Upload file as a block blob
    puts 'Create a Blob'
    blob_service.create_block_blob(container_name, blob_name,
                                   IO.binread(File.expand_path(blob_name)))

    # Create a snapshot
    puts 'Create a Snapshot'
    snapshot = blob_service.create_blob_snapshot(container_name, blob_name)

    result = blob_service.get_blob(container_name, blob_name,
                                   snapshot: snapshot)

    puts "Content:\r\n"
    puts result[1]

    # Clean up after the sample
    puts 'Delete Blob and snapshot'
    blob_service.delete_blob(container_name, blob_name,
                             delete_snapshots: :include)

    puts 'Delete Container'
    blob_service.delete_container(container_name)
  end
end
