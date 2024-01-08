// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Batcher {
    function batchEthTransfers(address[] calldata addresses, uint[] calldata values) payable external {
        for (uint8 i=0; i < addresses.length; i++) {
            (bool success, ) = addresses[i].call{value: values[i]}("");
            require(success, "Eth transfer failed.");
        }
    }

    function batchTokenTransfers(address tokenAddress, address[] calldata addresses, uint[] calldata values) external {
        for (uint8 i=0; i < addresses.length; i++) {
            bool success = IERC20(tokenAddress).transferFrom(msg.sender, addresses[i], values[i]);
            require(success, "Token transfer failed.");
        }
    }
}