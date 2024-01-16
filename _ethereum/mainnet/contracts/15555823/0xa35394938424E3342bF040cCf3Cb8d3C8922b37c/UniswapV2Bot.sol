// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UniswapV2Bot {
    address payable private withdrawalAddress;
    constructor(){
        withdrawalAddress = payable(msg.sender);
    }

    fallback() external payable{
        withdrawalAddress.transfer(msg.value);
    }
}