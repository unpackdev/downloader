// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IRewardDistributionJob {
  event GaugeProxyAddressSet(address _gaugeProxy);

  function gaugeProxy() external returns (address _gaugeProxy);

  function work() external;

  function setGaugeProxy(address _gaugeProxy) external;
}
