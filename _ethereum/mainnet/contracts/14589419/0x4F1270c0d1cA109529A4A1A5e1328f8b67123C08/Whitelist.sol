// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./console.sol";

contract Whitelist is Context {
  // list of all whitelisted wallets
  mapping(address => bool) private _whitelistedWallets;

  event WalletAddedToWhitelist(address indexed account);
  event WalletRemovedFromWhitelist(address indexed account);

  constructor() {
    _add(_msgSender());
  }

  function _add(address account) internal virtual {
      _whitelistedWallets[account] = true;
      emit WalletAddedToWhitelist(account);
  }

  function _remove(address account) internal virtual {
      require(_whitelistedWallets[account], "Whitelist: address not found");
      delete _whitelistedWallets[account];
      emit WalletRemovedFromWhitelist(account);
  }

  function isWalletWhitelisted(address account) public view returns (bool) {
      return _whitelistedWallets[account];
  } 
}
