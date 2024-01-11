// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ICollectionsRegistry.sol";

contract CollectionsRegistry is ICollectionsRegistry { 
    mapping(address => bool) private _approvedCollections;

    event ApprovedCollection(address indexed ownerAddress, address indexed collectionAddress);

    function approveCollection(address collectionAddress) external {
        require(Ownable(collectionAddress).owner() == msg.sender, "CollectionsRegistry: sender is not the collection contract owner");

        _approvedCollections[collectionAddress] = true;
        emit ApprovedCollection(msg.sender, collectionAddress);
    } 

    function isCollectionApproved(address collectionAddress) external view returns(bool) {
        return _approvedCollections[collectionAddress];
    } 

    function isCollectionApprovedBatch(address[] calldata collectionAddresses) external view returns(bool[] memory) {
        bool[] memory isApproved = new bool[](collectionAddresses.length);
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            isApproved[i] = _approvedCollections[collectionAddresses[i]];
        }

        return isApproved;
    }
}