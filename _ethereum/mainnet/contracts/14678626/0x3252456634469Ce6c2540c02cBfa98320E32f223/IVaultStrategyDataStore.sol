// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IVaultStrategyDataStore {
  function strategyPerformanceFee(address _vault, address _strategy) external view returns (uint256);

  function strategyActivation(address _vault, address _strategy) external view returns (uint256);

  function strategyDebtRatio(address _vault, address _strategy) external view returns (uint256);

  function strategyMinDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function strategyMaxDebtPerHarvest(address _vault, address _strategy) external view returns (uint256);

  function vaultStrategies(address _vault) external view returns (address[] memory);

  function vaultTotalDebtRatio(address _vault) external view returns (uint256);

  function withdrawQueue(address _vault) external view returns (address[] memory);

  function revokeStrategyByStrategy(address _strategy) external;

  function setVaultManager(address _vault, address _manager) external;

  function setMaxTotalDebtRatio(address _vault, uint256 _maxTotalDebtRatio) external;

  function addStrategy(
    address _vault,
    address _strategy,
    uint256 _debtRatio,
    uint256 _minDebtPerHarvest,
    uint256 _maxDebtPerHarvest,
    uint256 _performanceFee
  ) external;

  function updateStrategyPerformanceFee(
    address _vault,
    address _strategy,
    uint256 _performanceFee
  ) external;

  function updateStrategyDebtRatio(
    address _vault,
    address _strategy,
    uint256 _debtRatio
  ) external;

  function updateStrategyMinDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _minDebtPerHarvest
  ) external;

  function updateStrategyMaxDebtHarvest(
    address _vault,
    address _strategy,
    uint256 _maxDebtPerHarvest
  ) external;

  function migrateStrategy(
    address _vault,
    address _oldStrategy,
    address _newStrategy
  ) external;

  function revokeStrategy(address _vault, address _strategy) external;

  function setWithdrawQueue(address _vault, address[] calldata _queue) external;

  function addStrategyToWithdrawQueue(address _vault, address _strategy) external;

  function removeStrategyFromWithdrawQueue(address _vault, address _strategy) external;
}
