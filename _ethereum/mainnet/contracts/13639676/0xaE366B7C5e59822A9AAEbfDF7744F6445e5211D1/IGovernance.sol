//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IGovernance {
    /// @notice An event emitted once member is updated
    event MemberUpdated(address member, bool status);

    /**
     *  @notice Initializes the Governance facet with an initial set of members
     *  @param _members The initial set of members
     */
    function initGovernance(address[] memory _members) external;

    /**
     *  @notice Adds/removes a member account
     *  @param _account The account to be modified
     *  @param _status Whether the account will be set as member or not
     *  @param _signatures The signatures of the validators authorizing this member update
     */
    function updateMember(address _account, bool _status, bytes[] calldata _signatures) external;

    /// @return True/false depending on whether a given address is member or not
    function isMember(address _member) external view returns (bool);

    /// @return The count of members in the members set
    function membersCount() external view returns (uint256);

    /// @return The address of a member at a given index
    function memberAt(uint256 _index) external view returns (address);

    /// @return The current administrative nonce
    function administrativeNonce() external view returns (uint256);
}
