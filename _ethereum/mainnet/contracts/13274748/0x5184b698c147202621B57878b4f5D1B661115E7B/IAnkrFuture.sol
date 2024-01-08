// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./ERC721EnumerableUpgradeable.sol";

interface IAnkrFuture {

    function initialize(address operator, address pool, string memory token, uint256 defaultMaturity, uint8 initDecimals, string memory baseUri) external;

    function mint(address to, uint256 maturityBlock, uint256 futureValue) external;

    function burn(uint256 tokenId) external;

    function getDefaultMaturityBlocks() external view returns (uint256);

    function getMaturity(uint256 tokenId) external view returns (uint256);

    function getAmount(uint256 tokenId) external view returns (uint256);

    function decimals() external view returns (uint8);
}