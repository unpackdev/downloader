// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;
pragma experimental ABIEncoderV2;

import "./ControlledTokenBuilder.sol";
import "./ControlledSingleRecipientProxyFactory.sol";

/* solium-disable security/no-block-members */
contract ControlledSingleRecipientBuilder {

  event ControlledSingleRecipientCreated(address indexed prizeStrategy);

  struct ControlledSingleRecipientConfig {
    uint256 prizePeriodStart;
    uint256 prizePeriodSeconds;
    string ticketName;
    string ticketSymbol;
    string sponsorshipName;
    string sponsorshipSymbol;
    uint256 ticketCreditLimitMantissa;
    uint256 ticketCreditRateMantissa;
    address recipient;
  }

  ControlledSingleRecipientProxyFactory public controlledSingleRecipientProxyFactory;
  ControlledTokenBuilder public controlledTokenBuilder;

  constructor (
    ControlledSingleRecipientProxyFactory _controlledSingleRecipientProxyFactory,
    ControlledTokenBuilder _controlledTokenBuilder
  ) public {
    require(address(_controlledSingleRecipientProxyFactory) != address(0), "ControlledSingleRecipientBuilder/controlledSingleRecipientProxyFactory-not-zero");
    require(address(_controlledTokenBuilder) != address(0), "ControlledSingleRecipientBuilder/token-builder-not-zero");
    controlledSingleRecipientProxyFactory = _controlledSingleRecipientProxyFactory;
    controlledTokenBuilder = _controlledTokenBuilder;
  }

  function createControlledSingleRecipient(
    PrizePool prizePool,
    ControlledSingleRecipientConfig memory prizeStrategyConfig,
    uint8 decimals,
    address owner
  ) external returns (ControlledSingleRecipient) {
    ControlledSingleRecipient csr = controlledSingleRecipientProxyFactory.create();

    Ticket ticket = _createTicket(
      prizeStrategyConfig.ticketName,
      prizeStrategyConfig.ticketSymbol,
      decimals,
      prizePool
    );

    ControlledToken sponsorship = _createSponsorship(
      prizeStrategyConfig.sponsorshipName,
      prizeStrategyConfig.sponsorshipSymbol,
      decimals,
      prizePool
    );

    csr.initializeControlledSingleRecipient(
      prizeStrategyConfig.prizePeriodStart,
      prizeStrategyConfig.prizePeriodSeconds,
      prizePool,
      ticket,
      sponsorship,
      prizeStrategyConfig.recipient
    );

    csr.transferOwnership(owner);

    emit ControlledSingleRecipientCreated(address(csr));

    return csr;
  }

  function createControlledSingleRecipientFromExistingPrizeStrategy(
    ControlledStrategy prizeStrategy,
    address recipient
  ) external returns (ControlledSingleRecipient) {
    ControlledSingleRecipient csr = controlledSingleRecipientProxyFactory.create();

    csr.initializeControlledSingleRecipient(
      prizeStrategy.prizePeriodStartedAt(),
      prizeStrategy.prizePeriodSeconds(),
      prizeStrategy.prizePool(),
      prizeStrategy.ticket(),
      prizeStrategy.sponsorship(),
      recipient
    );

    csr.transferOwnership(msg.sender);

    emit ControlledSingleRecipientCreated(address(csr));

    return csr;
  }

  function _createTicket(
    string memory name,
    string memory token,
    uint8 decimals,
    PrizePool prizePool
  ) internal returns (Ticket) {
    return controlledTokenBuilder.createTicket(
      ControlledTokenBuilder.ControlledTokenConfig(
        name,
        token,
        decimals,
        prizePool
      )
    );
  }

  function _createSponsorship(
    string memory name,
    string memory token,
    uint8 decimals,
    PrizePool prizePool
  ) internal returns (ControlledToken) {
    return controlledTokenBuilder.createControlledToken(
      ControlledTokenBuilder.ControlledTokenConfig(
        name,
        token,
        decimals,
        prizePool
      )
    );
  }
}
