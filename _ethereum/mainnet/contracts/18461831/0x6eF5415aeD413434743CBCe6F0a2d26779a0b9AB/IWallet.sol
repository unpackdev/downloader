// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWallet {
    function isOwner(address signer) external view returns (bool);
}
