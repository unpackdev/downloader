// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./NFTYieldedToken.sol";

/// @custom:security-contact astridfox@protonmail.com
contract CHILL is NFTYieldedToken {

    uint256 constant public PROJECT_ALLOCATION = 5000000 * 10**18;

    uint256 constant public YIELD_STEP = 86400;

    uint256 constant public YIELD = 10**19;
    constructor(
        address admin,
        address pauser,
        address minter,
        address yieldManager,
        uint256 epoch_,
        uint256 horizon_,
        address nftContractAddress
    )
    NFTYieldedToken(
        "CHILL",
        "CHILL",
        admin,
        pauser,
        minter,
        yieldManager,
        YIELD_STEP,
        YIELD,
        epoch_,
        horizon_,
        nftContractAddress
    )
    {
        _mint(0x7A105DFD75713c1FDd592E1F9f81232Fa3E74945, PROJECT_ALLOCATION);
    }
}