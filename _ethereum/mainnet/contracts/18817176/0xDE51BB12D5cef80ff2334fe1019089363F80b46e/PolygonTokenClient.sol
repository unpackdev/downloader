// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title PolygonTokenClient
/// @notice This contract client of Polygon Token Oracle
contract PolygonTokenClient {
    event PolygonTokenBalanceRequest(
        bytes32 indexed requestId, // unique id of the oracle request, story oracle backend would call back with id.
        address indexed requester, // address of smart contract which sending the oracle request
        address tokenAddress, // address of the token
        address tokenOwnerAddress, // address of the token owner
        address callbackAddr, // address of smart contract which implemented the callback function
        bytes4 callbackFunctionSignature // the callback function signature
    );

    function sendRequest(
        bytes32 requestId,
        address requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) external {
        emit PolygonTokenBalanceRequest(
            requestId,
            requester,
            tokenAddress,
            tokenOwnerAddress,
            callbackAddr,
            callbackFunctionSignature
        );
    }

}
