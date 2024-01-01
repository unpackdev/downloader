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
import "./RequestTypes.sol";

/**************************************

    Milestone facet interface

**************************************/

/// @notice Interface for milestone facet.
interface IMilestoneFacet {
    // -----------------------------------------------------------------------
    //                              Unlock
    // -----------------------------------------------------------------------

    /// @dev Unlock new milestone for given raise.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Milestone data needs to have correct number and share under 100% cap in total.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: MilestoneUnlocked(string raiseId, StorageTypes.Milestone milestone).
    /// @param _request UnlockMilestoneRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function unlockMilestone(RequestTypes.UnlockMilestoneRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    // -----------------------------------------------------------------------
    //                              Claim
    // -----------------------------------------------------------------------

    /// @dev Claim milestone by startup.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by raise owner (startup).
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: StartupClaimed(string raiseId, address startup, uint256 claimed).
    /// @param _request ClaimRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function claimMilestoneStartup(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /// @dev Claim milestone by investor.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by user that invested in raise.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: InvestorClaimed(string raiseId, address erc20, address investor, uint256 claimed).
    /// @param _request ClaimRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function claimMilestoneInvestor(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    // -----------------------------------------------------------------------
    //                              Get available for claim
    // -----------------------------------------------------------------------

    /// @dev Get available funds to claim upon unlocked milestones by startup.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by raise owner (startup).
    /// @param _raiseId ID of raise
    /// @return Amount of USDT available for claim
    function getAvailableForStartup(string memory _raiseId) external view returns (uint256);

    /// @dev Get available funds to claim upon unlocked milestones by investor.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @param _raiseId ID of raise
    /// @param _account Address of investor
    /// @return Amount of ERC20 available for claim
    function getAvailableForInvestor(string memory _raiseId, address _account) external view returns (uint256);

    // -----------------------------------------------------------------------
    //                              Reject raise
    // -----------------------------------------------------------------------

    /// @dev Reject raise for failed repair plan scenario.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: RaiseRejected(string raiseId).
    /// @param _request RejectRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function rejectRaise(RequestTypes.RejectRaiseRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    // -----------------------------------------------------------------------
    //                              Claim rejected
    // -----------------------------------------------------------------------

    /// @dev Claim rejected funds (failed repair plan) by startup.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by raise owner (startup).
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: StartupClaimedRejected(string raiseId, address erc20, address startup, uint256 claimed).
    /// @param _request ClaimRejectedRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function claimRejectedStartup(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /// @dev Claim rejected funds (failed repair plan) by investor.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by user that invested in raise.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: InvestorClaimedRejected(string raiseId, address investor, uint256 claimed).
    /// @param _request ClaimRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function claimRejectedInvestor(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    // -----------------------------------------------------------------------
    //                              Get rejected for claim
    // -----------------------------------------------------------------------

    /// @dev Get available funds to claim for not unlocked milestones in rejected repair plan by startup.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by raise owner (startup).
    /// @param _raiseId ID of raise
    /// @return Amount of USDT available for claim
    function getRejectedForStartup(string memory _raiseId) external view returns (uint256);

    /// @dev Get available funds to claim for not unlocked milestones in rejected repair plan by investor.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @param _raiseId ID of raise
    /// @param _account Address of investor
    /// @return Amount of ERC20 available for claim
    function getRejectedForInvestor(string memory _raiseId, address _account) external view returns (uint256);
}
