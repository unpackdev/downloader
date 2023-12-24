// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITradingTokenFactoryV1.sol";
import "./TradingTokenV1.sol";
import "./Authorizable.sol";
import "./Pausable.sol";

contract TradingTokenFactoryV1 is ITradingTokenFactoryV1, Authorizable, Pausable {
  constructor() Authorizable(_msgSender()) {}

  function createToken(
    string memory name_, 
    string memory symbol_, 
    uint8 decimals_,
    uint256 totalSupply_,
    address owner_,
    uint256[] memory tokenData
  ) external virtual override onlyAuthorized onlyNotPaused returns (address) {
    TradingTokenV1 token;

    token = new TradingTokenV1(
      name_, 
      symbol_, 
      decimals_,
      totalSupply_,
      owner_,
      tokenData
    );

    return address(token);
  }
}
