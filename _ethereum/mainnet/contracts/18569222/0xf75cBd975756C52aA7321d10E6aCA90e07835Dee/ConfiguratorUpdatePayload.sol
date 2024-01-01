// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./AaveV2.sol";

contract ConfiguratorUpdatePayload {
  address public immutable NEW_POOL_CONFIGURATOR_IMPL;
  address public immutable POOL_ADDRESSES_PROVIDER;

  constructor(address poolAddressesProvider, address poolConfiguratorImpl) public {
    POOL_ADDRESSES_PROVIDER = poolAddressesProvider;
    NEW_POOL_CONFIGURATOR_IMPL = poolConfiguratorImpl;
  }

  function execute() public {
    ILendingPoolAddressesProvider(POOL_ADDRESSES_PROVIDER).setLendingPoolConfiguratorImpl(
      NEW_POOL_CONFIGURATOR_IMPL
    );
  }
}
