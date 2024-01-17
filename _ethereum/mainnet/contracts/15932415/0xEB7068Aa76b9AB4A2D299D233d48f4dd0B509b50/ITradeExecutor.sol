/// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface ITradeExecutor {
    function vault() external view returns (address);

    function totalFunds()
        external
        view
        returns (uint256 posValue, uint256 lastUpdatedBlock);
}
