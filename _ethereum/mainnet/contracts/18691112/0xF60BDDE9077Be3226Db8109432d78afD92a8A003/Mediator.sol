// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./ITransparentUpgradeableProxy.sol";
import "./IProxyAdmin.sol";
import "./AaveGovernanceV2.sol";
import "./GovernanceV3Ethereum.sol";
import "./AaveV2Ethereum.sol";
import "./AaveV3Ethereum.sol";
import "./MiscEthereum.sol";
import "./AaveSafetyModule.sol";
import "./IExecutor.sol";
import "./IMediator.sol";

/**
 * @title Mediator
 * @notice Accept the stkAave and aave token permissions from the Long executor to transfer
 * them to the new v3 executor level 2 for the synchronization of the migration from governance v2.5 to v3.
 * @author BGD Labs
 **/
contract Mediator is IMediator {
  bool private _isCancelled;
  uint256 private _overdueDate;

  uint256 public constant OVERDUE = 172800; // 2 days

  address public constant AAVE_IMPL = 0x5D4Aa78B08Bc7C530e21bf7447988b1Be7991322;
  address public constant STK_AAVE_IMPL = 0x0fE58FE1CaA69951dC924A8c222bE19013B89476;

  /**
   * @dev Throws if the caller is not the short executor.
   */
  modifier onlyShortV3Executor() {
    if (msg.sender != GovernanceV3Ethereum.EXECUTOR_LVL_1) {
      revert InvalidCaller();
    }
    _;
  }

  /**
   * @dev Throws if the caller is not the long executor.
   */
  modifier onlyLongExecutor() {
    if (msg.sender != AaveGovernanceV2.LONG_EXECUTOR) {
      revert InvalidCaller();
    }
    _;
  }

  function getIsCancelled() external view returns (bool) {
    return _isCancelled;
  }

  function setOverdueDate() external onlyLongExecutor {
    _overdueDate = block.timestamp + OVERDUE;

    emit OverdueDateUpdated(_overdueDate);
  }

  function execute() external onlyShortV3Executor {
    if (_isCancelled) {
      revert ProposalIsCancelled();
    }

    if (_overdueDate == 0) {
      revert LongProposalNotExecuted();
    }

    // UPDATE TOKENS

    // update Aave token impl
    IProxyAdmin(MiscEthereum.PROXY_ADMIN_LONG).upgradeAndCall(
      ITransparentUpgradeableProxy(payable(AaveV3EthereumAssets.AAVE_UNDERLYING)),
      address(AAVE_IMPL),
      abi.encodeWithSignature('initialize()')
    );

    // upgrade stk aave
    IProxyAdmin(MiscEthereum.PROXY_ADMIN_LONG).upgradeAndCall(
      ITransparentUpgradeableProxy(payable(AaveSafetyModule.STK_AAVE)),
      address(STK_AAVE_IMPL),
      abi.encodeWithSignature('initialize()')
    );

    // PROXY ADMIN
    IOwnable(MiscEthereum.PROXY_ADMIN_LONG).transferOwnership(
      address(GovernanceV3Ethereum.EXECUTOR_LVL_2)
    );

    // new executor - call execute payload to accept new permissions
    IExecutorV3(GovernanceV3Ethereum.EXECUTOR_LVL_2).executeTransaction(
      AaveGovernanceV2.LONG_EXECUTOR,
      0,
      'acceptAdmin()',
      bytes(''),
      false
    );

    // new executor - change owner to payload controller
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(
      address(GovernanceV3Ethereum.PAYLOADS_CONTROLLER)
    );

    emit Executed();
  }

  /**
   * @dev Will prevent the execution of the migration
   */
  function cancel() external {
    if (msg.sender != AaveV2Ethereum.EMERGENCY_ADMIN && block.timestamp < _overdueDate) {
      revert NotGuardianOrNotOverdue();
    }

    if (_isCancelled) {
      revert ProposalIsCancelled();
    }

    // proxy admin
    IOwnable(MiscEthereum.PROXY_ADMIN_LONG).transferOwnership(
      address(AaveGovernanceV2.LONG_EXECUTOR)
    );

    // new executor - change owner from the mediator contract to LongExecutor
    IOwnable(GovernanceV3Ethereum.EXECUTOR_LVL_2).transferOwnership(
      address(AaveGovernanceV2.LONG_EXECUTOR)
    );

    _isCancelled = true;
    emit Cancelled();
  }
}
