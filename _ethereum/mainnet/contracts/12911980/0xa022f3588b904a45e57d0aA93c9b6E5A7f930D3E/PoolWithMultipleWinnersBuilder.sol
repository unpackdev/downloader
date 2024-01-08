// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeCastUpgradeable.sol";

import "./IYieldSource.sol";
import "./RegistryInterface.sol";
import "./YieldSourcePrizePoolProxyFactory.sol";
import "./StakePrizePoolProxyFactory.sol";
import "./MultipleWinnersBuilder.sol";

contract PoolWithMultipleWinnersBuilder {
  using SafeCastUpgradeable for uint256;

  event YieldSourcePrizePoolWithMultipleWinnersCreated(
    YieldSourcePrizePool indexed prizePool,
    MultipleWinners indexed prizeStrategy
  );

  event StakePrizePoolWithMultipleWinnersCreated(
    StakePrizePool indexed prizePool,
    MultipleWinners indexed prizeStrategy
  );

  struct YieldSourcePrizePoolConfig {
    IYieldSource yieldSource;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  struct StakePrizePoolConfig {
    IERC20Upgradeable token;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  RegistryInterface public reserveRegistry;
  YieldSourcePrizePoolProxyFactory public yieldSourcePrizePoolProxyFactory;
  StakePrizePoolProxyFactory public stakePrizePoolProxyFactory;
  MultipleWinnersBuilder public multipleWinnersBuilder;

  constructor (
    RegistryInterface _reserveRegistry,
    YieldSourcePrizePoolProxyFactory _yieldSourcePrizePoolProxyFactory,
    StakePrizePoolProxyFactory _stakePrizePoolProxyFactory,
    MultipleWinnersBuilder _multipleWinnersBuilder
  ) public {
    require(address(_reserveRegistry) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: RESERVEREGISTRY_NOT_ZERO");
    require(address(_yieldSourcePrizePoolProxyFactory) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: YIELDSOURCEPRIZEPOOLPROXYFACTORY_NOT_ZERO");
    require(address(_stakePrizePoolProxyFactory) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: STAKEPRIZEPOOLPROXYFACTORY_NOT_ZERO");
    require(address(_multipleWinnersBuilder) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: MULTIPLEWINNERSBUILDER_NOT_ZERO");
    reserveRegistry = _reserveRegistry;
    yieldSourcePrizePoolProxyFactory = _yieldSourcePrizePoolProxyFactory;
    stakePrizePoolProxyFactory = _stakePrizePoolProxyFactory;
    multipleWinnersBuilder = _multipleWinnersBuilder;
  }

  function createYieldSourceMultipleWinners(
    YieldSourcePrizePoolConfig memory prizePoolConfig,
    MultipleWinnersBuilder.MultipleWinnersConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (YieldSourcePrizePool) {
    YieldSourcePrizePool prizePool = yieldSourcePrizePoolProxyFactory.create();
    MultipleWinners prizeStrategy = multipleWinnersBuilder.createMultipleWinners(
      prizePool,
      prizeStrategyConfig,
      decimals,
      msg.sender
    );
    prizePool.initializeYieldSourcePrizePool(
      reserveRegistry,
      _tokens(prizeStrategy),
      prizePoolConfig.maxExitFeeMantissa,
      prizePoolConfig.maxTimelockDuration,
      prizePoolConfig.yieldSource
    );
    prizePool.setPrizeStrategy(prizeStrategy);
    prizePool.setCreditPlanOf(
      address(prizeStrategy.ticket()),
      prizeStrategyConfig.ticketCreditRateMantissa.toUint128(),
      prizeStrategyConfig.ticketCreditLimitMantissa.toUint128()
    );
    prizePool.transferOwnership(msg.sender);
    emit YieldSourcePrizePoolWithMultipleWinnersCreated(prizePool, prizeStrategy);
    return prizePool;
  }

  function createStakeMultipleWinners(
    StakePrizePoolConfig memory prizePoolConfig,
    MultipleWinnersBuilder.MultipleWinnersConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (StakePrizePool) {
    StakePrizePool prizePool = stakePrizePoolProxyFactory.create();
    MultipleWinners prizeStrategy = multipleWinnersBuilder.createMultipleWinners(
      prizePool,
      prizeStrategyConfig,
      decimals,
      msg.sender
    );
    prizePool.initialize(
      reserveRegistry,
      _tokens(prizeStrategy),
      prizePoolConfig.maxExitFeeMantissa,
      prizePoolConfig.maxTimelockDuration,
      prizePoolConfig.token
    );
    prizePool.setPrizeStrategy(prizeStrategy);
    prizePool.setCreditPlanOf(
      address(prizeStrategy.ticket()),
      prizeStrategyConfig.ticketCreditRateMantissa.toUint128(),
      prizeStrategyConfig.ticketCreditLimitMantissa.toUint128()
    );
    prizePool.transferOwnership(msg.sender);
    emit StakePrizePoolWithMultipleWinnersCreated(prizePool, prizeStrategy);
    return prizePool;
  }

  function _tokens(MultipleWinners _multipleWinners) internal view returns (ControlledTokenInterface[] memory) {
    ControlledTokenInterface[] memory tokens = new ControlledTokenInterface[](2);
    tokens[0] = ControlledTokenInterface(address(_multipleWinners.ticket()));
    tokens[1] = ControlledTokenInterface(address(_multipleWinners.sponsorship()));
    return tokens;
  }
}