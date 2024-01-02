// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ITraderBalanceVaultStorage {
    struct TraderBalance {
        uint256 availableBalance;
        uint256 lockedBalance;
    }

    function registry() external view returns (address);

    /**
     *
     * @param trader Trader's address
     * @param asset Asset address
     * @return availableBalance availableBalance
     * @return lockedBalance lockedBalance
     */
    function balances(
        address trader,
        address asset
    ) external view returns (uint256 availableBalance, uint256 lockedBalance);
}
