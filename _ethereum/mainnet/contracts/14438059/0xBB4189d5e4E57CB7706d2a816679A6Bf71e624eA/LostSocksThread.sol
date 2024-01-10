// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ControllableUpgradeable.sol";
import "./draft-ERC20PermitUpgradeable.sol";

/// @title Lost Socks Thread
contract LostSocksThread is
  OwnableUpgradeable,
  PausableUpgradeable,
  ControllableUpgradeable,
  ERC20Upgradeable,
  ERC20PermitUpgradeable
{
  /// @notice If owners have already preminted.
  bool public preminted;

  /// @notice Max supply.
  uint256 public constant MAX_SUPPLY = 30_000_000 * 10**18;

  function initialize() external initializer {
    __Ownable_init();
    __Controllable_init();
    __ERC20_init("Lost Socks Thread", "THREAD");
    __ERC20Permit_init("Lost Socks Thread");
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Add or edit contract controllers.
  /// @param addrs Array of addresses to be added/edited.
  /// @param state New controller state of addresses.
  function setControllers(address[] calldata addrs, bool state) external onlyOwner {
    for (uint256 i = 0; i < addrs.length; i++) super._setController(addrs[i], state);
  }

  /// @notice Switch the contract paused state between paused and unpaused.
  function togglePaused() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  /// @notice Let owners premint their amount onceX.
  function premint(address to) external onlyOwner {
    require(!preminted, "Already preminted");
    preminted = true;
    super._mint(to, 7_480_000 * 10**18);
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-20 Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Mint tokens.
  /// @param to Address to get tokens minted to.
  /// @param value Number of tokens to be minted.
  function mint(address to, uint256 value) external onlyController {
    require(totalSupply() + value <= MAX_SUPPLY, "Max supply exceeded");
    super._mint(to, value);
  }

  /// @notice Burn tokens.
  /// @param from Address to get tokens burned from.
  /// @param value Number of tokens to be burned.
  function burn(address from, uint256 value) external onlyController {
    super._burn(from, value);
  }

  /// @notice See {ERC20-_beforeTokenTransfer}.
  /// @dev Overriden to block transactions while the contract is paused (avoiding bugs).
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
  }
}
