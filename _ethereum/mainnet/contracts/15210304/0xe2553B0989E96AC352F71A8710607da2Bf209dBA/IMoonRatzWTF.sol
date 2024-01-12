// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC721.sol";
import "./Counters.sol";
import "./AccessLock.sol";

/// @title IMoonRatzWTF
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Interface for the MoonRatzWTF NFT contract
interface IMoonRatzWTF is IERC721 {
    /// @notice - Mint NFT
    /// @dev - callable only by admin
    /// @param recipient - mint to
    /// @param quantity - number of NFTs to mint
    function mint(address recipient, uint256 quantity) external;
}
