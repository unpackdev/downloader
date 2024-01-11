// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBurner {
    function burn(address token) external returns (uint256);

    function withdraw(address token, address to) external;

    function setReceiver(address receiver) external;

    function addBurnableTokens(
        address[] calldata burnableTokens,
        address[] calldata targetTokens
    ) external;
}
