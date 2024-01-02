// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/** @title Proposal
 * Interface specification for proposals. Any proposal submitted in the
 * policy decision process must implement this interface.
 */
abstract contract Proposal {
    /** The name of the proposal.
     *
     * This should be relatively unique and descriptive.
     */
    function name() external view virtual returns (string memory);

    /** A longer description of what this proposal achieves.
     */
    function description() external view virtual returns (string memory);

    /** A URL where voters can go to see the case in favour of this proposal,
     * and learn more about it.
     */
    function url() external view virtual returns (string memory);

    /** Called to enact the proposal.
     *
     * This will be called from the root policy contract using delegatecall,
     * with the direct proposal address passed in as _self so that storage
     * data can be accessed if needed.
     *
     * @param _self The address of the proposal contract.
     */
    function enacted(address _self) external virtual;
}


/** @title MyProposal
 * A proposal to make some change
 */
contract MyProposal is Proposal {

    /** Instantiate a new proposal.
     */
    constructor() {

    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "2024 Eco Trustee Election: Preliminary Vote";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return "The Eco Association proposes that the  details outlined in the forum post for the Trustee year starting on January 6th, 2024 and ending on January 4th, 2025 be voted on by the community.This EGP represents an onchain record of community support or non-support for three things:  the proposed slate of nine Trustees, the program structure, and the compensation funding request for 2024. If this proposal passes, a second EGP will be submitted and automatically supported & voted upon by the Eco Association inGeneration 1031 to formally enact the details onchain. The separation of this specific proposal into two votes is due to an unforeseen technical constraint.";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return "https://forums.eco.org/t/2024-eco-trustee-election/322";
    }

    /** Enact the proposal.
     *
     * This is executed in the storage context of the root policy contract.
     *
     * @param _self The address of the proposal.
     */
    function enacted(address _self) public override {
        // Write code here
    }
}