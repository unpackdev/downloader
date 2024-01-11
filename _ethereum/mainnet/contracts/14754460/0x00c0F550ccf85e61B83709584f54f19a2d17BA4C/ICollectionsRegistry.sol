// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ICollectionsRegistry {
    function isCollectionApproved(address collectionAddress) external view returns(bool);

    function approveCollection(address tokenAddress) external;
}