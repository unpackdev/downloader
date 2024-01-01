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
import "./SafeERC20.sol";
import "./IERC20.sol";

// Local imports
import "./LibBaseAsset.sol";
import "./StorageTypes.sol";
import "./IEscrow.sol";

/**************************************

    Milestone library

    ------------------------------

    Diamond storage containing milestone data

 **************************************/

/// @notice Library containing MilestoneStorage and low level functions.
library LibMilestone {
    // -----------------------------------------------------------------------
    //                              Library usage
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev Milestone storage pointer.
    bytes32 internal constant MILESTONE_STORAGE_POSITION = keccak256("angelblock.fundraising.milestone");
    /// @dev Precision for share calculation.
    uint256 internal constant SHARE_PRECISION = 1_000_000;

    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Milestone storage struct.
    /// @param shares Mapping of raise id to struct containing share data
    /// @param votingClaiming Mapping of raise id to struct used to track claims after unlocked milestone
    /// @param repairPlanClaiming Mapping of raise id to struct used to track claims after failed repair plan
    struct MilestoneStorage {
        mapping(string => StorageTypes.ShareInfo) shares;
        mapping(string => StorageTypes.ClaimingInfo) votingClaiming;
        mapping(string => StorageTypes.ClaimingInfo) repairPlanClaiming;
    }

    // -----------------------------------------------------------------------
    //                              Diamond storage
    // -----------------------------------------------------------------------

    /// @dev Function returning milestone storage at storage pointer slot.
    /// @return ms MilestoneStorage struct instance at storage pointer position
    function milestoneStorage() internal pure returns (MilestoneStorage storage ms) {
        // declare position
        bytes32 position = MILESTONE_STORAGE_POSITION;

        // set slot to position
        assembly {
            ms.slot := position
        }

        // explicit return
        return ms;
    }

    // -----------------------------------------------------------------------
    //                              Getters / Setters
    // -----------------------------------------------------------------------

    /// @dev Diamond storage getter: milestones->length.
    /// @param _raiseId ID of raise
    /// @return Length of milestones
    function milestoneCount(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().shares[_raiseId].milestones.length;
    }

    /// @dev Diamond storage getter: milestones->share->sum.
    /// @param _raiseId ID of raise
    /// @return Sum of milestone shares (successful voting)
    function unlockedShares(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().shares[_raiseId].unlockedShares;
    }

    /// @dev Diamond storage getter: milestones->rejected->sum.
    /// @param _raiseId ID of raise
    /// @return Sum of rejected shares (failed repair plan)
    function rejectedShares(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().shares[_raiseId].rejectedShares;
    }

    /// @dev Diamond storage getter: milestones->share+rejected->sum.
    /// @param _raiseId ID of raise
    /// @return Sum of unlocked and rejected shares
    function totalShares(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().shares[_raiseId].totalShares;
    }

    /// @dev Diamond storage getter: investor claimed.
    /// @param _raiseId ID of raise
    /// @param _account Address of investor
    /// @return Claimed tokens by investor
    function getInvestorClaimedVoting(string memory _raiseId, address _account) internal view returns (uint256) {
        // return
        return milestoneStorage().votingClaiming[_raiseId].investorClaimed[_account];
    }

    /// @dev Diamond storage getter: startup claimed.
    /// @param _raiseId ID of raise
    /// @return Claimed base assets by investor
    function getStartupClaimedVoting(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().votingClaiming[_raiseId].startupClaimed;
    }

    /// @dev Diamond storage getter: investor claimed.
    /// @param _raiseId ID of raise
    /// @param _account Address of investor
    /// @return Claimed tokens by investor
    function getInvestorClaimedRejected(string memory _raiseId, address _account) internal view returns (uint256) {
        // return
        return milestoneStorage().repairPlanClaiming[_raiseId].investorClaimed[_account];
    }

    /// @dev Diamond storage getter: startup claimed.
    /// @param _raiseId ID of raise
    /// @return Claimed base assets by investor
    function getStartupClaimedRejected(string memory _raiseId) internal view returns (uint256) {
        // return
        return milestoneStorage().repairPlanClaiming[_raiseId].startupClaimed;
    }

    // -----------------------------------------------------------------------
    //                              Unlock
    // -----------------------------------------------------------------------

    /// @dev Unlock new milestone for raise.
    /// @param _raiseId ID of raise
    /// @param _milestone Milestone struct
    function unlockMilestone(string memory _raiseId, StorageTypes.Milestone memory _milestone) internal {
        // get shares
        StorageTypes.ShareInfo storage shares_ = milestoneStorage().shares[_raiseId];

        // register new unlocked milestone
        shares_.milestones.push(_milestone);

        // increase unlocked shares
        shares_.unlockedShares += _milestone.share;

        // increase total shares
        shares_.totalShares += _milestone.share;
    }

    // -----------------------------------------------------------------------
    //                              Claim
    // -----------------------------------------------------------------------

    /// @dev Claim milestone by startup.
    /// @param _raiseId ID of raise
    /// @param _escrow Address of escrow
    /// @param _recipient Address of startup
    /// @param _amount Tokens to claim
    function claimMilestoneStartup(string memory _raiseId, address _escrow, address _recipient, uint256 _amount) internal {
        // storage update
        milestoneStorage().votingClaiming[_raiseId].startupClaimed += _amount;

        // transfer USDT
        IEscrow(_escrow).withdraw(LibBaseAsset.getAddress(_raiseId), IEscrow.ReceiverData(_recipient, _amount));
    }

    /// @dev Claim milestone by investor.
    /// @param _raiseId ID of raise
    /// @param _erc20 Address of token to claim
    /// @param _escrow Address of escrow
    /// @param _recipient Address of investor
    /// @param _amount Tokens to claim
    function claimMilestoneInvestor(string memory _raiseId, address _erc20, address _escrow, address _recipient, uint256 _amount) internal {
        // storage update
        milestoneStorage().votingClaiming[_raiseId].investorClaimed[_recipient] += _amount;

        // transfer ERC20
        IEscrow(_escrow).withdraw(_erc20, IEscrow.ReceiverData(_recipient, _amount));
    }

    // -----------------------------------------------------------------------
    //                              Reject raise
    // -----------------------------------------------------------------------

    /// @dev Reject raise to revert the rest of locked shares.
    /// @param _raiseId ID of raise
    /// @return Amount of rejected shares
    function rejectRaise(string memory _raiseId) internal returns (uint256) {
        // get existing unlocked and rejected shares
        uint256 existing_ = totalShares(_raiseId);

        // calculate still locked shares
        uint256 remaining_ = 100 * SHARE_PRECISION - existing_;

        // set rejected shares
        milestoneStorage().shares[_raiseId].rejectedShares += remaining_;

        // set total shares
        milestoneStorage().shares[_raiseId].totalShares += remaining_;

        // return
        return remaining_;
    }

    // -----------------------------------------------------------------------
    //                              Claim (failed repair plan)
    // -----------------------------------------------------------------------

    /// @dev Claim rejected repair plan funds by startup.
    /// @param _raiseId ID of raise
    /// @param _erc20 Address of token to claim
    /// @param _escrow Address of escrow
    /// @param _recipient Address of startup
    /// @param _amount Tokens to claim
    function claimRejectedStartup(string memory _raiseId, address _erc20, address _escrow, address _recipient, uint256 _amount) internal {
        // storage update
        milestoneStorage().repairPlanClaiming[_raiseId].startupClaimed += _amount;

        // transfer ERC20
        IEscrow(_escrow).withdraw(_erc20, IEscrow.ReceiverData(_recipient, _amount));
    }

    /// @dev Claim rejected repair plan funds by investor.
    /// @param _raiseId ID of raise
    /// @param _escrow Address of escrow
    /// @param _recipient Address of investor
    /// @param _amount Tokens to claim
    function claimRejectedInvestor(string memory _raiseId, address _escrow, address _recipient, uint256 _amount) internal {
        // storage update
        milestoneStorage().repairPlanClaiming[_raiseId].investorClaimed[_recipient] += _amount;

        // transfer USDT
        IEscrow(_escrow).withdraw(LibBaseAsset.getAddress(_raiseId), IEscrow.ReceiverData(_recipient, _amount));
    }
}
