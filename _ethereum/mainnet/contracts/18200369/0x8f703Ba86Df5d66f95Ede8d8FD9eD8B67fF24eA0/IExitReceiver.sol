// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IExitReceiver {
    function onExit(
        uint256 amount,
        address token,
        address originSender,
        uint256 originChainId,
        bytes memory callData
    ) external returns (bool success);
}
