// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IThorchainRouter {
    function depositWithExpiry(
        address payable vault,
        address asset,
        uint amount,
        string calldata memo,
        uint expiration
    ) external payable;
}