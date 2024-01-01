// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHotWalletProxy {
    function getHotWallet(address coldWallet) external view returns (address);

    function getColdWallets(address hotWallet) external view returns (address[] memory);
}
