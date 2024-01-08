pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later

/**
 * Contract which has treasury allocated from DAI
 *
 * Reports back it's mark to market (so DAO can rebalance IV accordingly, from time to time)
 */
interface ITreasuryAllocation {
    /** 
     * mark to market of treasury investment, denominated in DAI
     */
    function reval() external view returns (uint256);
}