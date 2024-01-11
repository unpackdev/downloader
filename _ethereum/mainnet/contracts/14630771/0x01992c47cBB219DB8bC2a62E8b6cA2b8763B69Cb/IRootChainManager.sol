// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @dev see https://github.com/maticnetwork/pos-portal/blob/v1.1.0/contracts/root/RootChainManager/RootChainManager.sol
interface IRootChainManager {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external;

    function rootToChildToken(address rootToken) external returns (address);
}
