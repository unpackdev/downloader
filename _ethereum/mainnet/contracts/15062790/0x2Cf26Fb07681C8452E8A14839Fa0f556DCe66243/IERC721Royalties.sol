// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721Upgradeable.sol";

interface IERC721Royalties is IERC721Upgradeable {
    function getRoyalty(uint256 tokenId) external view returns (address receiver, uint256 value);
}
