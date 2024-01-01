// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./BridgeTransfer.sol";
import "./BridgeSignatures.sol";

// Import SafeERC20 from OpenZeppelin Contracts
import "./SafeERC20.sol";

abstract contract BridgeRefundRequest is BridgeTransfer, BridgeSignatures {
    using SafeERC20 for IERC20;

    event RefundStatusChanged(
        address indexed from,
        uint256 indexed nonce,
        RefundStatus indexed status,
        uint64 timestamp
    );

    enum RefundStatus {
        None,
        Requested,
        Claimed,
        Declined
    }

    uint256 public constant REFUND_REQUEST_MIN_DELAY = 1 days;
    bytes32 public constant REFUND_APPROVE_SIGNATURE =
        keccak256("REFUND_APPROVE_SIGNATURE(uint256 nonce,bool approved,uint256 deadline)");

    /**
     * @dev Refund request struct.
     * @param status The status of the refund request.
     * @param timestamp The timestamp of the refund request.
     * @param from The address of the user who requested the refund.
     * @param nonce The nonce of the teleport.
     */
    struct RefundRequest {
        RefundStatus status;
        uint64 timestamp;
        address from;
        uint256 nonce;
    }

    mapping(uint256 => RefundRequest) public refundRequests;

    /**
     * @dev Modifier to check if the refund request exists and is in the requested state.
     * @param nonce The nonce of the request(teleport).
     */
    modifier onlyRequestedRefund(uint256 nonce) {
        require(
            refundRequests[nonce].status == RefundStatus.Requested,
            "Bridge: Refund not requested or is already processed"
        );
        _;
    }

    /**
     * @dev Modifier to check if the refund request delay has passed.
     * @param nonce The nonce of the request(teleport).
     */
    modifier onlyRefundRequestDelayPassed(uint256 nonce) {
        require(
            refundRequests[nonce].timestamp + REFUND_REQUEST_MIN_DELAY <= block.timestamp,
            "Bridge: Refund request delay has not passed"
        );
        _;
    }

    /**
     * @dev Requests a refund for a teleport if tokens were not transferred for some reason.
     * @param nonce The nonce of the teleport.
     */
    function requestRefund(uint256 nonce) public {
        require(
            teleports[nonce].from == msg.sender,
            "Bridge: Only the sender can request a refund or teleport does not exist"
        );
        require(
            refundRequests[nonce].status == RefundStatus.None,
            "Bridge: Refund already requested or is already processed"
        );

        emit RefundStatusChanged(msg.sender, nonce, RefundStatus.Requested, uint64(block.timestamp));

        refundRequests[nonce] = RefundRequest({
            status: RefundStatus.Requested,
            timestamp: uint64(block.timestamp),
            from: msg.sender,
            nonce: nonce
        });
    }

    /**
     * @dev Approves a refund request.
     * @param nonce The nonce of the teleport.
     * @param signatures Signatures for the approved refund.
     */
    function _approveRefund(
        uint256 nonce,
        SignatureWithDeadline[] memory signatures
    ) internal onlyRequestedRefund(nonce) onlyRefundRequestDelayPassed(nonce) {
        bytes32[] memory digests = new bytes32[](signatures.length);

        for (uint256 id = 0; id < signatures.length; id++) {
            digests[id] = _getRefundApproveDigest(nonce, signatures[id].deadline);
        }

        _checkSignatures(digests, signatures);

        emit RefundStatusChanged(refundRequests[nonce].from, nonce, RefundStatus.Claimed, uint64(block.timestamp));

        refundRequests[nonce].status = RefundStatus.Claimed;

        token.safeTransfer(refundRequests[nonce].from, teleports[nonce].amount);
    }

    /**
     * @dev Declines a refund request.
     * @param nonce The nonce of the teleport.
     */
    function _declineRefund(uint256 nonce) internal onlyRequestedRefund(nonce) onlyRefundRequestDelayPassed(nonce) {
        emit RefundStatusChanged(refundRequests[nonce].from, nonce, RefundStatus.Declined, uint64(block.timestamp));

        refundRequests[nonce].status = RefundStatus.Declined;
    }

    /**
     * @dev Reopens a declined refund request.
     * @param nonce The nonce of the teleport.
     */
    function _reopenRefund(uint256 nonce) internal {
        require(refundRequests[nonce].status == RefundStatus.Declined, "Bridge: Refund not declined");

        emit RefundStatusChanged(refundRequests[nonce].from, nonce, RefundStatus.Requested, uint64(block.timestamp));

        refundRequests[nonce].status = RefundStatus.Requested;
        refundRequests[nonce].timestamp = uint64(block.timestamp);
    }

    /**
     * @dev Get typehash of the refund request
     * @param nonce Nonce of the refund to process
     * @param deadline Deadline of the signature
     */
    function _getRefundApproveDigest(uint256 nonce, uint256 deadline) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(REFUND_APPROVE_SIGNATURE, nonce, true, deadline));
        bytes32 digest = _hashTypedDataV4(structHash);
        return digest;
    }
}
