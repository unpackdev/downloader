pragma solidity ^0.8.0;

import "./Policy.sol";
import "./Policed.sol";
import "./FillerTrustedNodes.sol";
import "./Proposal.sol";
import "./TrustedNodes.sol";

/** @title TrustedNodesDataMigration
 * A proposal to patch some issues with trustee reward redemption around an unmigrated data structure
 */
contract FillTrusteeArray is Policy, Proposal {
    /** The address of the contract that will update the impl
     */
    address public immutable fillerTrustedNodes;

    /** The yearEnd to adjust for the new election
     */
    uint256 public immutable newYearEnd;

    /** The cohort to be adjusted
     */
    uint256 public immutable cohort;

    /** ID of the TrustedNodes contract
     */
    bytes32 public constant TRUSTED_NODES_ID = keccak256("TrustedNodes");

    constructor(
        address _fillerTrustedNodes,
        uint256 _newYearEnd,
        uint256 _cohort
    ) {
        fillerTrustedNodes = _fillerTrustedNodes;
        newYearEnd = _newYearEnd;
        cohort = _cohort;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "EGP #010 Rectify TrustedNodes votingRecord numbers";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return
            "This proposal fixes some voting record-related issues encountered with trustee annual update";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/egp-010-rectify-trustednodes-votingrecord-numbers/334";
    }

    function enacted(address self) public virtual override {
        TrustedNodes trustedNodesProxy = TrustedNodes(
            policyFor(TRUSTED_NODES_ID)
        );

        Policed(trustedNodesProxy).policyCommand(
            fillerTrustedNodes,
            abi.encodeWithSignature(
                "annualUpdateFix(uint256,uint256)",
                newYearEnd,
                cohort
            )
        );

        ECOx ecoX = ECOx(policyFor((keccak256("ECOx"))));
        uint256 amountToSend = trustedNodesProxy.numTrustees() *
            trustedNodesProxy.GENERATIONS_PER_YEAR() *
            trustedNodesProxy.voteReward() -
            ecoX.balanceOf(address(trustedNodesProxy));
        ecoX.transfer(address(trustedNodesProxy), amountToSend);
    }
}
