// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";

interface IMintClubIncinerator {
  function burnGoldTokens(address _tokenOwner, uint256 _qty) external;
  function burnBasicTokens(address _tokenOwner, uint256 _qty) external;
}
