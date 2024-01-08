// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC20Upgradeable.sol";

// The ATTRToken is the Attrace utility token.
// More info: https://attrace.com
//
// We keep the contract upgradeable during development to make sure we can evolve and implement gas optimizations later on.
//
// Upgrade strategy towards DAO:
// -  Pre-DAO: the token is managed and improved by the Attrace project.
// -  When DAO is achieved: the token will become owned by the DAO contracts, or if the DAO decides to lock the token, then it can do so by transferring ownership to a contract which can't be upgraded.
contract ATTRToken is ERC20Upgradeable {

  // Accounts which can transfer out in the pre-listing period
  mapping(address => bool) private _preListingAddrWL;

  // Timestamp when rules are disabled, once this time is reached, this is irreversible
  uint64 private _wlDisabledAt;

  // Who can modify _preListingAddrWL and _wlDisabledAt (team doing the listing).
  address private _wlController;

  function initialize(address preListWlController) public initializer {
    __ERC20_init("Attrace", "ATTR");
    _mint(msg.sender, 10 ** 27); // 1000000000000000000000000000 aces, 1,000,000,000 ATTR
    _wlController = address(preListWlController);
    _wlDisabledAt = 1623146400; // June 8 2021
  }

  // Public API
  function setPreReleaseAddressStatus(address addr, bool status) public {
    require(_wlController == msg.sender);
    _preListingAddrWL[addr] = status;
  }

  // Once rules are disabled, rules remain disabled
  // While not expected to be used, in case of need (to support optimal listing), the team can control the time the token becomes tradeable.
  function setNoRulesTime(uint64 disableTime) public {
    require(_wlController == msg.sender); // Only controller can 
    require(_wlDisabledAt > uint64(block.timestamp)); // Can not be set anymore when rules are already disabled
    require(disableTime > uint64(block.timestamp)); // Has to be in the future
    _wlDisabledAt = disableTime;
  }

  // Hook into openzeppelin's ERC20Upgradeable flow to support golive requirements
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
    super._beforeTokenTransfer(from, to, amount);

    // When not yet released, verify that the sender is white-listed.
    if(_wlDisabledAt > block.timestamp) {
      require(_preListingAddrWL[from] == true, "not yet tradeable");
    }
  }
}
