// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IInitializableAdminUpgradeabilityProxy.sol";
import "./IAaveGovernanceV2.sol";
import "./IOwnable.sol";

/**
 * @title ProposalPayloadNewLongExecutor
 * @author BGD Labs
 * @dev Proposal to deploy a new LongExecutor and authorize it on the Aave Governance.
 * - Introduces a new voting delay aplied between proposal creation and voting.
 *   This delay is of 1 day in blocks (7200) taking into account 1 block per 12 sec (Ethereum merge proof)
 * - Moves all the permission held on the old long executor to the new one.
 * - Moves the permissions on ABPT and stkABPT to the ShortExecutor as they don't influence on the Aave Governance
 *   and they belong to Level 1.
 * - The old long executor is not de-authorized on the Aave Governance, in case there would be any permission left there.
 */
contract ProposalPayloadNewLongExecutor {
  IAaveGovernanceV2 constant AAVE_GOVERNANCE_V2 =
    IAaveGovernanceV2(0xEC568fffba86c094cf06b22134B23074DFE2252c);
  uint256 public constant VOTING_DELAY = 7200;
  address public constant SHORT_EXECUTOR =
    0xEE56e2B3D491590B5b31738cC34d5232F378a8D5;
  address public immutable NEW_LONG_EXECUTOR;

  IInitializableAdminUpgradeabilityProxy constant AAVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
    );
  IInitializableAdminUpgradeabilityProxy constant ABPT_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x41A08648C3766F9F9d85598fF102a08f4ef84F84
    );
  IInitializableAdminUpgradeabilityProxy constant STK_AAVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x4da27a545c0c5B758a6BA100e3a049001de870f5
    );
  IInitializableAdminUpgradeabilityProxy constant STK_ABPT_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0xa1116930326D21fB917d5A27F1E9943A9595fb47
    );

  constructor(address longExecutor) {
    NEW_LONG_EXECUTOR = longExecutor;
  }

  function execute() external {
    AAVE_GOVERNANCE_V2.setVotingDelay(VOTING_DELAY);

    address[] memory executorsToAuthorize = new address[](1);
    executorsToAuthorize[0] = NEW_LONG_EXECUTOR;
    AAVE_GOVERNANCE_V2.authorizeExecutors(executorsToAuthorize);

    IOwnable(address(AAVE_GOVERNANCE_V2)).transferOwnership(NEW_LONG_EXECUTOR);
    AAVE_PROXY.changeAdmin(NEW_LONG_EXECUTOR);
    STK_AAVE_PROXY.changeAdmin(NEW_LONG_EXECUTOR);

    ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
    STK_ABPT_PROXY.changeAdmin(SHORT_EXECUTOR);
  }
}
