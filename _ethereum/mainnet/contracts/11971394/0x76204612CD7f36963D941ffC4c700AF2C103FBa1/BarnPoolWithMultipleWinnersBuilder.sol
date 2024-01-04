// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./SafeCastUpgradeable.sol";

import "./BarnPrizePoolBuilder.sol";
import "./MultipleWinnersBuilder.sol";

contract BarnPoolWithMultipleWinnersBuilder {
  using SafeCastUpgradeable for uint256;

  event BarnPrizePoolWithMultipleWinnersCreated(address indexed prizePool, address indexed prizeStrategy);

  BarnPrizePoolBuilder public barnPrizePoolBuilder;
  MultipleWinnersBuilder public multipleWinnersBuilder;

  constructor (
    BarnPrizePoolBuilder _barnPrizePoolBuilder,
    MultipleWinnersBuilder _multipleWinnersBuilder
  ) public {
    require(address(_barnPrizePoolBuilder) != address(0), "GlobalBuilder/barnPrizePoolBuilder-not-zero");
    require(address(_multipleWinnersBuilder) != address(0), "GlobalBuilder/multipleWinnersBuilder-not-zero");
    barnPrizePoolBuilder = _barnPrizePoolBuilder;
    multipleWinnersBuilder = _multipleWinnersBuilder;
  }

  function createBarnMultipleWinners(
    BarnPrizePoolBuilder.BarnPrizePoolConfig memory prizePoolConfig,
    MultipleWinnersBuilder.MultipleWinnersConfig memory prizeStrategyConfig,
    uint8 decimals
  ) external returns (BarnPrizePool) {
    BarnPrizePool prizePool = barnPrizePoolBuilder.createBarnPrizePool(prizePoolConfig);
    MultipleWinners prizeStrategy = _createMultipleWinnersAndTransferPrizePool(prizePool, prizeStrategyConfig, decimals);
    emit BarnPrizePoolWithMultipleWinnersCreated(address(prizePool), address(prizeStrategy));
    return prizePool;
  }

  function _createMultipleWinnersAndTransferPrizePool(
    PrizePool prizePool,
    MultipleWinnersBuilder.MultipleWinnersConfig memory prizeStrategyConfig,
    uint8 decimals
  ) internal returns (MultipleWinners) {

    MultipleWinners periodicPrizeStrategy = multipleWinnersBuilder.createMultipleWinners(
      prizePool,
      prizeStrategyConfig,
      decimals,
      msg.sender
    );

    address ticket = address(periodicPrizeStrategy.ticket());

    prizePool.setPrizeStrategy(periodicPrizeStrategy);

    prizePool.addControlledToken(Ticket(ticket));
    prizePool.addControlledToken(ControlledTokenInterface(address(periodicPrizeStrategy.sponsorship())));

    prizePool.setCreditPlanOf(
      ticket,
      prizeStrategyConfig.ticketCreditRateMantissa.toUint128(),
      prizeStrategyConfig.ticketCreditLimitMantissa.toUint128()
    );

    prizePool.transferOwnership(msg.sender);

    return periodicPrizeStrategy;
  }
}
