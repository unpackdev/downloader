// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";

/**
 * @title Whitelisted transfer restriction example
 * @dev Example of simple transfer rule, having a list
 * of whitelisted addresses manged by owner, and checking
 * that from and to address in src20 transfer are whitelisted.
 */
contract Whitelisted is Ownable {
  mapping(address => bool) internal whitelisted;

  event AccountWhitelisted(address account, address sender);
  event AccountUnWhitelisted(address account, address sender);

  function whitelistAccount(address _account) external virtual onlyOwner {
    whitelisted[_account] = true;
    emit AccountWhitelisted(_account, msg.sender);
  }

  function bulkWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      whitelisted[account] = true;
      emit AccountWhitelisted(account, msg.sender);
    }
  }

  function unWhitelistAccount(address _account) external virtual onlyOwner {
    delete whitelisted[_account];
    emit AccountUnWhitelisted(_account, msg.sender);
  }

  function bulkUnWhitelistAccount(address[] calldata _accounts) external virtual onlyOwner {
    for (uint256 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];
      delete whitelisted[account];
      emit AccountUnWhitelisted(account, msg.sender);
    }
  }

  function isWhitelisted(address _account) public view returns (bool) {
    return whitelisted[_account];
  }
}
