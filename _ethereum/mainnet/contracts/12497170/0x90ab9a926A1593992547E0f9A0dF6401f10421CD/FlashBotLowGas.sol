// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract FlashBotLowGas {
    receive() external payable {
        block.coinbase.call{gas: gasleft(), value: msg.value}("");
    }
}