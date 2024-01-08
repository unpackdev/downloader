// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./TokenTraits.sol";

/// @notice Interface to interact with the VampireGame contract
interface IVampireGame {
    /// @notice get the total supply of gen-0
    function getGenZeroSupply() external view returns (uint256);

    /// @notice get the total supply of tokens
    function getMaxSupply() external view returns (uint256);

    /// @notice get the TokenTraits for a given tokenId
    function getTokenTraits(uint256 tokenId) external view returns (TokenTraits memory);

    /// @notice returns true if a token is aleady revealed
    function isTokenRevealed(uint256 tokenId) external view returns (bool);
}

/// @notice Interface to control parts of the VampireGame ERC 721
interface IVampireGameControls {
    /// @notice mint any amount of nft to any address
    /// Requirements:
    /// - message sender should be an allowed address (game contract)
    /// - amount + totalSupply() has to be smaller than MAX_SUPPLY
    function mintFromController(address receiver, uint256 amount) external;

    /// @notice reveal a list of tokens using specific seeds for each
    function controllerRevealTokens(uint256[] calldata tokenIds, uint256[] calldata _seeds) external;
}
