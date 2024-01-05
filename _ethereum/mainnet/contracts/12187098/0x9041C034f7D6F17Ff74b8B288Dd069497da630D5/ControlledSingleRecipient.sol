// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./ControlledStrategy.sol";

contract ControlledSingleRecipient is ControlledStrategy {

  address internal __recipient;

  event RecipientSet(address indexed recipient);

  function initializeControlledSingleRecipient (
    uint256 _prizePeriodStart,
    uint256 _prizePeriodSeconds,
    PrizePool _prizePool,
    TicketInterface _ticket,
    IERC20Upgradeable _sponsorship,
    address _recipient
  ) public initializer {
    IERC20Upgradeable[] memory _externalErc20Awards;

    ControlledStrategy.initialize(
      _prizePeriodStart,
      _prizePeriodSeconds,
      _prizePool,
      _ticket,
      _sponsorship,
      _externalErc20Awards
    );

    _setRecipient(_recipient);
  }

  function setRecipient(address _recipient) external onlyOwner {
      _setRecipient(_recipient);
  }

  function _setRecipient(address _recipient) internal {
      __recipient = _recipient;
      emit RecipientSet(_recipient);
  }

  function recipient() external view returns (address) {
      return __recipient;
  }

  function _distribute() internal override {
    uint256 prize = prizePool.captureAwardBalance();

    _awardExternalErc721s(__recipient);
    _awardTickets(__recipient, prize);
    _awardExternalErc20s(__recipient);
  }
}
