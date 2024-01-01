// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFactory {
    function getOrDeployWallet(address) external returns (address);

    function getWalletOwner(address) external view returns (address);

    function getOwnerWallet(address) external view returns (address);
}
