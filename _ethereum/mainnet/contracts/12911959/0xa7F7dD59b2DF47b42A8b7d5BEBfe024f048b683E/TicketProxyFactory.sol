// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./Initializable.sol";

import "./Ticket.sol";
import "./ProxyFactory.sol";

contract TicketProxyFactory is ProxyFactory {

  Ticket public instance;

  constructor () public {
    instance = new Ticket();
  }

  function create() external returns (Ticket) {
    return Ticket(deployMinimal(address(instance), ""));
  }
}
