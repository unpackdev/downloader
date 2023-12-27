// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./CF_Ownable.sol";
import "./CF_Common.sol";

abstract contract CF_Whitelist is CF_Ownable, CF_Common {
  event Whitelisted(address indexed account, bool status);
  event RenouncedWhitelist();

  /// @notice Permanently renounce and prevent the owner from being able to update the whitelist
  /// @dev Existing entries will continue to be effective
  function renounceWhitelist() external onlyOwner {
    _renounced.Whitelist = true;

    emit RenouncedWhitelist();
  }

  /// @notice Check if an address is whitelisted
  /// @param account Address to check
  function isWhitelisted(address account) external view returns (bool) {
    return _whitelisted[account];
  }

  /// @notice Add or remove an address from the whitelist
  /// @param status True for adding, False for removing
  function whitelist(address account, bool status) public onlyOwner {
    _whitelist(account, status);
  }

  function _whitelist(address account, bool status) internal {
    require(!_renounced.Whitelist);
    require(account != address(0) && account != address(0xdEaD));
    require(account != _dex.router && account != _dex.pair, "DEX router and pair are privileged");

    if (status) { require(!_blacklisted[account], "Blacklisted"); }

    _whitelisted[account] = status;

    emit Whitelisted(account, status);
  }

  /// @notice Add or remove multiple addresses from the whitelist
  /// @param status True for adding, False for removing
  function whitelist(address[] calldata accounts, bool status) external onlyOwner {
    unchecked {
      uint256 cnt = accounts.length;

      for (uint256 i; i < cnt; i++) { _whitelist(accounts[i], status); }
    }
  }

  function _initialWhitelist(address[1] memory accounts) internal {
    require(!_initialized);

    unchecked {
      for (uint256 i; i < 1; i++) { _whitelist(accounts[i], true); }
    }
  }
}
