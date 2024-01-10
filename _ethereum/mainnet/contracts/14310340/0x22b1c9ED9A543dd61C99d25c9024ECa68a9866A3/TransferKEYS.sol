// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

// TransferKEYS Contract
// Developed by Daniel Kantor

// This contract will allow you to transfer KEYS to any address with NO 3% transfer tax.

// In order to use this contract, make sure you approve the amount of KEYS you would like to transfer
// with the approve() function on the KEYS contract located here: 
// https://etherscan.io/token/0xe0a189C975e4928222978A74517442239a0b86ff#writeContract
// After you approve the amount of KEYS you'd like to send, 
// you can call transferKEYS or transferKEYSWholeTokenAmounts

contract TransferKEYS {
    // KEYS Contract Address
    address constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    function transferKEYS(address toAddress, uint256 amount) public {
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount);
        require(s, "Failure to transfer from sender to contract");

        // Transfer KEYS Tokens To User
        bool s1 = IERC20(KEYS).transfer(toAddress, amount);
        require(s1, "Failure to transfer from contract to receiver");
    }

    function transferKEYSWholeTokenAmounts(address toAddress, uint256 amount) public {
        bool s = IERC20(KEYS).transferFrom(msg.sender, address(this), amount * 10**9);
        require(s, "Failure to transfer from sender to contract");

        // Transfer KEYS Tokens To User
        bool s1 = IERC20(KEYS).transfer(toAddress, amount * 10**9);
        require(s1, "Failure to transfer from contract to receiver");
    }
}