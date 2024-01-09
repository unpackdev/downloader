// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract WhitelistVerifier is Ownable {
  uint256 public maxToClaim;
  bool public wlMintCapEnabled;
  mapping(address => uint256) claimList;
  mapping(address => bool) whitelist;

  modifier whenCapIsSet() {
    require(!wlMintCapEnabled || maxToClaim > 0, 'Whitelist cap is set incorrectly.');
    _;
  }

  constructor() {
    // Set initial max number of whitelist items to claim.
    maxToClaim = 0;
    wlMintCapEnabled = false;
  }

  function isWhitelisted(address addr) external view returns (bool) {
    return checkAddress(addr);
  }

  function canClaimWLTokens(address addr, uint256 amount) external view returns (bool) {
    return canClaim(addr, amount);
  }

  function getClaimableWLAmount(address addr) external view returns (uint256) {
    return claimableAmount(addr);
  }

  function checkAddress(address addr) internal view whenCapIsSet returns (bool) {
    require(whitelist[addr], 'Addreess is not whitelisted');
    return true;
  }

  function canClaim(address addr, uint256 amount) internal view whenCapIsSet returns (bool) {
    if (wlMintCapEnabled) {
      require(claimableAmount(addr) >= amount, 'Too many tokens to claim in WL');
    } else {
      return checkAddress(addr);
    }

    return true;
  }

  function claimableAmount(address addr) private view returns (uint256) {
    if (checkAddress(addr)) {
      if (claimList[addr] >= maxToClaim) {
        return 0;
      }

      return maxToClaim - claimList[addr];
    }

    return 0;
  }

  function addClaimed(address addr, uint256 amount) internal {
    claimList[addr] = claimList[addr] + amount;
  }

  // Admin functions

  function setClaimCap(uint256 max, bool enableCap) external onlyOwner {
    maxToClaim = max;
    wlMintCapEnabled = enableCap;
  }

  function updateWhitelist(address[] memory addresses, bool remove) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add the null address");

      whitelist[addresses[i]] = remove ? false : true;
    }
  }
}
