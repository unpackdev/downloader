// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "./YIELDTokenHolder.sol";

contract YIELDTokenHolderLiquidity is YIELDTokenHolder {
    constructor (address _yieldTokenAddress) YIELDTokenHolder (
        _yieldTokenAddress
        ) {
            name = "Yield Protocol - Liquidity";
            unlockRate = 14;//Release duration (# of releases, months)
            //8,200,000.00
            //1,640,000.00
            perMonthCustom = [
                8200000 ether,
                1640000 ether,
                0,
                0,
                1640000 ether,
                0,
                0,
                1640000 ether,
                0,
                0,
                1640000 ether,
                0,
                0,
                1640000 ether
            ];
            transferOwnership(0xf5435455c49e4dA6686430506C45FB3385da3701);
    }
}