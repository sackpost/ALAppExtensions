// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Azure.Storage;

using System.Azure.Storage;
using System.TestLibraries.Utilities;

codeunit 132920 "ABS Blob Client Test"
{
    Subtype = Test;

    [Test]
    procedure PutBlobBlockBlobStreamTest()
    var
        Response: Codeunit "ABS Operation Response";
        ContainerName, BlobName, BlobContent, NewBlobContent : Text;
    begin
        // [Scenario] Given a storage account and a container, PutBlobBlockBlob operation succeeds and GetBlobAsText returns the content 

        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        ContainerName := ABSTestLibrary.GetContainerName();
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();

        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSContainerClient.CreateContainer(ContainerName);

        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        Response := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        Response := ABSBlobClient.GetBlobAsText(BlobName, NewBlobContent);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation GetBlobAsText failed');

        Assert.AreEqual(BlobContent, NewBlobContent, 'Blob content mismatch');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure ListBlobsTest()
    var
        ABSContainerContent: Record "ABS Container Content";
        Response: Codeunit "ABS Operation Response";
        ContainerName, FirstBlobName, SecondBlobName, BlobContent : Text;
    begin
        // [Scenario] Given a storage account and a container with BLOBs, ListBlobs operation succeeds. 

        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        ContainerName := ABSTestLibrary.GetContainerName();
        FirstBlobName := ABSTestLibrary.GetBlobName();
        SecondBlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();

        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSContainerClient.CreateContainer(ContainerName);

        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        // Add a BLOB block
        Response := ABSBlobClient.PutBlobBlockBlobText(FirstBlobName, BlobContent);
        Assert.IsTrue(Response.IsSuccessful(), 'Adding the first BLOB failed');

        ABSBlobClient.ListBlobs(ABSContainerContent);
        Assert.AreEqual(1, ABSContainerContent.Count(), 'There should be exactly one BLOB in the container');

        Assert.AreEqual('BlockBlob', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual(0, ABSContainerContent."Content Length", 'Content Length should not be 0');
        Assert.AreEqual('text/plain; charset=utf-8', ABSContainerContent."Content Type", 'Wrong Content type');

        // Add another BLOB block
        Response := ABSBlobClient.PutBlobBlockBlobText(SecondBlobName, BlobContent);
        Assert.IsTrue(Response.IsSuccessful(), 'Adding the second BLOB failed');

        ABSBlobClient.ListBlobs(ABSContainerContent);
        Assert.AreEqual(2, ABSContainerContent.Count(), 'There should be two BLOBs in the container');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure ListBlobsTestNextMarker()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSOptionalParameters: Codeunit "ABS Optional Parameters";
        ContainerName, FirstBlobName, SecondBlobName, BlobContent : Text;
        BlobList: Dictionary of [Text, XmlNode];
        Blobs: List of [Text];
    begin
        // [Scenario] Given a storage account and a container with BLOBs, ListBlobs operation succeeds. 

        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        ContainerName := ABSTestLibrary.GetContainerName();
        FirstBlobName := ABSTestLibrary.GetBlobName();
        SecondBlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();

        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSContainerClient.CreateContainer(ContainerName);

        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        // Add a BLOB block
        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(FirstBlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Adding the first BLOB failed');

        // Add another BLOB block
        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(SecondBlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Adding the second BLOB failed');

        // Fetch 1 Blob
        ABSOptionalParameters.MaxResults(1);
        ABSOperationResponse := ABSBlobClient.ListBlobs(BlobList, ABSOptionalParameters);
        Assert.AreEqual(1, BlobList.Count(), 'Should only fetch One BLOB from container');
        Assert.AreNotEqual('', ABSOperationResponse.GetNextMarker(), 'There should be a Next Marker');
        Blobs.AddRange(BlobList.Keys());

        // Fetch Next Blob
        ABSOptionalParameters.NextMarker(ABSOperationResponse.GetNextMarker());
        ABSOperationResponse := ABSBlobClient.ListBlobs(BlobList, ABSOptionalParameters);
        Assert.AreEqual(1, BlobList.Count(), 'Should only fetch One BLOB from container');
        Assert.AreEqual('', ABSOperationResponse.GetNextMarker(), 'There should not be a Next Marker');
        Blobs.AddRange(BlobList.Keys());
        Assert.AreEqual(2, Blobs.Count(), 'There should be two BLOBs in the container');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test] // Failing if ran against azurite, as BLOB tags are not supported there
    procedure ListBlobsTestIncludeTags()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSOptionalParameters: Codeunit "ABS Optional Parameters";
        BlobList: Dictionary of [Text, XmlNode];
        Tags: Dictionary of [Text, Text];
        ContainerName, BlobName, BlobContent : Text;
    begin
        // [SCENARIO] Given a storage account and a container with BLOB, ListBlobs operation succeeds and returns the content with tags.
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [GIVEN] Blob Tags
        Tags := ABSTestLibrary.GetBlobTags();

        // [WHEN] Tags are Set
        ABSOperationResponse := ABSBlobClient.SetBlobTags(BlobName, Tags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation SetBlobTags failed: ' + ABSOperationResponse.GetError());

        // Listing the BLOBs in the container
        ABSOptionalParameters.Include('tags');
        ABSOperationResponse := ABSBlobClient.ListBlobs(BlobList, ABSOptionalParameters);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation ListBlobs failed');

        // [THEN] The get tags are equal to set tags
        Assert.AreEqual(Tags, GetBlobTagsFromABSContainerBlobList(BlobName, BlobList));

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure ListBlobHierarchyTest()
    var
        ABSContainerContent: Record "ABS Container Content";
        ContainerName: Text;
    begin
        // [Scenario] When listing blobs, the levels, parent directories etc. are set correctly

        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        ContainerName := ABSTestLibrary.GetContainerName();

        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSContainerClient.CreateContainer(ContainerName);

        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        //[Given] A ABS container with the following structure
        // Create 10 blobs with the following hierarchy:
        // |   rootblob1
        // |   rootblob2
        // |
        // \---folder1
        //     |   folderblob1
        //     |   folderblob2
        //     |
        //     +---subfolder1
        //     |   |   subfolderblob1
        //     |   |   subfolderblob2
        //     |   |
        //     |   \---subsubfolder
        //     |           subsubfolderfolderblob1
        //     |           subsubfolderfolderblob2
        //     |
        //     \---subfolder2
        //         \---subsubfolder
        //                 subsubfolderfolderblob1
        //                 subsubfolderfolderblob2

        ABSBlobClient.PutBlobBlockBlobText('rootblob1', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('rootblob2', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/folderblob1', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/folderblob2', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder1/subfolderblob1', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder1/subfolderblob2', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder1/subsubfolder/subsubfolderblob1', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder1/subsubfolder/subsubfolderblob2', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder2/subsubfolder/subsubfolderblob1', CreateGuid());
        ABSBlobClient.PutBlobBlockBlobText('folder1/subfolder2/subsubfolder/subsubfolderblob2', CreateGuid());

        // [When] Listing the BLOBs in the container
        // [Then] The result is as expected
        Assert.IsTrue(ABSBlobClient.ListBlobs(ABSContainerContent).IsSuccessful(), 'Operation ListBlobs failed');
        Assert.AreEqual(15, ABSContainerContent.Count(), 'Wrong number of BLOBs + directories');

        // [Then] Directory entries are created
        ABSContainerContent.SetRange("Content Type", 'Directory');
        Assert.AreEqual(5, ABSContainerContent.Count(), 'There should be 5 directories in the result');

        ABSContainerContent.Reset();

        // [Then] Enties in the result (ABSContainerContent) are ordered by EntryNo and the BLOBs are sorted alphabetical order (by full name)
        Assert.IsTrue(ABSContainerContent.FindSet(), 'Directory does not exist');
        Assert.AreEqual('folder1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(0, ABSContainerContent.Level, 'Wrong level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('folderblob1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/folderblob1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(1, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('folderblob2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/folderblob2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(1, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'Directory does not exist');
        Assert.AreEqual('subfolder1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(1, ABSContainerContent.Level, 'Wrong level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subfolderblob1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1/subfolderblob1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(2, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subfolderblob2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1/subfolderblob2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(2, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'Directory does not exist');
        Assert.AreEqual('subsubfolder', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1/subsubfolder', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(2, ABSContainerContent.Level, 'Wrong level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subsubfolderblob1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1/subsubfolder/subsubfolderblob1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder1/subsubfolder/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(3, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subsubfolderblob2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder1/subsubfolder/subsubfolderblob2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder1/subsubfolder/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(3, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'Directory does not exist');
        Assert.AreEqual('subfolder2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(1, ABSContainerContent.Level, 'Wrong level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'Directory does not exist');
        Assert.AreEqual('subsubfolder', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder2/subsubfolder', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder2/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(2, ABSContainerContent.Level, 'Wrong level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subsubfolderblob1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder2/subsubfolder/subsubfolderblob1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder2/subsubfolder/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreEqual(3, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('subsubfolderblob2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('folder1/subfolder2/subsubfolder/subsubfolderblob2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('folder1/subfolder2/subsubfolder/', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(3, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('rootblob1', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('rootblob1', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(0, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() <> 0, 'BLOB does not exist');
        Assert.AreEqual('rootblob2', ABSContainerContent.Name, 'Wrong name');
        Assert.AreEqual('rootblob2', ABSContainerContent."Full Name", 'Wrong full name');
        Assert.AreEqual('', ABSContainerContent."Parent Directory", 'Wrong parent directory');
        Assert.AreNotEqual('Directory', ABSContainerContent."Content Type", 'Wrong content type');
        Assert.AreNotEqual('', ABSContainerContent."Blob Type", 'Wrong BLOB type');
        Assert.AreEqual(0, ABSContainerContent.Level, 'Wrong BLOB level');

        Assert.IsTrue(ABSContainerContent.Next() = 0, 'There should be no more entries');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test] // Failing if ran against azurite, as BLOB tags are not supported there
    procedure GetBlockBlobTagsTest()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        Tags, BlobTags : Dictionary of [Text, Text];
        ContainerName, BlobName, BlobContent : Text;
    begin
        // [SCENARIO] Given a storage account and a container, PutBlobBlockBlob operation succeeds and GetBlobAsText returns the content
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container 
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [GIVEN] Blob Tags
        Tags := ABSTestLibrary.GetBlobTags();

        // [WHEN] Tags are Set
        ABSOperationResponse := ABSBlobClient.SetBlobTags(BlobName, Tags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation SetBlobTags failed: ' + ABSOperationResponse.GetError());

        // [WHEN] Tags are Get
        ABSOperationResponse := ABSBlobClient.GetBlobTags(BlobName, BlobTags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation GetBlobTags failed: ' + ABSOperationResponse.GetError());

        // [THEN] The get tags are equal to set tags 
        Assert.AreEqual(Tags, BlobTags);

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test] // Failing if ran against azurite, as BLOB tags are not supported there
    procedure GetBlockBlobChangedTagsTest()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        Tags, OldTags, NewTags : Dictionary of [Text, Text];
        ContainerName, BlobName, BlobContent : Text;
    begin
        // [SCENARIO] Given a storage account and a container, PutBlobBlockBlob operation succeeds, then Tags are set and then changed
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container 
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [GIVEN] Blob Tags
        Tags := ABSTestLibrary.GetBlobTags();

        // [WHEN] Tags are Set
        ABSOperationResponse := ABSBlobClient.SetBlobTags(BlobName, Tags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation SetBlobTags failed');

        // [WHEN] Tags are Get
        ABSOperationResponse := ABSBlobClient.GetBlobTags(BlobName, OldTags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation GetBlobTags failed');

        // [GIVEN] New Blob Tags
        Tags := ABSTestLibrary.GetBlobTags();

        // [WHEN] New Tags are Set
        ABSOperationResponse := ABSBlobClient.SetBlobTags(BlobName, Tags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation SetBlobTags failed');

        // [WHEN] Tags are Get
        ABSOperationResponse := ABSBlobClient.GetBlobTags(BlobName, NewTags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation GetBlobTags failed');

        // [THEN] The new tags are different then the old tags 
        asserterror Assert.AreEqual(NewTags, OldTags);

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test] // Failing if ran against azurite, as BLOB tags are not supported there
    procedure GetBlockBlobEmptyTagsTest()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        Tags, BlobTags : Dictionary of [Text, Text];
        ContainerName, BlobName, BlobContent : Text;
    begin
        // [SCENARIO] Given a storage account and a container, empty Blob Tags dictionary, PutBlobBlockBlob operation succeeds and GetBlobAsText returns the content
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container 
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [WHEN] Tags are Set
        ABSOperationResponse := ABSBlobClient.SetBlobTags(BlobName, Tags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation SetBlobTags failed');
        // [WHEN] Tags are Get
        ABSOperationResponse := ABSBlobClient.GetBlobTags(BlobName, BlobTags);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation GetBlobTags failed');

        // [THEN] The get tags are equal to set tags 
        Assert.AreEqual(Tags, BlobTags);

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure LeaseBlobTest()
    var
        Response: Codeunit "ABS Operation Response";
        ContainerName, BlobName, BlobContent : Text;
        LeaseId: Guid;
        ProposedLeaseId: Guid;
    begin
        // [Scenario] Given a storage account and a container, PutBlobBlockBlob operation succeeds and subsequent lease-operations
        // (1) create a lease, (2) renew a lease, [(3) change a lease], (4) break a lease and (5) release the lease

        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        ContainerName := ABSTestLibrary.GetContainerName();
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();

        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSContainerClient.CreateContainer(ContainerName);

        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        // Create blob for this test
        Response := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [1st] Acquire Lease on Blob
        Response := ABSBlobClient.AcquireLease(BlobName, 60, LeaseId);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation LeaseAcquire failed');
        Assert.IsFalse(IsNullGuid(LeaseId), 'Operation LeaseAcquire failed (no LeaseId returned)');

        // [2nd] Renew Lease on Blob
        Response := ABSBlobClient.RenewLease(BlobName, LeaseId);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation LeaseRenew failed');

        // This part works when testing against a "real" Azure Storage and not Azurite
        if (AzuriteTestLibrary.GetStorageAccountName() <> 'devstoreaccount1') then begin // "devstoreaccount1" is the hardcoded name for Azurite test-account
            // [3rd] Change Lease on Blob
            ProposedLeaseId := CreateGuid();
            Response := ABSBlobClient.ChangeLease(BlobName, LeaseId, ProposedLeaseId);
            Assert.IsTrue(Response.IsSuccessful(), 'Operation LeaseChange failed');
            Assert.IsFalse(IsNullGuid(LeaseId), 'Operation LeaseChange failed (no LeaseId returned)');
        end;

        // [4th] Break Lease on Blob
        Response := ABSBlobClient.BreakLease(BlobName, LeaseId);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation LeaseBreak failed');

        // [5th] Release Lease on Blob
        Response := ABSBlobClient.ReleaseLease(BlobName, LeaseId);
        Assert.IsTrue(Response.IsSuccessful(), 'Operation LeaseRelease failed');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure GetBlobPropertiesTest()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ContainerName, BlobName, BlobContent : Text;
    begin
        // [SCENARIO] Given a storage account and a container, PutBlobBlockBlob operation succeeds and GetBlobAsText returns the content
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container 
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [WHEN] Properties are read
        ABSOperationResponse := ABSBlobClient.GetBlobProperties(BlobName);

        // [THEN] The properties are as expected
        Assert.IsTrue(ABSOperationResponse.GetHeaderValueFromResponseHeaders('x-ms-creation-time') <> '', 'Property x-ms-creation-time is missing');
        Assert.AreEqual(ABSOperationResponse.GetHeaderValueFromResponseHeaders('x-ms-blob-type'), 'BlockBlob', 'Property x-ms-blob-type is wrong');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure BlobExistsTest()
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ContainerName, BlobName, BlobContent : Text;
        BlobExists: Boolean;
    begin
        // [SCENARIO] Given a storage account and a container, PutBlobBlockBlob operation succeeds and GetBlobAsText returns the content
        // [GIVEN] Shared Key Authorization
        SharedKeyAuthorization := StorageServiceAuthorization.CreateSharedKey(AzuriteTestLibrary.GetAccessKey());

        // [GIVEN] ABS Container 
        ContainerName := ABSTestLibrary.GetContainerName();
        ABSContainerClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), SharedKeyAuthorization);
        ABSContainerClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSContainerClient.CreateContainer(ContainerName);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation CreateContainer failed');

        // [GIVEN] Block Blob
        BlobName := ABSTestLibrary.GetBlobName();
        BlobContent := ABSTestLibrary.GetSampleTextBlobContent();
        ABSBlobClient.Initialize(AzuriteTestLibrary.GetStorageAccountName(), ContainerName, SharedKeyAuthorization);
        ABSBlobClient.SetBaseUrl(AzuriteTestLibrary.GetBlobStorageBaseUrl());

        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobText(BlobName, BlobContent);
        Assert.IsTrue(ABSOperationResponse.IsSuccessful(), 'Operation PutBlobBlockBlob failed');

        // [WHEN] Blob Exists is called
        BlobExists := ABSBlobClient.BlobExists(BlobName);

        // [THEN] The blob exists
        Assert.IsTrue(BlobExists, 'The return value of procedure BlobExists should be true.');

        // Clean-up
        ABSContainerClient.DeleteContainer(ContainerName);
    end;

    [Test]
    procedure ParseResponseWithHierarchicalBlobName()
    var
        ABSContainerContent: Record "ABS Container Content";
        ABSHelperLibrary: Codeunit "ABS Helper Library";
        NodeList: XmlNodeList;
        NextMarker: Text;
    begin
        // [SCENARIO] Parse the BLOB storage API response listing BLOBs in a container without the hierarchical namespace

        // [GIVEN] Prepare an XML response from the BLOB Storage API, listing all BLOBs in a container.
        // [GIVEN] Container does not have hierarchical namespace and contains a single BLOB with the name like "folder/blob"
        NodeList := ABSHelperLibrary.CreateBlobNodeListFromResponse(ABSTestLibrary.GetServiceResponseBlobWithHierarchicalName(), NextMarker);

        // [WHEN] Invoke BlobNodeListToTempRecord
        ABSHelperLibrary.BlobNodeListToTempRecord(NodeList, ABSContainerContent);

        // [THEN] "ABS Container Content" contains one record "folder" and one record "blob"
        Assert.RecordCount(ABSContainerContent, 2);

        ABSContainerContent.SetRange(Name, ABSTestLibrary.GetSampleResponseRootDirName());
        Assert.RecordCount(ABSContainerContent, 1);

        ABSContainerContent.SetRange(Name, ABSTestLibrary.GetSampleResponseFileName());
        Assert.RecordCount(ABSContainerContent, 1);
    end;

    [Test]
    procedure ParseResponseFromStorageHierarachicalNamespace()
    var
        ABSContainerContent: Record "ABS Container Content";
        ABSHelperLibrary: Codeunit "ABS Helper Library";
        NodeList: XmlNodeList;
        NextMarker: Text;
    begin
        // [SCENARIO] Parse the BLOB storage API response listing BLOBs in a container with the hierarchical namespace enabled

        // [GIVEN] Prepare an XML response from the BLOB Storage API, listing all BLOBs in a container.
        // [GIVEN] Container has the hierarchical namespace enabled, and contains a root folder named "rootdir".
        // [GIVEN] There is a subdirectory "subdir" in the root, and one blob named "blob" in the subdirectory.
        NodeList := ABSHelperLibrary.CreateBlobNodeListFromResponse(ABSTestLibrary.GetServiceResponseHierarchicalNamespace(), NextMarker);

        // [WHEN] Invoke BlobNodeListToTempRecord
        ABSHelperLibrary.BlobNodeListToTempRecord(NodeList, ABSContainerContent);

        // [THEN] "ABS Container Content" contains two records with resource type "folder" and one record with resource type = "blob"
        Assert.RecordCount(ABSContainerContent, 3);

        VerifyContainerContentType(ABSContainerContent, CopyStr(ABSTestLibrary.GetSampleResponseRootDirName(), 1, MaxStrLen(ABSContainerContent.Name)), Enum::"ABS Blob Resource Type"::Directory);
        VerifyContainerContentType(ABSContainerContent, CopyStr(ABSTestLibrary.GetSampleResponseSubdirName(), 1, MaxStrLen(ABSContainerContent.Name)), Enum::"ABS Blob Resource Type"::Directory);
        VerifyContainerContentType(ABSContainerContent, CopyStr(ABSTestLibrary.GetSampleResponseFileName(), 1, MaxStrLen(ABSContainerContent.Name)), Enum::"ABS Blob Resource Type"::File);
    end;

    local procedure VerifyContainerContentType(var ABSContainerContent: Record "ABS Container Content"; BlobName: Text[2048]; ExpectedResourceType: Enum "ABS Blob Resource Type")
    var
        IncorrectBlobPropertyErr: Label 'BLOB property is assigned incorrectly';
    begin
        ABSContainerContent.SetRange(Name, BlobName);
        ABSContainerContent.FindFirst();
        Assert.AreEqual(ExpectedResourceType, ABSContainerContent."Resource Type", IncorrectBlobPropertyErr);
    end;

    local procedure GetBlobTagsFromABSContainerBlobList(BlobName: Text; BlobList: Dictionary of [Text, XmlNode]): Dictionary of [Text, Text]
    var
        BlobNode: XmlNode;
    begin
        BlobNode := BlobList.Get(BlobName);
        exit(XmlNodeToTagsDictionary(BlobNode));
    end;

    local procedure XmlNodeToTagsDictionary(Node: XmlNode): Dictionary of [Text, Text]
    var
        Tags: Dictionary of [Text, Text];
        TagNodesList: XmlNodeList;
        TagNode: XmlNode;
        KeyValue: Text;
        Value: Text;
    begin
        if not Node.SelectNodes('Tags/TagSet/Tag', TagNodesList) then
            exit;

        foreach TagNode in TagNodesList do begin
            KeyValue := GetSingleNodeInnerText(TagNode, 'Key');
            Value := GetSingleNodeInnerText(TagNode, 'Value');
            if KeyValue = '' then begin
                Clear(Tags);
                exit;
            end;
            Tags.Add(KeyValue, Value);
        end;
        exit(Tags);
    end;

    local procedure GetSingleNodeInnerText(Node: XmlNode; XPath: Text): Text
    var
        ChildNode: XmlNode;
        XmlElement: XmlElement;
    begin
        if not Node.SelectSingleNode(XPath, ChildNode) then
            exit;
        XmlElement := ChildNode.AsXmlElement();
        exit(XmlElement.InnerText());
    end;

    var
        Assert: Codeunit "Library Assert";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSContainerClient: Codeunit "ABS Container Client";
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        ABSTestLibrary: Codeunit "ABS Test Library";
        AzuriteTestLibrary: Codeunit "Azurite Test Library";
        SharedKeyAuthorization: Interface "Storage Service Authorization";
}
