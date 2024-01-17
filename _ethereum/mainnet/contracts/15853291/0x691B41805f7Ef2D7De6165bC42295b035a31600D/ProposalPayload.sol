// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./IAaveEcosystemReserveController.sol";
import "./AaveV2Ethereum.sol";

/**
 * @title Chaos <> AAVE Proposal
 * @author Chaos
 * @notice Payload to execute the Chaos <> AAVE Proposal
 * Governance Forum Post: https://governance.aave.com/t/updated-proposal-chaos-labs-risk-simulation-platform/10025
 * Snapshot: https://snapshot.org/#/aave.eth/proposal/0xad105e87d4df487bbe1daec2cd94ca49d1ea595901f5773c1804107539288b59
 */
contract ProposalPayload {
    /********************************
     *   CONSTANTS AND IMMUTABLES   *
     ********************************/

    // Chaos Recipient address
    address public constant CHAOS_RECIPIENT = 0xbC540e0729B732fb14afA240aA5A047aE9ba7dF0;
    address public constant AUSDC_TOKEN = 0xBcca60bB61934080951369a648Fb03DF4F96263C;

    // ~500,000 aUSDC = $0.5 million
    // Small additional amount to handle remainder condition during streaming
    // duration 180 days = 15552000 --> (500000e6 + [15552000 - 3200000]) % 15552000 = 0
    // https://github.com/bgd-labs/aave-ecosystem-reserve-v2/blob/release/final-proposal/src/AaveEcosystemReserveV2.sol#L229-L233
    uint256 public constant AUSDC_STREAM_AMOUNT = 500000e6 + 12352000;

    // 12 months of 30 days ~ 1 year
    uint256 public constant STREAMS_END = 360 days; // 6 months duration from start
    uint256 public constant STREAMS_START = 180 days; // in 6 months

    /*****************
     *   FUNCTIONS   *
     *****************/

    /// @notice The AAVE governance executor calls this function to implement the proposal.
    function execute() external {
        // Stream of $0.5 million in aUSDC over 12 months
        IAaveEcosystemReserveController(AaveV2Ethereum.COLLECTOR_CONTROLLER).createStream(
            AaveV2Ethereum.COLLECTOR,
            CHAOS_RECIPIENT,
            AUSDC_STREAM_AMOUNT,
            AUSDC_TOKEN,
            block.timestamp + STREAMS_START,
            block.timestamp + STREAMS_END
        );
    }
}
