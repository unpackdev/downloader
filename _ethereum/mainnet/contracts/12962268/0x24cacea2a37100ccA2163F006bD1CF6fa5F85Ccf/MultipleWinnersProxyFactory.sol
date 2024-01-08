// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./MultipleWinners.sol";
import "./ProxyFactory.sol";

contract MultipleWinnersProxyFactory is ProxyFactory {

  MultipleWinners public instance;

  constructor () public {
    instance = new MultipleWinners();
  }

  function create() external returns (MultipleWinners) {
    return MultipleWinners(deployMinimal(address(instance), ""));
  }

}