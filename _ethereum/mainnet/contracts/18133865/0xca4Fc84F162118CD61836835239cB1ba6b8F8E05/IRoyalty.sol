// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IERC2981.sol";

interface IRoyalty is IERC2981 {
    struct RoyaltyInfo {
        address recipient;
        uint256 bps;
    }

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(
        uint256 tokenId
    ) external view returns (address, uint16);
}
