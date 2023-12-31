// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC4907.sol";

interface ILendable is IERC4907 {

    /*
        @notice Lends the frame to the target user with the possibility to update the frame.
        @dev The caller must be the owner of the target frame.
        @param tokenId The id of the target frame.
        @param user The address to which the frame is lent.
        @param expires The expire timestamp.
    */
    function setUserWithUploads(uint256 tokenId, address user, uint64 expires) external;

    /*
        @notice User previously being the target of a lending can claim the artwork they previously put in the
            target frame. The artwork will be transferred from the frame to the artwork's owner.
        @dev The caller must own the artwork currently inside the target frame.
        @param to The address that will receive the artwork inside the target frame.
        @param frameId The id of the target frame.
    */
    function claimArtwork(address to, uint256 frameId) external;

    /*
        @notice The owner of the frame can empty the target frame after the lending period is expired.
        @param frameId The target frame id.
    */
    function claimFrame(uint256 frameId) external;

    /*
        @notice Lends an artwork already transferred to a frame, to another frame for a certain period.
        @dev The caller must own the lender frame.
        @param lenderId The id of the frame from which the artwork is lent.
        @param recipient The id of the frame that will receive the artwork.
        @param expires The expiration timestamp.
    */
    function lendArtwork(uint256 lenderId, uint256 recipient, uint256 expires) external;

    /*
        @notice Allows or revoke account to lend artworks or frames to the sender.
        @param account The target account.
        @param allowed True if the target account will be allowed, false if revoked.
    */
    function allowAccount(address account, bool allowed) external;

    /*
        @notice Return true if the target frame can be updated by the target user of the lending.
        @param frameId The id of the target frame.
        @return True if the frame can be updated, false otherwise.
    */
    function canBeUpdated(uint256 frameId) view external returns(bool);

    /*
        @notice Return true if the target account is allowed to lend artworks or frames to the owner.
        @param owner The owner account.
        @param account The target account.
        @return True if the target account is allowed for owner.
    */
    function isAccountAllowed(address owner, address account) view external returns(bool);

    /*
        @notice Emitted when an account is allowed.
        @param sender The sender account.
        @param account The target account.
        @param allowed True if the target account will be allowed, false if revoked.
    */
    event AccountAllowed(address indexed sender, address indexed account, bool allowed);

}
