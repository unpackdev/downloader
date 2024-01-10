//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Types.sol";
import "./IERC721.sol";

interface ITwinesis is IERC721 {
    // Public constants

    function MAX_TOKENS() external view returns (uint256);

    function MINTING_PRICE() external view returns (uint256);

    function PUBLIC_MINTING_START_DATE() external view returns (uint256);

    // Minting

    function mintTwin() external payable;

    function mintTwins(uint256 amount) external payable;

    // Twinesis metadata

    function outsetDate(uint256 tokenId) external view returns (uint256);

    function timeSinceOutset(uint256 tokenId) external view returns (uint256);

    function raritiesHaveBeenRevealed() external view returns (bool);

    function rarity(uint256 tokenId) external view returns (Rarity);

    function level(uint256 tokenId) external view returns (Level);

    function journeyPercentage(uint256 tokenId) external view returns (uint256);

    // ERC721 extensions

    function contractURI() external view returns (string memory);

    function exists(uint256 tokenId) external view returns (bool);

    function mintedTokens() external view returns (uint256);

    function tokensToMint() external view returns (uint256);

    // Withdrawal

    function withdraw() external;
}
