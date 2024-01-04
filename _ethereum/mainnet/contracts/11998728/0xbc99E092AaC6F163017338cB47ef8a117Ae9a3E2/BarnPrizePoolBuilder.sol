// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20Upgradeable.sol";
import "./RegistryInterface.sol";
import "./PrizePoolBuilder.sol";
import "./BarnPrizePoolProxyFactory.sol";
import "./BarnInterface.sol";
import "./BarnRewardsInterface.sol";
import "./OpenZeppelinProxyFactoryInterface.sol";

/* solium-disable security/no-block-members */
contract BarnPrizePoolBuilder is PrizePoolBuilder {
  using SafeMathUpgradeable for uint256;
  using SafeCastUpgradeable for uint256;

  struct BarnPrizePoolConfig {
    BarnInterface barn;
    BarnRewardsInterface rewards;
    IERC20Upgradeable bond;
    address reserveFeeCollectorBarn;
    address reserveFeeCollectorPoolTogether;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  RegistryInterface public reserveRegistry;
  BarnPrizePoolProxyFactory public barnPrizePoolProxyFactory;

  constructor (
    RegistryInterface _reserveRegistry,
    BarnPrizePoolProxyFactory _barnPrizePoolProxyFactory
  ) public {
    require(address(_reserveRegistry) != address(0), "BarnPrizePoolBuilder/reserveRegistry-not-zero");
    require(address(_barnPrizePoolProxyFactory) != address(0), "BarnPrizePoolBuilder/barn-prize-pool-builder-not-zero");
    reserveRegistry = _reserveRegistry;
    barnPrizePoolProxyFactory = _barnPrizePoolProxyFactory;
  }

  function createBarnPrizePool(
    BarnPrizePoolConfig calldata config
  )
    external
    returns (BarnPrizePool)
  {
    BarnPrizePool prizePool = barnPrizePoolProxyFactory.create();

    ControlledTokenInterface[] memory tokens;

    prizePool.initialize(
      reserveRegistry,
      tokens,
      config.maxExitFeeMantissa,
      config.maxTimelockDuration,
      config.barn,
      config.rewards,
      config.bond,
      config.reserveFeeCollectorBarn,
      config.reserveFeeCollectorPoolTogether
    );

    prizePool.transferOwnership(msg.sender);

    emit PrizePoolCreated(msg.sender, address(prizePool));

    return prizePool;
  }
}
