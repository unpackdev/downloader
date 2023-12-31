// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TrustedNodes.sol";
import "./ImplementationUpdatingTarget.sol";

/** @title SwitcherTrustedNodes
 * Delegate call function data contract for setter functions
 */
contract SwitcherTrustedNodes is TrustedNodes {
    // values are unused
    constructor(address[] memory addresses)
        TrustedNodes(
            Policy(0xDEADBEeFbAdf00dC0fFee1Ceb00dAFACEB00cEc0),
            addresses, //_initialTrustedNodes
            12345 //_voteReward
        )
    {}

    /** Function for changing the value of unallocatedRewards in TrustedNodes
     *
     * This is executed in the storage context of the TrustedNodes contract by the proposal.
     *
     * @param _unallocatedRewardsCount The correct value for unallocatedRewards, calculated on chain by the proposal.
     */
    function setUnallocatedRewards(uint256 _unallocatedRewardsCount) public {
        unallocatedRewardsCount = _unallocatedRewardsCount;
    }

    /** Function for changing the implementation for the trustedNodes proxy
     *
     * This is executed in the storage context of the TrustedNodes contract by the proposal.
     *
     * @param _newImplementation The new implementation of TrustedNodes
     */
    function updateImplementation(address _newImplementation) public {
        setImplementation(_newImplementation);
    }
}
