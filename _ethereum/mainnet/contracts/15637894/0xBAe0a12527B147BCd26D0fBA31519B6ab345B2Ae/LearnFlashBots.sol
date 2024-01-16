// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract LearnFlashBots {
    receive() external payable{
       // bribe the miner 
       block.coinbase.transfer(address(this).balance);
    }
}