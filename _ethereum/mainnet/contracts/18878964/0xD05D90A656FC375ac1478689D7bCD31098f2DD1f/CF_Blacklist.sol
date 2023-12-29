// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";

abstract contract CF_Blacklist is CF_Ownable, CF_Common {
  event Blacklisted(address indexed account, bool status);
  event RenouncedBlacklist();

  /// @notice Permanently renounce and prevent the owner from being able to update the blacklist
  /// @dev Existing entries will continue to be effective
  function renounceBlacklist() external onlyOwner {
    _renounced.Blacklist = true;

    emit RenouncedBlacklist();
  }

  /// @notice Check if an address is blacklisted.
  /// @param account Address to check
  function isBlacklisted(address account) external view returns (bool) {
    return _blacklisted[account];
  }

  /// @notice Add or remove an address from the blacklist
  /// @param status True for adding, False for removing
  function blacklist(address account, bool status) public onlyOwner {
    _blacklist(account, status);
  }

  function _blacklist(address account, bool status) internal {
    require(!_renounced.Blacklist);
    require(account != _owner && account != address(0) && account != address(0xdEaD));
    require(account != _dex.router && account != _dex.pair, "DEX router or pair");

    if (status) { require(!_whitelisted[account], "Whitelisted"); }

    _blacklisted[account] = status;

    emit Blacklisted(account, status);
  }

  /// @notice Add or remove multiple addresses from the blacklist
  /// @param status True for adding, False for removing
  function blacklist(address[] calldata accounts, bool status) external onlyOwner {
    unchecked {
      uint256 cnt = accounts.length;

      for (uint256 i; i < cnt; i++) { _blacklist(accounts[i], status); }
    }
  }
}
