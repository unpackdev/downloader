//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.0;

contract SealedTip {
    function tip() public payable {
        block.coinbase.transfer(msg.value);
    }
}