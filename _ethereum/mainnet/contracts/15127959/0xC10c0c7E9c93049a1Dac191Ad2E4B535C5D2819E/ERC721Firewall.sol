// SPDX-License-Identifier: MIT
pragma solidity =0.8.6;

import "./Whitelist.sol";
import "./Allocator.sol";

contract ERC721Firewall is Allocator, Whitelist {
    
    constructor(uint256 baseMaxAllocation_, Phase[] memory phases_) {
        initializeWhitelist();
        setWhitelistActive(false);
        initializeAllocator();
        setAllocatorActive(false);
        setBaseAllocation(baseMaxAllocation_);
        if (phases_.length > 0) setPhases(phases_);
    }
}