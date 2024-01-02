// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IMOPNCollectionVault.sol";

interface IMOPNData {
    struct NFTParams {
        address collectionAddress;
        uint256 tokenId;
    }

    struct AccountDataOutput {
        address account;
        address contractAddress;
        uint256 tokenId;
        uint256 CollectionMOPNPoint;
        uint256 MTBalance;
        uint256 OnMapMOPNPoint;
        uint256 TotalMOPNPoint;
        uint32 tileCoordinate;
        address owner;
        address AgentPlacer;
        uint256 AgentAssignPercentage;
    }

    struct CollectionDataOutput {
        address contractAddress;
        address collectionVault;
        uint256 OnMapNum;
        uint256 MTBalance;
        uint256 UnclaimMTBalance;
        uint256 CollectionMOPNPoints;
        uint256 OnMapMOPNPoints;
        uint256 CollectionMOPNPoint;
        uint256 PMTTotalSupply;
        uint256 OnMapAgentPlaceNftNumber;
        IMOPNCollectionVault.AskStruct AskStruct;
        IMOPNCollectionVault.BidStruct BidStruct;
    }

    function getAccountData(
        address account
    ) external view returns (AccountDataOutput memory accountData);

    function calcPerMOPNPointMinted() external view returns (uint256 inbox);

    function calcCollectionSettledMT(
        address collectionAddress
    ) external view returns (uint256 inbox);

    function calcAccountMT(
        address account
    ) external view returns (uint256 inbox);
}
