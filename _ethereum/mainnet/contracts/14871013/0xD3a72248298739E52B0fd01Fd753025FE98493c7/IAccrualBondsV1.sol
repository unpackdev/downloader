// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IAccrualBondsV1 {

  /// @notice Access Control Roles
  function DEFAULT_ADMIN_ROLE() external view returns (bytes32);
  function POLICY_ROLE() external view returns (bytes32);
  function STAKING_ROLE() external view returns (bytes32);
  function TREASURY_ROLE() external view returns (bytes32);

  /// @notice Treasury Methods
  function setBeneficiary(address accrualTo) external;
  function setPolicyMintAllowance(uint256 mintAllowance) external;
  function addQuoteAsset(address token, uint256 virtualReserves, uint256 halfLife, uint256 levelBips) external;
  function grantRole(bytes32 role, address account) external;
  function revokeRole(bytes32 role, address account) external;
  function renounceRole(bytes32 role, address account) external;
  function pause() external;
  function unpause() external;

  /// @notice Treasury + Policy Methods
  function removeQuoteAsset(address token) external;
  function policyUpdate(uint256 supplyDelta, bool positiveDelta, uint256 percentToConvert, uint256 newVirtualOutputReserves, address[] memory tokens, uint256[] memory virtualReserves, uint256[] memory halfLives, uint256[] memory levelBips, bool[] memory updateElapsed) external;

  /// @notice User Methods
  function purchaseBond(address recipient, address token, uint256 input, uint256 minOutput) external returns (uint256 output);
  function purchaseBondUsingPermit(address recipient, address token, uint256 input, uint256 minOutput, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (uint256 output);
  function redeemBond(address recipient, uint256 bondId) external returns (uint256 output);
  function redeemBondBatch(address recipient, uint256[] memory bondIds) external returns (uint256 output);
  function transferBond(address recipient, uint256 bondId) external;

  /// @notice View Methods
  function getAmountOut(address token, uint256 input) external view returns (uint256 output);
  function getAvailableSupply() external view returns (uint256);
  function getRoleAdmin(bytes32 role) external view returns (bytes32);
  function getSpotPrice(address token) external view returns (uint256);
  function getUserPositionCount(address guy) external view returns (uint256);
  function paused() external view returns (bool);
  function outputToken() external view returns (address);
  function term() external view returns (uint256);
  function totalAssets() external view returns (uint256);
  function totalDebt() external view returns (uint256);
  function beneficiary() external view returns (address);
  function cnvEmitted() external view returns (uint256);
  function virtualOutputReserves() external view returns (uint256);
  function policyMintAllowance() external view returns (uint256);
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function hasRole(bytes32 role, address account) external view returns (bool);
  function positions(address, uint256) external view returns (uint256 owed, uint256 redeemed, uint256 creation);
  function quoteInfo(address) external view returns (uint256 virtualReserves, uint256 lastUpdate, uint256 halfLife, uint256 levelBips);

  /// @notice Staking Methods
  function vebase() external returns (bool);
}
