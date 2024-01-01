// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

// Local imports
import "./MilestoneConstants.sol";
import "./RequestTypes.sol";

/**************************************

    Milestone encoder

**************************************/

/// @notice Milestone encoder for EIP712 message hash.
library MilestoneEncoder {
    /// @dev Encode unlock milestone request to validate the EIP712 message.
    /// @param _request UnlockMilestoneRequest struct
    /// @return EIP712 encoded message containing request
    function encodeUnlockMilestone(RequestTypes.UnlockMilestoneRequest memory _request) internal pure returns (bytes memory) {
        // milestone
        bytes memory encodedMilestone_ = abi.encode(_request.milestone);

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            MilestoneConstants.VOTING_UNLOCK_MILESTONE_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            keccak256(encodedMilestone_),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    /// @dev Encode claim milestone request to validate the EIP712 message.
    /// @param _request ClaimRequest struct
    /// @return EIP712 encoded message containing request
    function encodeClaim(RequestTypes.ClaimRequest memory _request) internal pure returns (bytes memory) {
        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            MilestoneConstants.USER_CLAIM_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.recipient,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    /// @dev Encode reject raise request to validate the EIP712 message.
    /// @param _request RejectRaiseRequest struct
    /// @return EIP712 encoded message containing request
    function encodeRejectRaise(RequestTypes.RejectRaiseRequest memory _request) internal pure returns (bytes memory) {
        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            MilestoneConstants.VOTING_REJECT_RAISE_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }
}
