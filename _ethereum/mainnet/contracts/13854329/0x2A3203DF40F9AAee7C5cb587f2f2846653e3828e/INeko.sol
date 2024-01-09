// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721Enumerable.sol";

interface INeko {
    // Helper functions for getting all tokens of a owner
    function tokensOfOwner(address owner) external view returns (uint256[] memory tokenIds);
}
