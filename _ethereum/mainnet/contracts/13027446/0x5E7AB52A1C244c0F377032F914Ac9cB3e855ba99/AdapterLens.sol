// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IProtocolAdapter.sol";
import "./IAdapterRegistry.sol";



contract AdapterLens {
  IAdapterRegistry internal registry = IAdapterRegistry(0x5F2945604013Ee9f80aE2eDDb384462B681859C4);

  function getSupportedProtocols(address token) external view returns (string[] memory protocolNames) {
    address[] memory adapters = registry.getAdaptersList(token);
    protocolNames = new string[](adapters.length);
    for (uint256 i; i < adapters.length; i++) {
      protocolNames[i] = IProtocolAdapter(registry.getProtocolForTokenAdapter(adapters[i])).protocol();
    }
  }
}