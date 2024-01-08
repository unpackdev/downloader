// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

import "./ERC20Permit.sol";

/**
 * @title WiseToken
 * @dev WISE ERC20 Token
 */


contract WiseToken is ERC20Permit, Ownable {
  constructor(
    string memory name,
    string memory symbol,
    uint256 totalSupply
  ) ERC20(name, symbol) {
    _mint(msg.sender, totalSupply);
  }

  /**
    * @notice Function to rescue funds
    * Owner is assumed to be a governance/multi-sig, Which will be used to rescue accidently sent user tokens
    * In case of no use this funtion can be disabled by destroying ownership via `renounceOwnership` function
    * @param token Address of token to be rescued
    * @param destination User address
    * @param amount Amount of tokens
    */
  function rescueTokens(
    address token,
    address destination,
    uint256 amount
  ) external onlyOwner {
    require(token != destination, "Invalid address");
    require(ERC20(token).transfer(destination, amount), "Retrieve failed");
  }
}
