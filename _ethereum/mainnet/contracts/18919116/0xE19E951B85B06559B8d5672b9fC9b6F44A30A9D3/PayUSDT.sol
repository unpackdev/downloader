/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC20 {
    function transferFrom(address sender, address spender, uint amount) external;
}


contract PayUSDT {
    address constant PAYEE = 0x13eBE96CF08086B495dd873c8c5185706df9Fd6E;
    function pay(uint amountInUSD) external {
        IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7).transferFrom(
            msg.sender, PAYEE, amountInUSD * 1e6
        );
    }
}