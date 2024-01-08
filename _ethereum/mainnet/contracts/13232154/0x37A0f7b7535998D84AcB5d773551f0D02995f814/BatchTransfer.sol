// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./IERC721.sol";

/**
 * @title BatchTransfer
 * @author MirrorXYZ
 */
contract BatchTransfer {
    // ============ Edition Methods ============

    function batchTransfer(
        address editions,
        address[] memory addresses,
        uint256[] memory tokenIds
    ) external {
        require(
            addresses.length == tokenIds.length,
            "Arrays must be equal length"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC721(editions).transferFrom(
                msg.sender,
                addresses[i],
                tokenIds[i]
            );
        }
    }
}
