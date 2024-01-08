// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Collection.sol";

contract HewerClanMergeProtocol is Ownable, ERC721Enumerable {
    struct CollectionEntry {
        bool registered;
        Collection collection;
    }

    struct MergedEntry {
        uint256 tagTokenId;
        uint256 tokenId;
        uint256 mergedTokenId;
        string collectionName;
        bool merged;
    }

    Collection public hewerClan;
    string public baseUri;
    bool public unmergeAllowed;

    string [] collections;

    mapping(string => CollectionEntry) collectionNameToCollectionEntry;
    mapping(uint256 => MergedEntry) tokenIdToMergedEntry;

    mapping(string => mapping(uint256 => MergedEntry)) collectionNftTokenIdToMergedEntry;
    mapping(uint256 => MergedEntry) tagTokenIdToMergedEntry;

    modifier onlyRegisteredCollection(string memory name) {
        require(collectionNameToCollectionEntry[name].registered, "Collection is not registered for the merge protocol");
        _;
    }

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can unmerge the request");
        _;
    }

    event TagMerged(uint256 tagTokenId, uint256 tokenId, string collectionName, uint256 mergedTokenId);
    event TagUnmerged(uint256 tagTokenId, uint256 tokenId, string collectionName, uint256 mergedTokenId);

    constructor(string memory uri, address hewerClanContractAddress, string [] memory supportedCollections) ERC721("HewerClanMergeProtocol", "HCMP") {
        setBaseURI(uri);

        hewerClan = Collection(hewerClanContractAddress);

        collections = supportedCollections;

        addCollection(collections[0], 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
        addCollection(collections[1], 0x1A92f7381B9F03921564a437210bB9396471050C);
        addCollection(collections[2], 0xbe6e3669464E7dB1e1528212F0BfF5039461CB82);
        addCollection(collections[3], 0x85f740958906b317de6ed79663012859067E745B);
        addCollection(collections[4], 0xF4ee95274741437636e748DdAc70818B4ED7d043);
        addCollection(collections[5], 0xeC516eFECd8276Efc608EcD958a4eAB8618c61e8);
        addCollection(collections[6], 0xBd3531dA5CF5857e7CfAA92426877b022e612cf8);
        addCollection(collections[7], 0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
        addCollection(collections[8], 0xdD467a6C8ae2b39825a452E06b4fA82F73D4253D);
        addCollection(collections[9], 0x8943C7bAC1914C9A7ABa750Bf2B6B09Fd21037E0);
        addCollection(collections[10], 0x3f5FB35468e9834A43dcA1C160c69EaAE78b6360);
        addCollection(collections[11], 0x3EAcf2D8ce91b35c048C6Ac6Ec36341aaE002FB9);
        addCollection(collections[12], 0x2acAb3DEa77832C09420663b0E1cB386031bA17B);
        addCollection(collections[13], 0xECDD2F733bD20E56865750eBcE33f17Da0bEE461);
        addCollection(collections[14], 0x3a8778A58993bA4B941f85684D74750043A4bB5f);
        addCollection(collections[15], 0x15533781a650F0c34F587CdB60965cdFd16ff624);
        addCollection(collections[16], 0x3bf2922f4520a8BA0c2eFC3D2a1539678DaD5e9D);
    }

    function mintMergeRequest(uint256 tagTokenId, uint256 tokenId, string memory collectionName) public onlyRegisteredCollection(collectionName) {
        require(!tagIsMerged(tagTokenId), "Tag with the given tokenId has already been used in a merge");
        require(!collectionNftIsMerged(collectionName, tokenId), "Nft with the given tokenId has already been used in a merge");

        require(hewerClan.ownerOf(tagTokenId) == msg.sender, "Must be the owner of the tag");
        require(collectionNameToCollectionEntry[collectionName].collection.ownerOf(tokenId) == msg.sender, "Must be the owner of the nft that is used in a merge");

        uint mergedTokenId = totalSupply() + 1;

        MergedEntry memory entry = MergedEntry(tagTokenId, tokenId, mergedTokenId, collectionName, true);

        tokenIdToMergedEntry[mergedTokenId] = entry;
        tagTokenIdToMergedEntry[tagTokenId] = entry;
        collectionNftTokenIdToMergedEntry[collectionName][tokenId] = entry;

        _safeMint(msg.sender, mergedTokenId);

        emit TagMerged(tagTokenId, tokenId, collectionName, mergedTokenId);
    }

    function mergeRequest(
        uint256 mergedTokenId,
        uint256 tagTokenId,
        uint256 collectionTokenId,
        string memory collectionName
    ) public onlyRegisteredCollection(collectionName) onlyOwnerOf(mergedTokenId) {
        require(unmergeAllowed, "Merging the request is only allowed when the unmerge feature is enabled");
        require(!tokenIdToMergedEntry[mergedTokenId].merged, "Merge request with the given parameters has already been merged");

        MergedEntry storage entry = tokenIdToMergedEntry[mergedTokenId];

        entry.merged = true;
        entry.collectionName = collectionName;
        entry.tokenId = collectionTokenId;
        entry.tagTokenId = tagTokenId;

        emit TagMerged(tagTokenId, collectionTokenId, collectionName, mergedTokenId);
    }

    function unmergeRequest(uint256 tokenId) public onlyOwnerOf(tokenId) {
        require(unmergeAllowed, "Unmerging the request is not allowed");
        require(tokenIdToMergedEntry[tokenId].merged, "Merge request with the given parameters has already been merged");

        MergedEntry storage entry = tokenIdToMergedEntry[tokenId];

        entry.merged = false;
        tagTokenIdToMergedEntry[entry.tagTokenId].merged = false;
        collectionNftTokenIdToMergedEntry[entry.collectionName][entry.tokenId].merged = false;

        emit TagUnmerged(entry.tagTokenId, entry.tokenId, entry.collectionName, entry.mergedTokenId);
    }

    function tagIsMerged(uint256 tagTokenId) public view returns (bool) {
        return tagTokenIdToMergedEntry[tagTokenId].merged;
    }

    function collectionNftIsMerged(string memory collectionName, uint256 tokenId) public view returns (bool) {
        return collectionNftTokenIdToMergedEntry[collectionName][tokenId].merged;
    }

    function getSupportedCollections() public view returns (string [] memory) {
        return collections;
    }

    function getOwnerTagTokenIdsAvailableForMerge(address _owner) public view returns (uint [] memory) {
        uint balance = hewerClan.balanceOf(_owner);
        uint balanceWithoutMergedTokens = balance;

        int [] memory allTokenIds = new int [](balance);

        for (uint i = 0; i < balance; i++) {
            uint tagTokenId = hewerClan.tokenOfOwnerByIndex(_owner, i);

            if (tagIsMerged(tagTokenId)) {
                balanceWithoutMergedTokens--;
                allTokenIds[i] = - 1;
            } else {
                allTokenIds[i] = int(i);
            }
        }

        uint [] memory tokenIds = new uint [](balanceWithoutMergedTokens);
        uint curTokenId = 0;

        for (uint i = 0; i < balance; i++) {
            if (allTokenIds[i] != - 1) {
                tokenIds[curTokenId++] = hewerClan.tokenOfOwnerByIndex(_owner, uint(allTokenIds[i]));
            }
        }

        return tokenIds;
    }

    function getOwnerNftTokenIdsAvailableForMerge(address _owner, string memory _name) public view returns (uint [] memory) {
        if (collectionIsRegistered(_name)) {
            Collection collection = collectionNameToCollectionEntry[_name].collection;

            uint balance = collection.balanceOf(_owner);
            uint balanceWithoutMergedTokens = balance;

            int [] memory allTokenIds = new int [](balance);

            for (uint i = 0; i < balance; i++) {
                uint tokenId = collection.tokenOfOwnerByIndex(_owner, i);

                if (collectionNftIsMerged(_name, tokenId)) {
                    balanceWithoutMergedTokens--;
                    allTokenIds[i] = - 1;
                } else {
                    allTokenIds[i] = int(i);
                }
            }

            uint [] memory tokenIds = new uint [](balanceWithoutMergedTokens);
            uint curTokenId = 0;

            for (uint i = 0; i < balance; i++) {
                if (allTokenIds[i] != - 1) {
                    tokenIds[curTokenId++] = collection.tokenOfOwnerByIndex(_owner, uint(allTokenIds[i]));
                }
            }

            return tokenIds;
        }

        return new uint [](0);
    }

    function getCollectionNameByMergedTokenId(uint _tokenId) public view returns (string memory) {
        return tokenIdToMergedEntry[_tokenId].collectionName;
    }

    function getCollectionTokenIdByMergedTokenId(uint _tokenId) public view returns (uint) {
        return tokenIdToMergedEntry[_tokenId].tokenId;
    }

    function getTagTokenIdByMergedTokenId(uint _tokenId) public view returns (uint) {
        return tokenIdToMergedEntry[_tokenId].tagTokenId;
    }

    function addCollection(string memory name, address _addr) public onlyOwner {
        require(!collectionIsRegistered(name), "Adding already existing collection");

        collectionNameToCollectionEntry[name] = CollectionEntry(true, Collection(_addr));
        collections.push(name);
    }

    function getCollectionAddress(string memory name) public view returns (address) {
        return address(collectionNameToCollectionEntry[name].collection);
    }

    function setCollectionAddress(string memory name, address _addr) public onlyOwner {
        collectionNameToCollectionEntry[name].collection = Collection(_addr);
    }

    function collectionIsRegistered(string memory name) public view returns (bool) {
        return collectionNameToCollectionEntry[name].registered;
    }

    function flipCollectionRegisteredState(string memory name) public onlyOwner {
        collectionNameToCollectionEntry[name].registered = !collectionNameToCollectionEntry[name].registered;
    }

    function flipUnmergeAllowed() public onlyOwner {
        unmergeAllowed = !unmergeAllowed;
    }

    function setHewerClanAddress(address _contractAddress) public onlyOwner {
        hewerClan = Collection(_contractAddress);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseUri = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}
