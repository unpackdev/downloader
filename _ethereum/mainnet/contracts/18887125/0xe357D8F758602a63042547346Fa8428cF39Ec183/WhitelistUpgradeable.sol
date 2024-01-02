// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdministrableUpgradeable.sol";
import "./EnumerableSetUpgradeable.sol";

error NotAdmin();
error BlacklistedAddress();

abstract contract WhitelistUpgradeable is Initializable, AdministrableUpgradeable {
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  // keccak256("WHITELIST_ADMIN_ROLE")
  bytes32 public constant WHITELIST_ADMIN_ROLE =
    0xe9ea3f660aa5a8eccd1bf9d16e6cdf3c1cf9a2b284b830f15bda4493942cb68f;

  // keccak256("BLACKLIST_ADMIN_ROLE")
  bytes32 public constant BLACKLIST_ADMIN_ROLE =
    0x167d8d68b016f9cc1b8fb15b910e43cbad3223c8d98cf24f4b170dbd14933df1;

  mapping(address => EnumerableSetUpgradeable.AddressSet)
  private _tokenWhitelist;

  EnumerableSetUpgradeable.AddressSet private _blacklist;

  modifier onlyAdmin() {
    _onlyAdmin(msg.sender);
    _;
  }

  modifier onlyWhitelistAdmin() {
    if(
      !(hasRole(WHITELIST_ADMIN_ROLE, _msgSender()) ||
        hasRole(ADMIN_ROLE, _msgSender()))
    ) revert NotAdmin();
    _;
  }

  modifier onlyBlacklistAdmin() {
    if(
      !(hasRole(BLACKLIST_ADMIN_ROLE, _msgSender()) ||
      hasRole(ADMIN_ROLE, _msgSender()))
    ) revert NotAdmin();
    _;
  }

  function isWhitelisted(address token, address account) public view returns (bool)
  {
    if (_blacklist.contains(account)) {
      return false;
    }

    return _tokenWhitelist[token].contains(account);
  }

  function isBlacklisted(address account) public view returns (bool) {
    return _blacklist.contains(account);
  }

  function addToWhitelist(address token, address account) public onlyWhitelistAdmin {
    if (_blacklist.contains(account))
      revert BlacklistedAddress();

    _tokenWhitelist[token].add(account);
  }

  function removeFromWhitelist(address token, address account) public onlyWhitelistAdmin {
    if (_tokenWhitelist[token].contains(account)) {
      _tokenWhitelist[token].remove(account);
    }
  }

  function addToBlacklist(address account) public onlyBlacklistAdmin {
    _blacklist.add(account);
  }

  function removeFromBlacklist(address account) public onlyBlacklistAdmin {
    _blacklist.remove(account);
  }

  function whitelistAddressAtIndex(address token, uint256 index) public view returns (address account) {
    return _tokenWhitelist[token].at(index);
  }

  function blacklistAddressAtIndex(uint256 index) public view returns (address) {
    return _blacklist.at(index);
  }

  function setWhitelistAdmin(address _whitelistAdmin, bool status) external onlyAdmin {
    if(status) {
      _setupRole(WHITELIST_ADMIN_ROLE, _whitelistAdmin);
    }else {
      _revokeRole(WHITELIST_ADMIN_ROLE, _whitelistAdmin);
    }
  }

  uint256[50] private __gap;
}
