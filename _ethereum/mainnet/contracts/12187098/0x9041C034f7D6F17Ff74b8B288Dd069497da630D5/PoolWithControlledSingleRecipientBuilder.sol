// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeCastUpgradeable.sol";
import "./IYieldSource.sol";

import "./RegistryInterface.sol";
import "./CompoundPrizePoolProxyFactory.sol";
import "./YieldSourcePrizePoolProxyFactory.sol";
import "./StakePrizePoolProxyFactory.sol";
import "./ControlledSingleRecipientBuilder.sol";

contract PoolWithControlledSingleRecipientBuilder {
  using SafeCastUpgradeable for uint256;

  event CompoundPrizePoolWithControlledSingleRecipientCreated(
    CompoundPrizePool indexed prizePool,
    ControlledSingleRecipient indexed prizeStrategy
  );

  event YieldSourcePrizePoolWithControlledSingleRecipientCreated(
    YieldSourcePrizePool indexed prizePool,
    ControlledSingleRecipient indexed prizeStrategy
  );

  event StakePrizePoolWithControlledSingleRecipientCreated(
    StakePrizePool indexed prizePool,
    ControlledSingleRecipient indexed prizeStrategy
  );

  /// @notice The configuration used to initialize the Compound Prize Pool
  struct CompoundPrizePoolConfig {
    CTokenInterface cToken;
    uint256 maxExitFeeMantissa;
    uint256 maxTimelockDuration;
  }

  /// @notice The configuration used to initialize the Compound Prize Pool
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
  CompoundPrizePoolProxyFactory public compoundPrizePoolProxyFactory;
  YieldSourcePrizePoolProxyFactory public yieldSourcePrizePoolProxyFactory;
  StakePrizePoolProxyFactory public stakePrizePoolProxyFactory;
  ControlledSingleRecipientBuilder public controlledSingleRecipientBuilder;

  constructor (
    RegistryInterface _reserveRegistry,
    CompoundPrizePoolProxyFactory _compoundPrizePoolProxyFactory,
    YieldSourcePrizePoolProxyFactory _yieldSourcePrizePoolProxyFactory,
    StakePrizePoolProxyFactory _stakePrizePoolProxyFactory,
    ControlledSingleRecipientBuilder _controlledSingleRecipientBuilder
  ) public {
    require(address(_reserveRegistry) != address(0), "GlobalBuilder/reserveRegistry-not-zero");
    require(address(_compoundPrizePoolProxyFactory) != address(0), "GlobalBuilder/compoundPrizePoolProxyFactory-not-zero");
    require(address(_yieldSourcePrizePoolProxyFactory) != address(0), "GlobalBuilder/yieldSourcePrizePoolProxyFactory-not-zero");
    require(address(_stakePrizePoolProxyFactory) != address(0), "GlobalBuilder/stakePrizePoolProxyFactory-not-zero");
    require(address(_controlledSingleRecipientBuilder) != address(0), "GlobalBuilder/controlledSingleRecipientBuilder-not-zero");
    reserveRegistry = _reserveRegistry;
    compoundPrizePoolProxyFactory = _compoundPrizePoolProxyFactory;
    yieldSourcePrizePoolProxyFactory = _yieldSourcePrizePoolProxyFactory;
    stakePrizePoolProxyFactory = _stakePrizePoolProxyFactory;
    controlledSingleRecipientBuilder = _controlledSingleRecipientBuilder;
  }

  function createCompoundControlledSingleRecipient(
    CompoundPrizePoolConfig memory prizePoolConfig,
    ControlledSingleRecipientBuilder.ControlledSingleRecipientConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (CompoundPrizePool) {
    CompoundPrizePool prizePool = compoundPrizePoolProxyFactory.create();
    ControlledSingleRecipient prizeStrategy = controlledSingleRecipientBuilder.createControlledSingleRecipient(
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
      CTokenInterface(prizePoolConfig.cToken)
    );
    prizePool.setPrizeStrategy(prizeStrategy);
    prizePool.setCreditPlanOf(
      address(prizeStrategy.ticket()),
      prizeStrategyConfig.ticketCreditRateMantissa.toUint128(),
      prizeStrategyConfig.ticketCreditLimitMantissa.toUint128()
    );
    prizePool.transferOwnership(msg.sender);
    emit CompoundPrizePoolWithControlledSingleRecipientCreated(prizePool, prizeStrategy);
    return prizePool;
  }

  function createYieldSourceControlledSingleRecipient(
    YieldSourcePrizePoolConfig memory prizePoolConfig,
    ControlledSingleRecipientBuilder.ControlledSingleRecipientConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (YieldSourcePrizePool) {
    YieldSourcePrizePool prizePool = yieldSourcePrizePoolProxyFactory.create();
    ControlledSingleRecipient prizeStrategy = controlledSingleRecipientBuilder.createControlledSingleRecipient(
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
    emit YieldSourcePrizePoolWithControlledSingleRecipientCreated(prizePool, prizeStrategy);
    return prizePool;
  }

  function createStakeControlledSingleRecipient(
    StakePrizePoolConfig memory prizePoolConfig,
    ControlledSingleRecipientBuilder.ControlledSingleRecipientConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (StakePrizePool) {
    StakePrizePool prizePool = stakePrizePoolProxyFactory.create();
    ControlledSingleRecipient prizeStrategy = controlledSingleRecipientBuilder.createControlledSingleRecipient(
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
    emit StakePrizePoolWithControlledSingleRecipientCreated(prizePool, prizeStrategy);
    return prizePool;
  }

  function _tokens(ControlledSingleRecipient _controlledSingleRecipient) internal view returns (ControlledTokenInterface[] memory) {
    ControlledTokenInterface[] memory tokens = new ControlledTokenInterface[](2);
    tokens[0] = ControlledTokenInterface(address(_controlledSingleRecipient.ticket()));
    tokens[1] = ControlledTokenInterface(address(_controlledSingleRecipient.sponsorship()));
    return tokens;
  }

}
