// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IOptimismBridge {
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    ) external payable;

    function xDomainMessageSender() external view returns (address);
}
