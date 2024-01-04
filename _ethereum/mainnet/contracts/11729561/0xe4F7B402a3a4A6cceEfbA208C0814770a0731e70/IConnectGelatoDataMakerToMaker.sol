// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectGelatoDataMakerToMaker {
    function getDataAndCastMakerToMaker(
        uint256 _vaultAId,
        uint256 _vaultBId,
        string calldata _colType,
        address _colToken
    ) external payable;
}
