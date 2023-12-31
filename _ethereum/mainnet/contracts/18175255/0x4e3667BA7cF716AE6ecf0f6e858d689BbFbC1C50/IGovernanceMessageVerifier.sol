// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/**
 * @title IGovernanceMessageVerifier
 * @author pNetwork
 *
 * @notice
 */

interface IGovernanceMessageVerifier {
    struct GovernanceMessageProof {
        bytes rootHashProof;
        uint256 rootHashProofIndex;
        bytes32 receiptsRoot;
        uint256 blockNumber;
        uint256 blockTimestamp;
        bytes32 transactionsRoot;
        bytes receiptsRootProofPath;
        bytes receiptsRootProofParentNodes;
        bytes receipt;
        uint256 logIndex;
        uint8 transactionType;
        uint256 headerBlock;
    }

    /**
     * @dev Emitted when a governance message is propagated.
     *
     * @param data The governance message
     */
    event GovernanceMessagePropagated(bytes data);

    /*
     * @notice Returns if a message has been processed by providing the proof.
     *
     * @param proof
     *
     * @return bool indicating if the message has been processed or not.
     */
    function isProcessed(GovernanceMessageProof calldata proof) external view returns (bool);

    /*
     * @notice Returns the id of a message proof.
     *
     * @param proof
     *
     * @return bytes32 representing the id of a message proof.
     */
    function proofIdOf(GovernanceMessageProof calldata proof) external pure returns (bytes32);

    /*
     * @notice Verify that a certain event has been emitted on Polygon by the GovernanceMessageEmitter and propagate the message
     *
     * @param proof
     * @param destinationAddresses
     *
     */
    function verifyAndPropagateMessage(GovernanceMessageProof calldata proof) external;
}
