// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721MetadataUpgradeable.sol";

interface IHeistPass is IERC721Upgradeable, IERC721MetadataUpgradeable {
  function getFee(uint256 amount) external view returns (uint256);
  function burn(uint256 tokenId, uint256 amount) external payable;
}