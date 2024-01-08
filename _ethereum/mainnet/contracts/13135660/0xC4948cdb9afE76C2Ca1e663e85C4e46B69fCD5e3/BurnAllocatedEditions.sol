// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721.sol";
import "./IAllocatedEditionsLogic.sol";

/**
 * @title BurnAllocatedEditions
 * @author MirrorXYZ
 */
contract BurnAllocatedEditions {
    // ============ Storage for Setup ============

    /// @notice Edition Config
    address public editions;

    // ============ Constructor ============

    constructor(address editions_) {
        editions = editions_;
    }

    // ============ Edition Methods ============

    function batchBurn(uint256 fromTokenId, uint256 toTokenId) external {
        require(
            fromTokenId <= toTokenId,
            "fromTokenId should be less than or equal to toTokenId"
        );

        for (uint256 i = fromTokenId; i <= toTokenId; i++) {
            IERC721(editions).transferFrom(msg.sender, address(this), i);
            IAllocatedEditionsLogic(editions).burn(i);
        }
    }
}
