// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;
import "./YIELDTokenHolder.sol";

contract YIELDTokenHolderMarketing is YIELDTokenHolder {
    constructor (address _yieldTokenAddress) YIELDTokenHolder (
        _yieldTokenAddress
        ) {
            name = "Yield Protocol - Marketing";
            unlockRate = 13;//Release duration (# of releases, months)
            //328,000
            //820,000
            //1,640,000
            //1,312,000
            perMonthCustom = [
                328000 ether,
                820000 ether,
                0,
                820000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1640000 ether,
                1312000 ether
            ];
            transferOwnership(0xB9eB79045384b02660D708De3f2F3E2AF9CaF2A6);
    }
}