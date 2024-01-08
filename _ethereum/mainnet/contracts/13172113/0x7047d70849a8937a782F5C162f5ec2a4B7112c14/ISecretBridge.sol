// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISecretBridge {
    function swap(bytes memory _recipient)
        external
        payable;

    function swapToken(bytes memory _recipient, uint256 _amount, address _tokenAddress) 
        external;
}
