// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RToken.sol";

interface IBridgeTokenManager {
    event TokenAdded(address indexed addr, uint256 chainId);
    event TokenRemoved(address indexed addr, uint256 chainId);
    event LimitUpdated(address indexed addr, uint256 amt);

    function issue(
        RToken.Token calldata sourceToken,
        RToken.Token calldata targetToken
    ) external;

    function revoke(address targetAddr, uint256 targetChainId) external;

    function getLocal(
        address sourceAddr,
        uint256 sourceChainId,
        uint256 targetChainId
    ) external view returns (RToken.Token memory token);

    function setLimit(address tokenAddr, uint256 amt) external;

    function limits(address tokenAddr) external view returns (uint256);
}
