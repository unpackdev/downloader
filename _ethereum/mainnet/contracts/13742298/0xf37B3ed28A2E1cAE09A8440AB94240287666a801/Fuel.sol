// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FurProxy.sol";

/// @title Fuel
/// @author LFG Gaming LLC
/// @notice Simple tracker for how much ETH a user has deposited into Furballs' pools, etc.
contract Fuel is FurProxy {
  mapping(address => uint256) public tank;

  uint256 public conversionRate = 100000000000;

  constructor(address furballsAddress) FurProxy(furballsAddress) { }

  /// @notice Change ETH/Fuel ratio
  function setConversion(uint256 rate) external gameModerators {
    conversionRate = rate;
  }

  /// @notice Direct deposit function
  /// @dev Pass zero address to apply to self
  function deposit(address to) external payable {
    require(msg.value > 0, "VALUE");
    if (to == address(0)) to = msg.sender;
    tank[to] += msg.value / conversionRate;
  }

  /// @notice Sends payout to the treasury
  function settle(uint256 amount) external gameModerators {
    if (amount == 0) amount = address(this).balance;
    furballs.governance().treasury().transfer(amount);
  }

  /// @notice Increases balance
  function gift(address[] calldata tos, uint256[] calldata amounts) external gameModerators {
    for (uint i=0; i<tos.length; i++) {
      tank[tos[i]] += amounts[i];
    }
  }

  /// @notice Decreases balance. Returns the amount withdrawn, where zero indicates failure.
  /// @dev Does not require/throw, but empties the balance when it exceeds the requested amount.
  function burn(address from, uint256 amount) external gameModerators returns(uint) {
    return _burn(from, amount);
  }

  /// @notice Burn lots of fuel from different players
  function burnAll(
    address[] calldata wallets, uint256[] calldata requestedFuels
  ) external gameModerators {
    for (uint i=0; i<wallets.length; i++) {
      _burn(wallets[i], requestedFuels[i]);
    }
  }

  /// @notice Internal burn
  function _burn(address from, uint256 amount) internal returns(uint) {
    uint256 bal = tank[from];
    if (bal == 0) {
      return 0;
    } else if (bal > amount) {
      tank[from] = bal - amount;
    } else {
      amount = bal;
      tank[from] = 0;
    }
    return amount;
  }
}
