// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./IDEXV2.sol";
import "./IERC20.sol";

abstract contract CF_Common {
  string internal constant _version = "1.0.0";

  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  mapping(address => bool) internal _blacklisted;
  mapping(address => bool) internal _whitelisted;
  mapping(address => holderAccount) internal _holder;
  mapping(uint8 => taxBeneficiary) internal _taxBeneficiary;

  address[] internal _holders;

  bool internal _swapEnabled;
  bool internal _swapping;
  bool internal _suspendTaxes;
  bool internal _distributing;
  bool internal immutable _initialized;

  uint8 internal immutable _decimals;
  uint8 internal _cooldownTriggerCount;
  uint24 internal constant _denominator = 1000;
  uint24 internal _maxBalancePercent;
  uint24 internal _totalTxTax;
  uint24 internal _totalBuyTax;
  uint24 internal _totalSellTax;
  uint24 internal _totalPenaltyTxTax;
  uint24 internal _totalPenaltyBuyTax;
  uint24 internal _totalPenaltySellTax;
  uint24 internal _minTaxDistributionPercent;
  uint24 internal _minSwapPercent;
  uint32 internal _lastTaxDistribution;
  uint32 internal _tradingEnabled;
  uint32 internal _lastSwap;
  uint32 internal _earlyPenaltyTime;
  uint32 internal _cooldownTriggerTime;
  uint32 internal _cooldownPeriod;
  uint256 internal _totalSupply;
  uint256 internal _totalBurned;
  uint256 internal _maxBalanceAmount;
  uint256 internal _totalTaxCollected;
  uint256 internal _minTaxDistributionAmount;
  uint256 internal _amountForTaxDistribution;
  uint256 internal _amountSwappedForTaxDistribution;
  uint256 internal _minSwapAmount;
  uint256 internal _amountForLiquidity;
  uint256 internal _ethForTaxDistribution;
  uint256 internal _reflectionTokensForTaxDistribution;

  struct Renounced {
    bool Blacklist;
    bool Whitelist;
    bool Cooldown;
    bool MaxBalance;
    bool Taxable;
    bool DEXRouterV2;
  }

  struct holderAccount {
    bool exists;
    bool penalty;
    uint32 count;
    uint32 start;
    uint32 cooldown;
  }

  struct taxBeneficiary {
    bool exists;
    address account;
    uint24[3] percent; // 0: tx, 1: buy, 2: sell
    uint24[3] penalty;
    uint256 unclaimed;
  }

  struct DEXRouterV2 {
    address router;
    address pair;
    address WETH;
    address receiver;
  }

  Renounced internal _renounced;
  DEXRouterV2 internal _dex;
  IERC20 internal _reflectionToken;

  function _percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    unchecked {
      return (amount * bps) / (100 * uint256(_denominator));
    }
  }

  function _timestamp() internal view returns (uint32) {
    unchecked {
      return uint32(block.timestamp % 2**32);
    }
  }

  function version() external pure returns (string memory) {
    return _version;
  }

  function denominator() external view returns (uint24) {
    return _denominator;
  }
}
