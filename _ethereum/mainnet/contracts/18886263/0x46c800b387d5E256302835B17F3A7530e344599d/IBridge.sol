// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISwapper.sol";

interface IBridge is ISwapper {
    error ZeroTokens();
    error InvalidPlanetsArray();

    event Bridged(
        uint256 nonce,
        uint16 dstChainId,
        address userAddress,
        Claim claim
    );
    event TreasurySet(address treasury);
}
