// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./IERC721Metadata.sol";

/// @title IPilgrimMetaNFT
///
/// @notice An interface of Pilgrim Meta NFT contract.
interface IPilgrimMetaNFT is IERC721 {
    function setCore(address _core) external;
    function safeMint(address _to) external returns (uint256 _tokenId);
    function burn(uint256 _tokenId) external;
}
