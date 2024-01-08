// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./SafeCastUpgradeable.sol";

import "./IYieldSource.sol";
import "./RegistryInterface.sol";
import "./YieldSourcePrizePoolProxyFactory.sol";
import "./MultipleWinnersBuilder.sol";

contract PoolWithMultipleWinnersBuilder {
  using SafeCastUpgradeable for uint256;

  event YieldSourcePrizePoolWithMultipleWinnersCreated(
    YieldSourcePrizePool indexed prizePool,
    MultipleWinners indexed prizeStrategy
  );

  struct YieldSourcePrizePoolConfig {
    IYieldSource yieldSource;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  RegistryInterface public reserveRegistry;
  YieldSourcePrizePoolProxyFactory public yieldSourcePrizePoolProxyFactory;
  MultipleWinnersBuilder public multipleWinnersBuilder;

  constructor (
    RegistryInterface _reserveRegistry,
    YieldSourcePrizePoolProxyFactory _yieldSourcePrizePoolProxyFactory,
    MultipleWinnersBuilder _multipleWinnersBuilder
  ) public {
    require(address(_reserveRegistry) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: RESERVEREGISTRY_NOT_ZERO");
    require(address(_yieldSourcePrizePoolProxyFactory) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: YIELDSOURCEPRIZEPOOLPROXYFACTORY_NOT_ZERO");
    require(address(_multipleWinnersBuilder) != address(0), "POOLWITHMULTIPLEWINNERSBUILDER: MULTIPLEWINNERSBUILDER_NOT_ZERO");
    reserveRegistry = _reserveRegistry;
    yieldSourcePrizePoolProxyFactory = _yieldSourcePrizePoolProxyFactory;
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
      ControlledTokenInterface(address(prizeStrategy.ticket())),
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
}