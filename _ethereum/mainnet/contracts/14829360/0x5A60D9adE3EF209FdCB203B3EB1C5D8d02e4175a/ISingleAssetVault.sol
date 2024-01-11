// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

import "./IERC20.sol";

import "./OndoLibrary.sol";
import "./ITrancheToken.sol";

interface ISingleAssetVault {
  // Events
  event Deposit(address indexed user, uint256 amount, uint256 investFromIndex);
  event Withdraw(
    address indexed user,
    uint256 amount,
    address indexed recipient
  );
  event MassUpdateUserBalance(address indexed user);
  event Invest(
    uint256 indexed poolId,
    address indexed strategist,
    address indexed strategy,
    uint256 amount,
    bytes data
  );
  event Redeem(
    uint256 indexed poolId,
    address indexed redeemer,
    uint256 amount,
    bytes data
  );

  // Enums / Structs
  enum ActionType {Invest, Redeem}

  /**
   * redeem rollover will have two steps
   * 1. redeem from rollover -> will update vaultId field with withdrawn vault id
   * 2. redeem from vault once redeem state
   */
  struct PoolData {
    bool isPassive;
    uint256 investAmount;
    address strategy;
    address strategist;
    uint256 depositMultiplier;
    uint256 redemptionMultiplier;
    bool redeemed;
  }
  struct Action {
    ActionType actionType;
    uint256 poolId;
  }
  struct UserDeposit {
    uint256 amount;
    uint256 firstActionId;
  }

  // Functions

  function asset() external view returns (IERC20);
}
