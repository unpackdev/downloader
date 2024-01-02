// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Policy.sol";
import "./Proposal.sol";
import "./ECOx.sol";
import "./TrustedNodes.sol";

/** @title DeployRootPolicyFundw
 * A proposal to send some root policy funds to another
 * address (multisig, lockup, etc)
 */
contract Cohort2Election is Policy, Proposal {
    address[] public newTrustees;

    uint256 public immutable votingECOxContributions;

    uint256 public immutable nonvotingECOxContributions;

    address public constant VOTING_ECOX_RECIPIENT_ADDRESS =
        0x9fA130E9d1dA166164381F6d1de8660da0afc1f1;

    address public constant NONVOTING_ECOX_RECIPIENT_ADDRESS =
        0x99f98ea4A883DB4692Fa317070F4ad2dC94b05CE;

    constructor(
        address[] memory _newTrustees,
        uint256 _votingECOxContributions,
        uint256 _nonvotingECOxContributions
    ) {
        // ether here indicates x1E18, these are still quantities of ECOx
        newTrustees = _newTrustees;
        votingECOxContributions = _votingECOxContributions * 1 ether;
        nonvotingECOxContributions = _nonvotingECOxContributions * 1 ether;
    }

    function name() external view returns (string memory) {
        return "Cohort 2 election";
    }

    function description() external view returns (string memory) {
        return
            "Elects trustees into the new cohort and provides funding to the TrustedNodes contract and the Association Treasury in order to compensate Trustees and Trustee Observers respectively";
    }

    function url() external view returns (string memory) {
        return "https://forums.eco.org/t/new-trustee-cohort-election/339";
    }

    function returnNewTrustees() public view returns (address[] memory) {
        return newTrustees;
    }

    function enacted(address _self) public override {
        TrustedNodes _trustedNodes = TrustedNodes(
            policyFor(keccak256("TrustedNodes"))
        );
        address[] memory _newTrustees = Cohort2Election(_self)
            .returnNewTrustees();
        _trustedNodes.newCohort(_newTrustees);

        ECOx ecoX = ECOx(policyFor(keccak256("ECOx")));
        ecoX.transfer(VOTING_ECOX_RECIPIENT_ADDRESS, votingECOxContributions);
        ecoX.transfer(
            NONVOTING_ECOX_RECIPIENT_ADDRESS,
            nonvotingECOxContributions
        );
    }
}
