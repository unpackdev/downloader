// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

interface MProxyInterface {
  
    function proxyClaimReward(address asset, address recipient, uint amount) external;
    function proxySplitReserves(address asset, uint amount) external;
}
