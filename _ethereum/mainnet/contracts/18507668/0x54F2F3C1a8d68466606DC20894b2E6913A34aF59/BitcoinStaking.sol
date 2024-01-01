// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./RevenueDistributionToken.sol";

contract BitcoinStaking is RevenueDistributionToken {
    constructor()
        RevenueDistributionToken(
            address(0xC701E3D2DcCf4115D87a92f2a6E0eeEF2f0D0F25), //owner
            address(0x476908D9f75687684CE3DBF6990e722129cDbCc6), //token
            1e30
        )
    {}

    function name() public view virtual override returns (string memory) {
        return "Bitcoin2015 Staking";
    }

    function symbol() public view virtual override returns (string memory) {
        return "xWBTC";
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }
}
