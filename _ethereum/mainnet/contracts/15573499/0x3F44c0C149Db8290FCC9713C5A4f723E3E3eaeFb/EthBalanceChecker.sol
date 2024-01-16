// SPDX-License-Identifier: MIT
// Based on ZeroEx Intl work

pragma solidity ^0.5.16;


contract EthBalanceChecker {

    /// @dev Batch fetches ETH balances
    /// @param addresses Array of addresses.
    /// @return Array of ETH balances.
    function getEthBalances(address[] memory addresses)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory balances = new uint256[](addresses.length);
        for (uint256 i = 0; i != addresses.length; i++) {
            balances[i] = addresses[i].balance;
        }
        return balances;
    }

}
