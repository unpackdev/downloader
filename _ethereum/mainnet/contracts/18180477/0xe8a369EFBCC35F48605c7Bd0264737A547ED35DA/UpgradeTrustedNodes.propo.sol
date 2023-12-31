pragma solidity ^0.8.0;

import "./Policy.sol";
import "./Policed.sol";
import "./SwitcherTrustedNodes.sol";
import "./Proposal.sol";
import "./TrustedNodes.sol";

/** @title TrustedNodesUpgrade
 * A proposal to patch some issues with trustee reward redemption
 */
contract UpgradeTrustedNodes is Policy, Proposal {
    /** The address of the new TrustedNodes impl
     */
    address public immutable newTrustedNodesImpl;

    /** The address of the contract that will update the impl
     */
    address public immutable switcherTrustedNodes;

    /** ID of the TrustedNodes contract
     */
    bytes32 public constant TRUSTED_NODES_ID = keccak256("TrustedNodes");

    constructor(address _newTrustedNodesImpl, address _switcherTrustedNodes) {
        newTrustedNodesImpl = _newTrustedNodesImpl;
        switcherTrustedNodes = _switcherTrustedNodes;
    }

    /** The name of the proposal.
     */
    function name() public pure override returns (string memory) {
        return "EGP #010 Patch TrustedNodes Contract";
    }

    /** A description of what the proposal does.
     */
    function description() public pure override returns (string memory) {
        return
            "This proposal patches some issues with trustee reward redemption";
    }

    /** A URL where more details can be found.
     */
    function url() public pure override returns (string memory) {
        return
            "https://forums.eco.org/t/egp-10-patch-trustednodes-contract/306";
    }

    function enacted(address self) public virtual override {
        TrustedNodes trustedNodesProxy = TrustedNodes(
            policyFor(TRUSTED_NODES_ID)
        );

        address[] memory trustees = trustedNodesProxy.getTrustedNodesFromCohort(
            trustedNodesProxy.cohort()
        );
        uint256 generationsInAYear = 26;
        uint256 _unallocatedRewardsCount = generationsInAYear * trustees.length;
        for (uint256 i = 0; i < trustees.length; i++) {
            _unallocatedRewardsCount -= trustedNodesProxy.votingRecord(
                trustees[i]
            );
        }

        Policed(trustedNodesProxy).policyCommand(
            switcherTrustedNodes,
            abi.encodeWithSignature(
                "updateImplementation(address)",
                newTrustedNodesImpl
            )
        );

        Policed(trustedNodesProxy).policyCommand(
            switcherTrustedNodes,
            abi.encodeWithSignature(
                "setUnallocatedRewards(uint256)",
                _unallocatedRewardsCount
            )
        );
    }
}
