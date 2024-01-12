// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGaugeFactory {
  function createGauge(
    address _registry,
    address _pool,
    address _bribe
  ) external returns (address);

  event GaugeCreated(address _gauge, address _pool, address _bribe);
}
