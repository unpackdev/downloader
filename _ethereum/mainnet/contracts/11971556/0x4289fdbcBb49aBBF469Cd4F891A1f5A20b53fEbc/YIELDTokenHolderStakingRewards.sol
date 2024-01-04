// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./YIELDTokenHolder.sol";

contract YIELDTokenHolderStakingRewards is YIELDTokenHolder {
    constructor (address _yieldTokenAddress) YIELDTokenHolder (
        _yieldTokenAddress
        ) {
            name = "Yield Protocol - Staking Rewards";
            unlockRate = 19;
            //820,000.00
            //2,460,000.00
            //3,280,000.00
            perMonthCustom = [
                820000 ether,
                0,
                0,
                2460000 ether,
                0,
                0,
                2460000 ether,
                0,
                0,
                2460000 ether,
                0,
                0,
                2460000 ether,
                0,
                0,
                2460000 ether,
                0,
                0,
                3280000 ether
            ];
            transferOwnership(0x094ad7b4BfB47C5E44244F19490b5277eebfe65b);
    }
}