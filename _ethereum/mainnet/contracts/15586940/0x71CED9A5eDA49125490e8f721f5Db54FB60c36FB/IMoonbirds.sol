// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./IERC2981.sol";
import "./IERC721.sol";
/**
@dev A minimal interface for interaction with the Moonbirds contract.
 */
interface IMoonbirds is IERC721, IERC2981 {
    function safeTransferWhileNesting(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function nestingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool nesting,
            uint256 current,
            uint256 total
        );
}
