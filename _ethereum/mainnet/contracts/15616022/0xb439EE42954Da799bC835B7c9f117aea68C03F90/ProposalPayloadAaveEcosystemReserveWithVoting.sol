// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./IInitializableAdminUpgradeabilityProxy.sol";
import "./AaveEcosystemReserveV2.sol";

/**
 * @title ProposalPayloadAaveEcosystemReserveWithVoting
 * @author BGD Labs
 * @notice Aave Governance Proposal payload, upgrading the implementation of the AAVE Ecosystem Reserve
 * The initialize() on the new implementation allows to vote on another Aave governance proposal
 */
contract ProposalPayloadAaveEcosystemReserveWithVoting {
  address public immutable AAVE_ECOSYSTEM_RESERVE_V2_IMPL;
  address public constant AAVE_GOVERNANCE_V2 =
    0xEC568fffba86c094cf06b22134B23074DFE2252c;

  IInitializableAdminUpgradeabilityProxy
    public constant AAVE_ECOSYSTEM_RESERVE_PROXY =
    IInitializableAdminUpgradeabilityProxy(
      0x25F2226B597E8F9514B3F68F00f494cF4f286491
    );

  constructor(address aaveEcosystemReserveV2Impl) {
    AAVE_ECOSYSTEM_RESERVE_V2_IMPL = aaveEcosystemReserveV2Impl;
  }

  function execute(uint256 payloadId) external {
    require(payloadId != 0, 'PAYLOAD_ID_BIGGER_THAN_0');

    AAVE_ECOSYSTEM_RESERVE_PROXY.upgradeToAndCall(
      AAVE_ECOSYSTEM_RESERVE_V2_IMPL,
      abi.encodeWithSelector(
        IStreamable(AAVE_ECOSYSTEM_RESERVE_V2_IMPL).initialize.selector,
        payloadId,
        AAVE_GOVERNANCE_V2
      )
    );
  }
}
