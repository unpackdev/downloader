// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AStructs.sol";
import "./ICreate.sol";

interface IPDCreate is ICreate {
    function createBasicDao(
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam
    )
        external
        payable
        returns (bytes32 daoId);

    function createOwnerBasicDao(
        DaoMetadataParam memory daoMetadataParam,
        BasicDaoParam memory basicDaoParam
    )
        external
        payable
        returns (bytes32 daoId);

    function createCanvas(
        bytes32 daoId,
        bytes32 canvasId,
        string calldata canvasUri,
        bytes32[] calldata proof,
        address to
    )
        external
        payable;
}
