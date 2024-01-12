//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC20.sol";
import "./CitizenAlpha.sol";

contract TrustToken is ERC20 {
  CitizenAlpha private citizenAlpha;
  uint256 private distribution = 1000e18;
  mapping(address => bool) private _claimed;

  constructor(
    CitizenAlpha citizenAlpha_,
    string memory name,
    string memory symbol
  ) ERC20(name, symbol) {
    citizenAlpha = citizenAlpha_;
  }

  function claim() external {
    require(citizenAlpha.isCitizen(msg.sender), "TrustToken:not-trusted");
    require(!_claimed[msg.sender], "TrustToken:trust-previously-issued");
    _claimed[msg.sender] = true;
    _mint(msg.sender, distribution);
  }
}
