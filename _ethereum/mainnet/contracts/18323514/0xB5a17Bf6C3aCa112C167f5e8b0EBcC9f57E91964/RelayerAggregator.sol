// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./ENSRegistry.sol";
import "./ENSResolver.sol";
import "./IRelayerRegistry.sol";

struct Relayer {
  uint256 balance;
  bool isRegistered;
}

contract RelayerAggregator {
  IRelayerRegistry public relayerRegistry;

  constructor(address _relayerRegistry) {
    relayerRegistry = IRelayerRegistry(_relayerRegistry);
  }

  function relayersData(address[] memory _relayers) public view returns (Relayer[] memory) {
    uint256 _length = _relayers.length;

    Relayer[] memory relayers = new Relayer[](_length);
    for (uint256 i = 0; i < _length; i++) {
      relayers[i].isRegistered = relayerRegistry.isRelayerRegistered(_relayers[i]);
      relayers[i].balance = 0;
    }

    return relayers;
  }
}
