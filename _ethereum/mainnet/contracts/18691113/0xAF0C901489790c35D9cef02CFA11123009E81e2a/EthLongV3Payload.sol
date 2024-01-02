// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./ITransparentUpgradeableProxy.sol";
import "./IProxyAdmin.sol";
import "./AaveV3Ethereum.sol";
import "./MiscEthereum.sol";
import "./GovernanceV3Ethereum.sol";
import "./IExecutor.sol";
import "./IExecutor.sol";
import "./IMediator.sol";

/**
 * @title EthLongV3Payload
 * @notice Migrate permissions for stkAave and Aave tokens from Long executor to the mediator contract,
 * @notice upgrade governance v3 implementation.
 * @author BGD Labs
 **/
contract EthLongV3Payload {
  address public immutable MEDIATOR;

  constructor(address mediator) {
    MEDIATOR = mediator;
  }

  function execute() external {
    // move aave token proxy admin owner from Long Executor to ProxyAdminLong
    ITransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)).changeAdmin(
      MiscEthereum.PROXY_ADMIN_LONG
    );

    // proxy admin
    IOwnable(MiscEthereum.PROXY_ADMIN_LONG).transferOwnership(address(MEDIATOR));

    // set the new executor as the pending admin
    IExecutorV2(address(this)).setPendingAdmin(address(GovernanceV3Ethereum.EXECUTOR_LVL_2));

    // new executor - change owner to the mediator contract
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(address(MEDIATOR));

    // set the overdue date for the migration
    IMediator(MEDIATOR).setOverdueDate();
  }
}
