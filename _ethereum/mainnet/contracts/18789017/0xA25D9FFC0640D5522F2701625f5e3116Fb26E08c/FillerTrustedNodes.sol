// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrustedNodes.sol";
import "./ImplementationUpdatingTarget.sol";

/** @title FillerTrustedNodes
 * Delegate call function data contract to fill an empty array on TrustedNodes and do the missed functionality of annualUpdate()
 */
contract FillerTrustedNodes is TrustedNodes {
    // values are unused
    constructor(address[] memory addresses)
        TrustedNodes(
            Policy(0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0),
            addresses, //_initialTrustedNodes
            12345 //_voteReward
        )
    {}

    /** Function for executing the missed parts of annualUpdate() due to everTrustee being empty
     * Also fills everTrustee with the correct addresses
     *
     * This is executed in the storage context of the TrustedNodes contract by the proposal.
     *
     *
     */
    function annualUpdateFix(uint256 _yearEnd, uint256 cohort) public {
        address[] memory trustees = cohorts[cohort].trustedNodes;
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < trustees.length; ++i) {
            address trustee = trustees[i];
            everTrustee.push(trustee);
            totalVotes += votingRecord[trustees[i]];
        }

        // total possible rewards - number of votes that have been recorded as of the end of generation 29
        unallocatedRewardsCount =
            trustees.length *
            GENERATIONS_PER_YEAR -
            totalVotes;

        yearEnd = _yearEnd;
    }
}
