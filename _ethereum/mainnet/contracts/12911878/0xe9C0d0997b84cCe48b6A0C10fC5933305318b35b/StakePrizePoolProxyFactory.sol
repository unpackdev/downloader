// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./StakePrizePool.sol";
import "./ProxyFactory.sol";

contract StakePrizePoolProxyFactory is ProxyFactory {

  StakePrizePool public instance;

  constructor () public {
    instance = new StakePrizePool();
  }

  function create() external returns (StakePrizePool) {
    return StakePrizePool(deployMinimal(address(instance), ""));
  }
}
