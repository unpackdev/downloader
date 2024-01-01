// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.6.12;

import "./AaveV2Ethereum.sol";

contract V2EthLiquidationSentinelPayload {
  address public immutable NEW_COLLATERAL_MANAGER;

  constructor(address collateralManager) public {
    NEW_COLLATERAL_MANAGER = collateralManager;
  }

  function execute() public {
    AaveV2Ethereum.POOL_ADDRESSES_PROVIDER.setLendingPoolCollateralManager(NEW_COLLATERAL_MANAGER);
  }
}
