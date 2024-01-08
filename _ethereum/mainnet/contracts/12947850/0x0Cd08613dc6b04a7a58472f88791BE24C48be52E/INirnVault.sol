// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IAdapterRegistry.sol";
import "./ITokenAdapter.sol";
import "./IRewardsSeller.sol";


interface INirnVault {
/* ========== Events ========== */

  /** @dev Emitted when an adapter is removed and its balance fully withdrawn. */
  event AdapterRemoved(IErc20Adapter adapter);

  /** @dev Emitted when weights or adapters are updated. */
  event AllocationsUpdated(IErc20Adapter[] adapters, uint256[] weights);

  /** @dev Emitted when performance fees are claimed. */
  event FeesClaimed(uint256 underlyingAmount, uint256 sharesMinted);

  /** @dev Emitted when a rebalance happens without allocation changes. */
  event Rebalanced();

  /** @dev Emitted when max underlying is updated. */
  event SetMaximumUnderlying(uint256 maxBalance);

  /** @dev Emitted when fee recipient address is set. */
  event SetFeeRecipient(address feeRecipient);

  /** @dev Emitted when performance fee is set. */
  event SetPerformanceFee(uint256 performanceFee);

  /** @dev Emitted when reserve ratio is set. */
  event SetReserveRatio(uint256 reserveRatio);

  /** @dev Emitted when rewards seller contract is set. */
  event SetRewardsSeller(address rewardsSeller);

  /** @dev Emitted when a deposit is made. */
  event Deposit(uint256 shares, uint256 underlying);

  /** @dev Emitted when a deposit is made. */
  event Withdrawal(uint256 shares, uint256 underlying);

/* ========== Structs ========== */

  struct DistributionParameters {
    IErc20Adapter[] adapters;
    uint256[] weights;
    uint256[] balances;
    int256[] liquidityDeltas;
    uint256 netAPR;
  }

/* ========== Initializer ========== */

  function initialize(
    address _underlying,
    address _rewardsSeller,
    address _feeRecipient,
    address _owner
  ) external;

/* ========== Config Queries ========== */

  function minimumAPRImprovement() external view returns (uint256);

  function registry() external view returns (IAdapterRegistry);

  function eoaSafeCaller() external view returns (address);

  function underlying() external view returns (address);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function feeRecipient() external view returns (address);

  function rewardsSeller() external view returns (IRewardsSeller);

  function lockedTokens(address) external view returns (bool);

  function maximumUnderlying() external view returns (uint256);

  function performanceFee() external view returns (uint64);

  function reserveRatio() external view returns (uint64);

  function priceAtLastFee() external view returns (uint128);

  function minimumCompositionChangeDelay() external view returns (uint256);

  function canChangeCompositionAfter() external view returns (uint96);

/* ========== Admin Actions ========== */

  function setMaximumUnderlying(uint256 _maximumUnderlying) external;

  function setPerformanceFee(uint64 _performanceFee) external;

  function setFeeRecipient(address _feeRecipient) external;

  function setRewardsSeller(IRewardsSeller _rewardsSeller) external;

  function setReserveRatio(uint64 _reserveRatio) external;

/* ========== Balance Queries ========== */

  function balance() external view returns (uint256 sum);

  function reserveBalance() external view returns (uint256);

/* ========== Fee Queries ========== */

  function getPendingFees() external view returns (uint256);

/* ========== Price Queries ========== */

  function getPricePerFullShare() external view returns (uint256);

  function getPricePerFullShareWithFee() external view returns (uint256);

/* ========== Reward Token Sales ========== */

  function sellRewards(address rewardsToken, bytes calldata params) external;

/* ========== Adapter Queries ========== */

  function getBalances() external view returns (uint256[] memory balances);

  function getAdaptersAndWeights() external view returns (
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  );

/* ========== Status Queries ========== */

  function getCurrentLiquidityDeltas() external view returns (int256[] memory liquidityDeltas);

  function getAPR() external view returns (uint256);

  function currentDistribution() external view returns (
    DistributionParameters memory params,
    uint256 totalProductiveBalance,
    uint256 _reserveBalance
  );

/* ========== Deposit/Withdraw ========== */

  function deposit(uint256 amount) external returns (uint256 shares);

  function depositTo(uint256 amount, address to) external returns (uint256 shares);

  function withdraw(uint256 shares) external returns (uint256 owed);

  function withdrawUnderlying(uint256 amount) external returns (uint256 shares);

/* ========== Rebalance Actions ========== */

  function rebalance() external;

  function rebalanceWithNewWeights(uint256[] calldata proposedWeights) external;

  function rebalanceWithNewAdapters(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external;
}