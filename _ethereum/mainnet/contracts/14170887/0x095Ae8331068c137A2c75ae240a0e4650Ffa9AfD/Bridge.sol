// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

//   $$$$$$$\  $$$$$$$$\ $$\       $$\        $$$$$$\  $$$$$$$\
//   $$  __$$\ $$  _____|$$ |      $$ |      $$  __$$\ $$  __$$\
//   $$ |  $$ |$$ |      $$ |      $$ |      $$ /  $$ |$$ |  $$ |
//   $$$$$$$  |$$$$$\    $$ |      $$ |      $$$$$$$$ |$$$$$$$  |
//   $$  ____/ $$  __|   $$ |      $$ |      $$  __$$ |$$  __$$<
//   $$ |      $$ |      $$ |      $$ |      $$ |  $$ |$$ |  $$ |
//   $$ |      $$$$$$$$\ $$$$$$$$\ $$$$$$$$\ $$ |  $$ |$$ |  $$ |
//   \__|      \________|\________|\________|\__|  \__|\__|  \__|
//
//  Pellar 2022

contract Bridge is Ownable {
  struct TokenInfo {
    address contractAddress;
    uint256 tokenId;
  }

  // variables
  TokenInfo[] public tokens;

  /**
   * View
   */
  function balanceOf(address _account) public view returns (uint256) {
    uint256 balance = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      TokenInfo memory token = tokens[i];
      balance += IERC1155(token.contractAddress).balanceOf(_account, token.tokenId);
    }
    return balance;
  }

  /**
   * Admin
   */
  function setTokens(TokenInfo[] calldata _tokens) external onlyOwner {
    delete tokens;
    for (uint256 i = 0; i < _tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
  }

  function addTokens(TokenInfo[] calldata _tokens) external onlyOwner {
    for (uint256 i = 0; i < _tokens.length; i++) {
      tokens.push(_tokens[i]);
    }
  }
}

interface IERC1155 {
  function balanceOf(address, uint256) external view returns (uint256);
}
