// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./Counters.sol";
import "./AccessLock.sol";

/// @title ITrippyFrens3D
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Interface for the T3IPPY NFT contract
interface ITrippyFrens3D is IERC721 {
    /// @notice - Mint NFT
    /// @dev - callable only by admin
    /// @param recipient - mint to
    /// @param quantity - number of NFTs to mint
    function mint(address recipient, uint256 quantity) external;

    /// @dev See {IERC721Enumerable-totalSupply}.
    /// @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
    function totalSupply() external returns (uint256);
}
