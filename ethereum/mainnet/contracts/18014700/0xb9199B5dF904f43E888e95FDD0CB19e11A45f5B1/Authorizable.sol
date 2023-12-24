// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizable.sol";
import "./OwnableV2.sol";

abstract contract Authorizable is IAuthorizable, OwnableV2 {
  constructor(address owner_) OwnableV2(owner_) {}

  mapping(address => bool) internal _authorized;

  modifier onlyAuthorized() {
    require(_isAuthorized(_msgSender()), "Unauthorized");
    _;
  }

  function _isAuthorized(address account) internal virtual view returns (bool) {
    // always return true for the owner
    return account == _owner() ? true : _authorized[account];
  }

  function isAuthorized(address account) external view override returns (bool) {
    return _isAuthorized(account);
  }

  function _authorize(address account, bool value) internal virtual {
    _authorized[account] = value;

    emit Authorized(account, value);
  }

  /** @dev only allow the owner to authorize more accounts */
  function authorize(address account, bool value) external override onlyOwner {
    _authorize(account, value);
  }
}
