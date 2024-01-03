// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.10;

interface IPowerOracleStaking {
  enum UserStatus { UNAUTHORIZED, CAN_REPORT, CAN_SLASH }

  /*** User Interface ***/
  function deposit(uint256 userId_, uint256 amount_) external;

  function withdraw(
    uint256 userId_,
    address to_,
    uint256 amount_
  ) external;

  function createUser(
    address adminKey_,
    address reporterKey_,
    uint256 depositAmount
  ) external;

  function updateUser(
    uint256 userId,
    address adminKey_,
    address reporterKey_
  ) external;

  /*** Owner Interface ***/
  function withdrawExtraCVP(address to) external;

  function setMinimalSlashingDeposit(uint256 amount) external;

  function setPowerOracle(address powerOracle) external;

  function setSlashingPct(uint256 slasherRewardPct, uint256 reservoirRewardPct) external;

  function pause() external;

  function unpause() external;

  /*** PowerOracle Contract Interface ***/
  function slash(uint256 slasherId_, uint256 overdueCount_) external;

  /*** Permissionless Interface ***/
  function setReporter(uint256 reporterId) external;

  /*** Viewers ***/
  function getReporterId() external view returns (uint256);

  function getHighestDeposit() external view returns (uint256);

  function getDepositOf(uint256 userId) external view returns (uint256);

  function getUserStatus(uint256 userId_, address reporterKey_) external view returns (UserStatus);

  function authorizeReporter(uint256 userId_, address reporterKey_) external view;

  function authorizeSlasher(uint256 userId_, address reporterKey_) external view;

  function requireValidAdminKey(uint256 userId_, address adminKey_) external view;
}
