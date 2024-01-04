// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectGelatoDataMakerToAave {
    function getDataAndCastMakerToAave(uint256 _vaultId, address _colToken)
        external
        payable;
}
