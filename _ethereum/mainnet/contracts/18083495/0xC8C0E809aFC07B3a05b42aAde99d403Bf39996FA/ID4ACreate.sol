// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";
import "./ICreate.sol";

interface ID4ACreate is ICreate {
    function createProject(
        uint256 startRound,
        uint256 mintableRound,
        uint256 daoFloorPriceRank,
        uint256 nftMaxSupplyRank,
        uint96 royaltyFeeRatioInBps,
        string calldata daoUri
    )
        external
        payable
        returns (bytes32 daoId);

    function createOwnerProject(DaoMetadataParam calldata daoMetadataParam) external payable returns (bytes32 daoId);

    function createCanvas(
        bytes32 daoId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        uint256 canvasRebateRatioInBps
    )
        external
        payable
        returns (bytes32);
}
