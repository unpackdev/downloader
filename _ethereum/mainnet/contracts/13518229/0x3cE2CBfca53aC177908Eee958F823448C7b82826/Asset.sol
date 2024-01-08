// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Mintable.sol";
import "./Minting.sol";

contract MomentousV1 is ERC721URIStorage, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {}

    mapping(uint256 => uint256[]) private creatorToCollectionMap;
    mapping(uint256 => uint256) private nftToCollectionMap;
    mapping(uint256 => uint256) private collectionToCreatorMap;
    mapping(uint256 => uint256) private collectionToRunSizeMap;
    mapping(uint256 => uint256[]) private collectionToNFTsMap;

    // Returns the Collection IDs of the specific creator
    function getCollectionsByCreator(uint256 _creatorID) external view returns (uint256[] memory) {
        return creatorToCollectionMap[_creatorID];
    }

    // Return the NFT IDs that are in a collection
    function getNFTsByCollection(uint256 _collectionID) external view returns (uint256[] memory) {
        return collectionToNFTsMap[_collectionID];
    }

    // Return the run size of a collection
    function getRunSizeByCollection(uint256 _collectionID) external view returns (uint256) {
        return collectionToRunSizeMap[_collectionID];
    }

    // Return the Collection ID that this NFT belongs to
    function getCollectionByNFT(uint256 _nftID) external view returns (uint256) {
        return nftToCollectionMap[_nftID];
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory blueprint
    ) internal override {

        (string memory uri, uint32 creatorID, uint32 collectionID, uint32 runSize) = MintingUtils.deserializeIMXMintingBlob(blueprint);

        if(collectionToCreatorMap[collectionID] == 0) {
            collectionToCreatorMap[collectionID] = creatorID;
            creatorToCollectionMap[creatorID].push(collectionID);
            collectionToRunSizeMap[collectionID] = runSize;
        }

        collectionToNFTsMap[collectionID].push(id);
        
        nftToCollectionMap[id] = collectionID;
        
        _safeMint(user, id);
        _setTokenURI(id, uri);
    }

 
}
