// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

contract FreezableFeature {
  mapping(address => bool) private frozen;

  event AccountFrozen(address indexed account);
  event AccountUnfrozen(address indexed account);

  function _freezeAccount(address _account) internal {
    frozen[_account] = true;
    emit AccountFrozen(_account);
  }

  function _unfreezeAccount(address _account) internal {
    frozen[_account] = false;
    emit AccountUnfrozen(_account);
  }

  function _isAccountFrozen(address _account) internal view returns (bool) {
    return frozen[_account];
  }
}
