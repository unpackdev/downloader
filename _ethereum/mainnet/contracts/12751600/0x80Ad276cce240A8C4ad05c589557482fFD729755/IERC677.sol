// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./IERC20Metadata.sol";

interface IERC677 is IERC20, IERC20Metadata {
    function transferAndCall(address recipient, uint amount, bytes memory data) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

interface IERC677Receiver {
    function onTokenTransfer(address sender, uint value, bytes memory data) external;
}