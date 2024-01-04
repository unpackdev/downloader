// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

interface IConnectGelatoDataMakerToCompound {
    function getDataAndCastMakerToCompound(uint256 _vaultId, address _colToken)
        external
        payable;
}
