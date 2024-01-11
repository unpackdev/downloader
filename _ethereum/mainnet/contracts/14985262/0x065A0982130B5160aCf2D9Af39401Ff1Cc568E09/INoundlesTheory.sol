// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

interface INoundlesTheory is IERC721 {
  // migration

  function alreadyClaimedMigration(uint256 _tokenId)
    external
    view
    returns (bool);

  function migrateOldNoundles(uint256[] memory _tokenIds) external;

  // noundle details

  function getNoundlesFromWallet(address _address)
    external
    view
    returns (uint256[] memory);

  function getTypeByTokenIds(uint256[] memory _tokenIds)
    external
    view
    returns (uint8[] memory);

  function noundleType(uint256 _tokenId) external view returns (uint8);

  function noundleOffsetCount(uint256 _tokenId) external view returns (uint256);

  function tokenURI(uint256 _tokenId) external view returns (string memory);

  // collection details

  function totalSupply() external view returns (uint256);

  function MAX_EVIL_NOUNDLES() external view returns (uint256);

  function mintCountCompanions() external view returns (uint256);

  function mintCountEvil() external view returns (uint256);

  function OG_TOTAL_SUPPLY() external view returns (uint256);

  // mint with rainbows

  function rainbowMintingEnabled() external view returns (bool);

  function costToMintWithRainbows() external view returns (uint256);

  function mintWithRainbows(uint256 _noundles) external;

  // balance

  function companionBalance(address owner) external view returns (uint256);

  function evilBalance(address owner) external view returns (uint256);
}
