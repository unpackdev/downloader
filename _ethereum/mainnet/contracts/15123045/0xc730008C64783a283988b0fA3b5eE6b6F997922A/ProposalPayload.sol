// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "./OtcEscrowApprovals.sol";
import "./IEcosystemReserveController.sol";

/// @title Payload to approve and execute BAL <> AAVE Swap
/// @author Llama
/// @notice Provides an execute function for Aave governance to approve and execute the BAL <> AAVE Swap
contract ProposalPayload {
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    IEcosystemReserveController public constant AAVE_ECOSYSTEM_RESERVE_CONTROLLER =
        IEcosystemReserveController(0x3d569673dAa0575c936c7c67c4E6AedA69CC630C);

    address public constant AAVE_ECOSYSTEM_RESERVE = 0x25F2226B597E8F9514B3F68F00f494cF4f286491;

    address public constant AAVE_TOKEN = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    uint256 public constant AAVE_AMOUNT = 1690728e16;

    OtcEscrowApprovals public constant OTC_ESCROW_APPROVALS =
        OtcEscrowApprovals(0x5AE986d7ca23fc3519daaa589E1d38d19BA42a47);

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Approve the OTC Escrow Approvals contract to transfer pre-defined amount of AAVE tokens
        AAVE_ECOSYSTEM_RESERVE_CONTROLLER.approve(
            AAVE_ECOSYSTEM_RESERVE,
            AAVE_TOKEN,
            address(OTC_ESCROW_APPROVALS),
            AAVE_AMOUNT
        );
        // Execute the OTC Escrow Approvals swap
        OTC_ESCROW_APPROVALS.swap();
    }
}
