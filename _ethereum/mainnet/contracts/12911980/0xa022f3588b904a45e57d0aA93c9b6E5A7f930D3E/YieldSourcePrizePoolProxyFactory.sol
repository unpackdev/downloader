// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "./YieldSourcePrizePool.sol";
import "./ProxyFactory.sol";

contract YieldSourcePrizePoolProxyFactory is ProxyFactory {
  YieldSourcePrizePool public instance;

  constructor () public {
    instance = new YieldSourcePrizePool();
  }

  function create() external returns (YieldSourcePrizePool) {
    return YieldSourcePrizePool(deployMinimal(address(instance), ""));
  }
}
