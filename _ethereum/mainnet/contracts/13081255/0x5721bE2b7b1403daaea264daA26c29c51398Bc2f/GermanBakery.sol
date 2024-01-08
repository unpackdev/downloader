// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg / Twitter @divergence_art
// All Rights Reserved
pragma solidity >=0.8.0 <0.9.0;

import "./Brotchain.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";

/**
 * @dev German bakeries make brot.
 *
 * After deployment we discoverd a bug in the Brotchain early-access allocator
 * that exposed a loophole if someone transferred their Brot after minting, thus
 * allowing for unlimited mints. This contract is the fix and acts as a proxy
 * minter with correct allocation limiting. The entire Brotchain supply is thus
 * allocated to this contract.
 */
contract GermanBakery is Ownable, ERC721Holder, ReentrancyGuard {
    Brotchain public brotchain;
    
    constructor(address _brotchain) {
        brotchain = Brotchain(_brotchain);
    }

    /**
     * @dev Remaining allocation for addresses.
     */
    mapping(address => int256) public allocRemaining;

    /**
     * @dev Received by changeAllocation() in lieu of a mapping.
     */
    struct AllocationDelta {
        address addr;
        int80 value;
    }

    /**
     * @dev Changes the remaining allocation for the specified addresses.
     */
    function changeAllocations(AllocationDelta[] memory deltas) external onlyOwner {
        for (uint256 i = 0; i < deltas.length; i++) {
            allocRemaining[deltas[i].addr] += deltas[i].value;
        }
    }

    /**
     * @dev Calls Brotchain.safeMint() and transfers the token to the sender.
     *
     * This correctly implements early-access limiting by decrementing the
     * sender's allocation instead of comparing the balance to the allocation as
     * the Brotchain contract does. This was vulnerable to tokens be transferred
     * before minting again.
     */
    function safeMint() external payable nonReentrant {
        // CHECKS
        require(allocRemaining[msg.sender] > 0, "Address allocation exhausted");

        // EFFECTS
        allocRemaining[msg.sender]--;
        brotchain.safeMint{value: msg.value}();

        // INTERACTIONS
        // As the token is immediately transferred, it will always be index 0.
        address self = address(this);
        uint256 tokenId = brotchain.tokenOfOwnerByIndex(self, 0);
        brotchain.safeTransferFrom(self, msg.sender, tokenId);
    }
}