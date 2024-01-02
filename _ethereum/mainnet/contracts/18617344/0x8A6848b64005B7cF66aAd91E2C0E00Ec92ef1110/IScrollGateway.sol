// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IScrollGateway {
   
   function sendMessage(
        address _to,
        uint256 _value,
        bytes calldata _message,
        uint256 _gasLimit,
        address _refundAddress
    ) external payable;
}
