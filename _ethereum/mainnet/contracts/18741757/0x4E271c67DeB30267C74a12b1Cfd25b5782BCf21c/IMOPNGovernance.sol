// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMOPNGovernance {
    function owner() external view returns (address);

    function auctionHouseContract() external view returns (address);

    function mopnContract() external view returns (address);

    function bombContract() external view returns (address);

    function tokenContract() external view returns (address);

    function pointContract() external view returns (address);

    function landContract() external view returns (address);

    function dataContract() external view returns (address);

    function rentalContract() external view returns (address);

    function ERC6551Registry() external view returns (address);

    function ERC6551AccountProxy() external view returns (address);

    function ERC6551AccountHelper() external view returns (address);

    function createCollectionVault(
        address collectionAddress
    ) external returns (address);

    function getCollectionVaultIndex(
        address collectionAddress
    ) external view returns (uint256);

    function getCollectionVault(
        address collectionAddress
    ) external view returns (address);
}
