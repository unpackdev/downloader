//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract TransferValueToMinerCoinbase {
    
    receive() external payable {
        block.coinbase.transfer(msg.value);
    }
    
}