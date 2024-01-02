// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IReserveStorage {
    struct TransferRestrictions {
        uint256 minAmountToBeLeft;
        uint256 minPercentOfTotalSupplyToBeLeft;
    }

    event TransferFromReserve(address pToken, address to, uint256 amount);

    function transferRestrictions(address pToken) external view returns (uint256, uint256);
}
