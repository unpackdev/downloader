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

// OpenZeppelin imports
import "./IERC20.sol";

// Local imports
import "./MilestoneConstants.sol";
import "./MilestoneEncoder.sol";
import "./RequestTypes.sol";
import "./EnumTypes.sol";
import "./StorageTypes.sol";
import "./LibInvestorFundsInfo.sol";
import "./LibMilestone.sol";
import "./LibEscrow.sol";
import "./LibRaise.sol";
import "./LibERC20Asset.sol";
import "./RequestService.sol";
import "./SignatureService.sol";
import "./MilestoneEvents.sol";
import "./MilestoneErrors.sol";
import "./RaiseErrors.sol";
import "./IMilestoneFacet.sol";

// Local imports - Internal services
import "./RaiseService.sol";

/**************************************

    Milestone facet

**************************************/

/// @notice Milestone facet implementing unlocking of new milestones for raises and claiming of unlocked tokens.
contract MilestoneFacet is IMilestoneFacet {
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
    function unlockMilestone(
        RequestTypes.UnlockMilestoneRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // validation
        RequestService.validateBaseRequest(_request.base);
        _validateCompletedRaise(_request.raiseId);
        _validateUnlockMilestoneRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = MilestoneEncoder.encodeUnlockMilestone(_request);

        // verify message
        SignatureService.verifyMessage(MilestoneConstants.EIP712_NAME, MilestoneConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);

        // unlock milestone
        LibMilestone.unlockMilestone(_request.raiseId, _request.milestone);

        // events
        emit MilestoneEvents.MilestoneUnlocked(_request.raiseId, _request.milestone);
    }

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
    function claimMilestoneStartup(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // validation
        RequestService.validateBaseRequest(_request.base);
        _validateRaiseExists(_request.raiseId);
        _validateClaimMilestoneStartup(_request.raiseId, msg.sender);

        // get available
        uint256 available_ = _getAvailableForStartup(_request.raiseId);
        if (available_ == 0) revert MilestoneErrors.NothingToClaim(_request.raiseId, _request.recipient);

        // validate msg and sig
        _verifyClaimMsgSig(_request, _message, _v, _r, _s);

        // claim USDT
        LibMilestone.claimMilestoneStartup(_request.raiseId, LibEscrow.getEscrow(_request.raiseId), _request.recipient, available_);

        // events
        emit MilestoneEvents.MilestoneUnlocked__StartupClaimed(_request.raiseId, _request.recipient, available_);
    }

    /// @dev Claim milestone by investor.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by user that invested in raise.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: InvestorClaimed(string raiseId, address erc20, address startup, uint256 claimed).
    /// @param _request ClaimRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function claimMilestoneInvestor(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // validation
        RequestService.validateBaseRequest(_request.base);
        _validateRaiseExists(_request.raiseId);
        _validateClaimMilestoneInvestor(_request.raiseId, msg.sender);

        // get available
        uint256 available_ = _getAvailableForInvestor(_request.raiseId, msg.sender);
        if (available_ == 0) revert MilestoneErrors.NothingToClaim(_request.raiseId, _request.recipient);

        // validate msg and sig
        _verifyClaimMsgSig(_request, _message, _v, _r, _s);

        // get erc20
        address erc20_ = LibERC20Asset.getAddress(_request.raiseId);

        // claim ERC20
        LibMilestone.claimMilestoneInvestor(_request.raiseId, erc20_, LibEscrow.getEscrow(_request.raiseId), _request.recipient, available_);

        // events
        emit MilestoneEvents.MilestoneUnlocked__InvestorClaimed(_request.raiseId, erc20_, _request.recipient, available_);
    }

    // -----------------------------------------------------------------------
    //                              Internal
    // -----------------------------------------------------------------------

    /// @dev Validate unlock milestone request.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Milestone data needs to have correct number and share under 100% cap in total.
    /// @param _request UnlockMilestoneRequest struct
    function _validateUnlockMilestoneRequest(RequestTypes.UnlockMilestoneRequest calldata _request) internal view {
        // verify milestone number
        uint256 milestoneCount_ = LibMilestone.milestoneCount(_request.raiseId);
        if (_request.milestone.milestoneNo != milestoneCount_ + 1) {
            revert MilestoneErrors.InvalidMilestoneNumber(_request.milestone.milestoneNo, milestoneCount_);
        }

        // verify share greater than 0
        if (_request.milestone.share == 0) {
            revert MilestoneErrors.ZeroShare(_request.milestone.milestoneNo);
        }

        // verify sum of shares max 100
        uint256 shares_ = LibMilestone.totalShares(_request.raiseId);
        if (_request.milestone.share + shares_ > 100 * LibMilestone.SHARE_PRECISION) {
            revert MilestoneErrors.ShareExceedLimit(_request.milestone.share, shares_);
        }
    }

    /// @dev Validate claim milestone by startup request.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by raise owner (startup).
    /// @param _raiseId ID of raise
    /// @param _recipient Address of startup
    function _validateClaimMilestoneStartup(string memory _raiseId, address _recipient) internal view {
        // TODO: Check if erc20 is on this chain

        // check if sender is startup
        if (_recipient != LibRaise.getOwner(_raiseId)) {
            revert RaiseErrors.CallerNotStartup(_recipient, _raiseId);
        }
    }

    /// @dev Validate claim milestone by investor request.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Can be only called by user that invested in raise.
    /// @param _raiseId ID of raise
    /// @param _recipient Address of investor
    function _validateClaimMilestoneInvestor(string memory _raiseId, address _recipient) internal view {
        // TODO: Check if base asset is on this chain

        // check if sender invested
        if (LibInvestorFundsInfo.getInvested(_raiseId, _recipient) == 0) {
            revert RaiseErrors.UserHasNotInvested(_recipient, _raiseId);
        }

        // check if erc20 is set and deposited for claiming
        if (LibRaise.getType(_raiseId) == EnumTypes.RaiseType.EarlyStage) {
            _validateEarlyStageERC20(_raiseId);
        }
    }

    // -----------------------------------------------------------------------
    //                              Get available
    // -----------------------------------------------------------------------

    /// @dev Get available funds to claim by startup.
    /// @return Amount of unlocked base asset available to claim
    function getAvailableForStartup(string memory _raiseId) external view returns (uint256) {
        // validation
        _validateCompletedRaise(_raiseId);
        _validateClaimMilestoneStartup(_raiseId, msg.sender);

        // return
        return _getAvailableForStartup(_raiseId);
    }

    /// @dev Return available USDC to claim for startup
    function _getAvailableForStartup(string memory _raiseId) internal view returns (uint256) {
        // get raised
        uint256 total_ = LibRaise.getRaised(_raiseId);

        // compute claimable
        uint256 claimable_ = (LibMilestone.unlockedShares(_raiseId) * total_) / (100 * LibMilestone.SHARE_PRECISION);

        // get claimed
        uint256 claimed_ = LibMilestone.getStartupClaimedVoting(_raiseId);

        // return available
        return claimable_ - claimed_;
    }

    /// @dev Get available funds to claim by investor.
    /// @return Amount of unlocked ERC20s available to claim
    function getAvailableForInvestor(string memory _raiseId, address _account) external view returns (uint256) {
        // validation
        _validateCompletedRaise(_raiseId);
        _validateClaimMilestoneInvestor(_raiseId, _account);

        // return
        return _getAvailableForInvestor(_raiseId, _account);
    }

    /// @dev Return available ERC20 to claim for investor
    function _getAvailableForInvestor(string memory _raiseId, address _account) internal view returns (uint256) {
        // get investment
        uint256 invested_ = LibInvestorFundsInfo.getInvested(_raiseId, _account);

        // get raised
        uint256 total_ = LibRaise.getRaised(_raiseId);

        // compute share
        uint256 share_ = (invested_ * LibMilestone.SHARE_PRECISION) / total_;

        // get all tokens for investor
        uint256 userDebt_ = (share_ * RaiseService.getSold(_raiseId)) / LibMilestone.SHARE_PRECISION;

        // compute claimable
        uint256 claimable_ = (LibMilestone.unlockedShares(_raiseId) * userDebt_) / (100 * LibMilestone.SHARE_PRECISION);

        // get claimed
        uint256 claimed_ = LibMilestone.getInvestorClaimedVoting(_raiseId, _account);

        // return available
        return claimable_ - claimed_;
    }

    // -----------------------------------------------------------------------
    //                              Failed repair plan
    // -----------------------------------------------------------------------

    /// @dev Submit failed repair plan and reject future milestones for given raise.
    /// @dev Validation: Requires raise that is finished and has reached softcap.
    /// @dev Validation: Require raise that was not rejected before and has not fully unlocked shares.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: RaiseRejected(string raiseId, uint256 rejectedShares).
    /// @param _request RejectRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function rejectRaise(RequestTypes.RejectRaiseRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // validate request
        RequestService.validateBaseRequest(_request.base);
        _validateCompletedRaise(_request.raiseId);
        _validateRejectRaiseRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = MilestoneEncoder.encodeRejectRaise(_request);

        // verify message
        SignatureService.verifyMessage(MilestoneConstants.EIP712_NAME, MilestoneConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);

        // reject raise
        uint256 rejectedShares_ = LibMilestone.rejectRaise(_request.raiseId);

        // events
        emit MilestoneEvents.RaiseRejected(_request.raiseId, rejectedShares_);
    }

    // -----------------------------------------------------------------------
    //                              Claim (repair plan)
    // -----------------------------------------------------------------------

    function claimRejectedStartup(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // validation
        RequestService.validateBaseRequest(_request.base);
        _validateRaiseExists(_request.raiseId);
        _validateClaimRejectedStartup(_request.raiseId, msg.sender);

        // get available
        uint256 available_ = _getRejectedForStartup(_request.raiseId);
        if (available_ == 0) revert MilestoneErrors.NothingToClaim(_request.raiseId, _request.recipient);

        // validate msg and sig
        _verifyClaimMsgSig(_request, _message, _v, _r, _s);

        // get erc20
        address erc20_ = LibERC20Asset.getAddress(_request.raiseId);

        // claim ERC20
        LibMilestone.claimRejectedStartup(_request.raiseId, erc20_, LibEscrow.getEscrow(_request.raiseId), _request.recipient, available_);

        // events
        emit MilestoneEvents.RaiseRejected__StartupClaimed(_request.raiseId, erc20_, _request.recipient, available_);
    }

    function claimRejectedInvestor(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // validate request
        RequestService.validateBaseRequest(_request.base);
        _validateRaiseExists(_request.raiseId);
        _validateClaimRejectedInvestor(_request.raiseId, msg.sender);

        // get available
        uint256 available_ = _getRejectedForInvestor(_request.raiseId, msg.sender);
        if (available_ == 0) revert MilestoneErrors.NothingToClaim(_request.raiseId, _request.recipient);

        // validate msg and sig
        _verifyClaimMsgSig(_request, _message, _v, _r, _s);

        // claim ERC20
        LibMilestone.claimRejectedInvestor(_request.raiseId, LibEscrow.getEscrow(_request.raiseId), _request.recipient, available_);

        // events
        emit MilestoneEvents.RaiseRejected__InvestorClaimed(_request.raiseId, _request.recipient, available_);
    }

    // -----------------------------------------------------------------------
    //                              Internal (repair plan)
    // -----------------------------------------------------------------------

    function _validateRejectRaiseRequest(RequestTypes.RejectRaiseRequest calldata _request) internal view {
        // Ensure raise was not rejected already
        uint256 rejected_ = LibMilestone.rejectedShares(_request.raiseId);
        if (rejected_ > 0) {
            revert MilestoneErrors.RaiseAlreadyRejected(_request.raiseId, rejected_);
        }

        // Ensure milestones are not 100%
        uint256 shares_ = LibMilestone.totalShares(_request.raiseId);
        if (shares_ >= 100 * LibMilestone.SHARE_PRECISION) {
            revert MilestoneErrors.AllMilestonesUnlocked(_request.raiseId, shares_);
        }
    }

    function _validateClaimRejectedStartup(string memory _raiseId, address _recipient) internal view {
        // TODO: Check if base asset is on this chain

        // check if sender is startup
        if (_recipient != LibRaise.getOwner(_raiseId)) {
            revert RaiseErrors.CallerNotStartup(_recipient, _raiseId);
        }

        // check if raise was rejected
        if (LibMilestone.rejectedShares(_raiseId) == 0) {
            revert MilestoneErrors.RaiseNotRejected(_raiseId);
        }

        // check if erc20 is set and deposited for claiming
        if (LibRaise.getType(_raiseId) == EnumTypes.RaiseType.EarlyStage) {
            _validateEarlyStageERC20(_raiseId);
        }
    }

    function _validateClaimRejectedInvestor(string memory _raiseId, address _recipient) internal view {
        // TODO: Check if base asset is on this chain

        // check if sender invested
        if (LibInvestorFundsInfo.getInvested(_raiseId, _recipient) == 0) {
            revert RaiseErrors.UserHasNotInvested(_recipient, _raiseId);
        }

        // check if raise was rejected
        if (LibMilestone.rejectedShares(_raiseId) == 0) {
            revert MilestoneErrors.RaiseNotRejected(_raiseId);
        }
    }

    // -----------------------------------------------------------------------
    //                              Get available (failed repair plan)
    // -----------------------------------------------------------------------

    function getRejectedForStartup(string memory _raiseId) external view returns (uint256) {
        // validation
        _validateCompletedRaise(_raiseId);
        _validateClaimRejectedStartup(_raiseId, msg.sender);

        // return
        return _getRejectedForStartup(_raiseId);
    }

    /// @dev Return available ERC20 to claim back for startup
    function _getRejectedForStartup(string memory _raiseId) internal view returns (uint256) {
        // get sold
        uint256 sold_ = RaiseService.getSold(_raiseId);

        // compute claimable
        uint256 claimable_ = (LibMilestone.rejectedShares(_raiseId) * sold_) / (100 * LibMilestone.SHARE_PRECISION);

        // get claimed
        uint256 claimed_ = LibMilestone.getStartupClaimedRejected(_raiseId);

        // return available
        return claimable_ - claimed_;
    }

    function getRejectedForInvestor(string memory _raiseId, address _account) external view returns (uint256) {
        // validation
        _validateCompletedRaise(_raiseId);
        _validateClaimRejectedInvestor(_raiseId, _account);

        // return
        return _getRejectedForInvestor(_raiseId, _account);
    }

    /// @dev Return available USDT to claim back for investor
    function _getRejectedForInvestor(string memory _raiseId, address _account) internal view returns (uint256) {
        // get investment
        uint256 invested_ = LibInvestorFundsInfo.getInvested(_raiseId, _account);

        // compute claimable
        uint256 claimable_ = (LibMilestone.rejectedShares(_raiseId) * invested_) / (100 * LibMilestone.SHARE_PRECISION);

        // get claimed
        uint256 claimed_ = LibMilestone.getInvestorClaimedRejected(_raiseId, _account);

        // return available
        return claimable_ - claimed_;
    }

    // -----------------------------------------------------------------------
    //                              Common
    // -----------------------------------------------------------------------

    function _validateRaiseExists(string memory _raiseId) internal view {
        // verify raise exists
        if (!RaiseService.isRaiseExists(_raiseId)) {
            revert RaiseErrors.RaiseDoesNotExists(_raiseId);
        }
    }

    function _validateCompletedRaise(string memory _raiseId) internal view {
        // verify raise exists
        _validateRaiseExists(_raiseId);

        // verify raise ended
        if (!RaiseService.isRaiseFinished(_raiseId)) {
            revert RaiseErrors.RaiseNotFinished(_raiseId);
        }

        // check if raise reach softcap
        if (!RaiseService.isSoftcapAchieved(_raiseId)) {
            revert RaiseErrors.SoftcapNotAchieved(_raiseId);
        }
    }

    function _validateEarlyStageERC20(string memory _raiseId) internal view {
        // get erc20
        address erc20_ = LibERC20Asset.getAddress(_raiseId);

        // check if erc20 address is set
        if (erc20_ == address(0)) revert RaiseErrors.TokenNotSet(_raiseId);

        // get escrow
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // check if erc20 is present on escrow for claiming
        if (IERC20(erc20_).balanceOf(escrow_) == 0) {
            revert MilestoneErrors.TokenNotOnEscrow(_raiseId);
        }
    }

    /// @dev Verify claim milestone message and signature.
    /// @dev Validation: Requires correct message with valid cosignature from AngelBlock validator to execute.
    /// @param _request ClaimRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function _verifyClaimMsgSig(RequestTypes.ClaimRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        // eip712 encoding
        bytes memory encodedMsg_ = MilestoneEncoder.encodeClaim(_request);

        // verify message
        SignatureService.verifyMessage(MilestoneConstants.EIP712_NAME, MilestoneConstants.EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        SignatureService.verifySignature(_message, _v, _r, _s);
    }
}
