// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev see https://github.com/fx-portal/contracts/blob/main/contracts/tunnel/FxBaseRootTunnel.sol
interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}
