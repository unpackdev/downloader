// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRootChainManager {
    function depositFor(address user, address rootToken, bytes calldata depositData) external;

    function depositEtherFor(address user) external payable;
}
