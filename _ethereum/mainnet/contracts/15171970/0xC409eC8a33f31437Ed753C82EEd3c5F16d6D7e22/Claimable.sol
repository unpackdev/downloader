// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20.sol";

import "./console.sol";

contract Claimable is Ownable {
    function claim(address to, uint256 amount) public payable onlyOwner {
        console.log("address balance: %s", address(this).balance);

        payable(to).transfer(amount);
    }

    function claimT(address token, address to, uint256 amount) public onlyOwner {
        console.log("address balance: %s", IERC20(token).balanceOf(address(this)));
        
        IERC20(token).transfer(to, amount);
    }
}