pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";

// SPDX-License-Identifier: MIT

contract LiquiditySack is Ownable {
    using Address for address;
    address otherTokenAddress;

    constructor(address otherToken) {
        otherTokenAddress = otherToken;
    }

    function giveItBack() public onlyOwner {
        IERC20 other = IERC20(otherTokenAddress);
        uint256 owned = other.balanceOf(address(this));
        other.transfer(owner(), owned);
    }
}
