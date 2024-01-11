// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "./IERC20Upgradeable.sol";
import "./Math.sol";
import "./IStaking.sol";
import "./IVault.sol";
import "./IHealthCheck.sol";
import "./IStrategy.sol";
import "./IFeeCollection.sol";
import "./IVaultStrategyDataStore.sol";

///@dev This library will include some of the stateless functions used by the SingleAssetVault
/// The main reason to put these function in the library is to reduce the size of the main contract
library VaultUtils {
  uint256 internal constant SECONDS_PER_YEAR = 31_556_952; // 365.2425 days
  uint256 internal constant MAX_BASIS_POINTS = 10_000;

  function calculateBoostedVaultBalance(
    address _user,
    address _stakingContract,
    address _vaultContract,
    uint128 _vaultBalanceWeight,
    uint128 _stakingBalanceWeight
  ) external view returns (uint256) {
    uint256 stakingPoolSize = IStaking(_stakingContract).workingBalanceOf(_user);
    uint256 totalStakingSize = IStaking(_stakingContract).totalWorkingSupply();
    uint256 userVaultBalance = IVault(_vaultContract).balanceOf(_user);
    uint256 totalVaultSize = IVault(_vaultContract).totalSupply();
    uint128 totalWeight = _vaultBalanceWeight + _stakingBalanceWeight;
    // boostedBalance = min(1 * userVaultBalance + 9 * stakingPoolSize/totalStakingSize*totalVaultSize, 10 * userVaultBalance);
    return
      Math.min(
        _vaultBalanceWeight *
          userVaultBalance +
          (totalStakingSize == 0 ? 0 : ((_stakingBalanceWeight * stakingPoolSize * totalVaultSize) / totalStakingSize)),
        totalWeight * userVaultBalance
      );
  }

  function checkStrategyHealth(
    address _healthCheck,
    address _strategy,
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment,
    uint256 _debtOutstanding,
    uint256 _totalDebt
  ) external {
    if (_healthCheck != address(0)) {
      IHealthCheck check = IHealthCheck(_healthCheck);
      if (check.doHealthCheck(_strategy)) {
        require(check.check(_strategy, _gain, _loss, _debtPayment, _debtOutstanding, _totalDebt), "!healthy");
      } else {
        check.enableCheck(_strategy);
      }
    }
  }

  function assessManagementFee(
    uint256 _lastReport,
    uint256 _totalDebt,
    uint256 _delegateAssets,
    uint256 _managementFee
  ) public view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    uint256 duration = block.timestamp - _lastReport;
    require(duration > 0, "!block"); // should not be called twice within the same block
    // the managementFee is per year, so only charge the management fee for the period since last time it is charged.
    if (_managementFee > 0) {
      uint256 strategyTVL = _totalDebt - _delegateAssets;
      return (strategyTVL * _managementFee * duration) / SECONDS_PER_YEAR / MAX_BASIS_POINTS;
    }
    return 0;
  }

  function assessStrategyPerformanceFee(uint256 _performanceFee, uint256 _gain) public pure returns (uint256) {
    return (_gain * _performanceFee) / MAX_BASIS_POINTS;
  }

  function calculateFees(
    mapping(address => StrategyInfo) storage _strategies,
    address _strategy,
    uint256 _gain,
    uint256 _managementFee,
    uint256 _performanceFee
  ) public view returns (uint256 totalFee, uint256 performanceFee) {
    // Issue new shares to cover fees
    // solhint-disable-next-line not-rely-on-time
    if (_strategies[_strategy].activation == block.timestamp) {
      return (0, 0); // NOTE: Just added, no fees to assess
    }
    if (_gain == 0) {
      // The fees are not charged if there hasn't been any gains reported
      return (0, 0);
    }
    uint256 managementFee_ = assessManagementFee(
      _strategies[_strategy].lastReport,
      _strategies[_strategy].totalDebt,
      IStrategy(_strategy).delegatedAssets(),
      _managementFee
    );
    uint256 strategyPerformanceFee_ = assessStrategyPerformanceFee(_performanceFee, _gain);
    uint256 totalFee_ = Math.min(_gain, managementFee_ + strategyPerformanceFee_);
    return (totalFee_, strategyPerformanceFee_);
  }

  function assessFees(
    IERC20Upgradeable _token,
    address _feeCollection,
    mapping(address => StrategyInfo) storage _strategies,
    address _strategy,
    uint256 _gain,
    uint256 _managementFee,
    uint256 _performanceFee
  ) external returns (uint256) {
    uint256 totalFee_;
    uint256 performanceFee_;
    (totalFee_, performanceFee_) = calculateFees(_strategies, _strategy, _gain, _managementFee, _performanceFee);

    if (totalFee_ > 0) {
      _token.approve(_feeCollection, totalFee_);
      uint256 managementFee_ = totalFee_ - performanceFee_;
      if (managementFee_ > 0) {
        IFeeCollection(_feeCollection).collectManageFee(managementFee_);
      }
      if (performanceFee_ > 0) {
        IFeeCollection(_feeCollection).collectPerformanceFee(_strategy, performanceFee_);
      }
    }
    return totalFee_;
  }

  function reportLoss(
    mapping(address => StrategyInfo) storage _strategies,
    address _strategy,
    uint256 _totalDebt,
    IVaultStrategyDataStore _strategyDataStore,
    uint256 _loss
  ) public returns (uint256) {
    if (_loss > 0) {
      require(_strategies[_strategy].totalDebt >= _loss, "!loss");
      uint256 tRatio_ = _strategyDataStore.vaultTotalDebtRatio(address(this));
      uint256 straRatio_ = _strategyDataStore.strategyDebtRatio(address(this), _strategy);
      // make sure we reduce our trust with the strategy by the amount of loss
      if (tRatio_ != 0) {
        uint256 c = Math.min((_loss * tRatio_) / _totalDebt, straRatio_);
        _strategyDataStore.updateStrategyDebtRatio(address(this), _strategy, straRatio_ - c);
      }
      _strategies[_strategy].totalLoss = _strategies[_strategy].totalLoss + _loss;
      _strategies[_strategy].totalDebt = _strategies[_strategy].totalDebt - _loss;
      _totalDebt = _totalDebt - _loss;
    }
    return _totalDebt;
  }

  function creditAvailable(
    IERC20Upgradeable _token,
    uint256 _totalAsset,
    uint256 _totalDebt,
    IVaultStrategyDataStore _strategyDataStore,
    mapping(address => StrategyInfo) storage _strategies,
    address _strategy
  ) external view returns (uint256) {
    uint256 vaultTotalDebtLimit_ = (_totalAsset * _strategyDataStore.vaultTotalDebtRatio(address(this))) /
      MAX_BASIS_POINTS;

    uint256 strategyDebtLimit_ = (_totalAsset * _strategyDataStore.strategyDebtRatio(address(this), _strategy)) /
      MAX_BASIS_POINTS;
    uint256 strategyTotalDebt_ = _strategies[_strategy].totalDebt;
    uint256 strategyMinDebtPerHarvest_ = _strategyDataStore.strategyMinDebtPerHarvest(address(this), _strategy);
    uint256 strategyMaxDebtPerHarvest_ = _strategyDataStore.strategyMaxDebtPerHarvest(address(this), _strategy);

    if ((strategyDebtLimit_ <= strategyTotalDebt_) || (vaultTotalDebtLimit_ <= _totalDebt)) {
      return 0;
    }

    uint256 available_ = strategyDebtLimit_ - strategyTotalDebt_;
    available_ = Math.min(available_, vaultTotalDebtLimit_ - _totalDebt);
    available_ = Math.min(available_, _token.balanceOf(address(this)));

    return available_ < strategyMinDebtPerHarvest_ ? 0 : Math.min(available_, strategyMaxDebtPerHarvest_);
  }

  function debtOutstanding(
    bool _emergencyShutdown,
    uint256 _totalAsset,
    IVaultStrategyDataStore _strategyDataStore,
    mapping(address => StrategyInfo) storage _strategies,
    address _strategy
  ) external view returns (uint256) {
    if (_strategyDataStore.vaultTotalDebtRatio(address(this)) == 0) {
      return _strategies[_strategy].totalDebt;
    }
    uint256 strategyLimit_ = (_totalAsset * _strategyDataStore.strategyDebtRatio(address(this), _strategy)) /
      MAX_BASIS_POINTS;
    uint256 strategyTotalDebt_ = _strategies[_strategy].totalDebt;

    if (_emergencyShutdown) {
      return strategyTotalDebt_;
    } else if (strategyTotalDebt_ <= strategyLimit_) {
      return 0;
    } else {
      return strategyTotalDebt_ - strategyLimit_;
    }
  }

  function expectedReturn(mapping(address => StrategyInfo) storage _strategies, address _strategy)
    external
    view
    returns (uint256)
  {
    uint256 strategyLastReport_ = _strategies[_strategy].lastReport;
    // solhint-disable-next-line not-rely-on-time
    uint256 sinceLastHarvest_ = block.timestamp - strategyLastReport_;
    uint256 totalHarvestTime_ = strategyLastReport_ - _strategies[_strategy].activation;

    // NOTE: If either `sinceLastHarvest_` or `totalHarvestTime_` is 0, we can short-circuit to `0`
    if ((sinceLastHarvest_ > 0) && (totalHarvestTime_ > 0) && (IStrategy(_strategy).isActive())) {
      // # NOTE: Unlikely to throw unless strategy accumalates >1e68 returns
      // # NOTE: Calculate average over period of time where harvests have occured in the past
      return (_strategies[_strategy].totalGain * sinceLastHarvest_) / totalHarvestTime_;
    } else {
      return 0;
    }
  }
}
