// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IWalletObserver {
    function beforeTokenTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}