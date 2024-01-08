// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IGovernance {
    /// @notice An event emitted once members percentage is updated
    event MembersPercentageUpdated(uint256 percentage);

    /// @notice An event emitted once member is updated
    event MemberUpdated(address member, bool status);

    /// @notice An event emitted once a member's admin is updated
    event MemberAdminUpdated(address member, address admin);

    /// @notice An event emitted once the admin is updated
    event AdminUpdated(address indexed previousAdmin, address indexed newAdmin);

    /// @notice Initializes the Governance facet with an initial set of members
    /// @param _members The initial set of members
    /// @param _membersAdmins The initial set of member admins for each member
    /// Must be the same length
    /// @param _percentage The percentage of minimum amount of members signatures required
    /// @param _precision The precision used to calculate the minimum amount of members signatures required
    function initGovernance(
        address[] memory _members,
        address[] memory _membersAdmins,
        uint256 _percentage,
        uint256 _precision
    ) external;

    /// @return The current admin
    function admin() external view returns (address);

    /// @return The current percentage for minimum amount of members signatures
    function membersPercentage() external view returns (uint256);

    /// @return The current precision for minimum amount of members signatures
    function membersPrecision() external view returns (uint256);

    /// @notice Updates the admin address
    /// @param _newAdmin The address of the new admin
    function updateAdmin(address _newAdmin) external;

    /// @notice Updates the percentage of minimum amount of members signatures required
    /// @param _percentage The new percentage
    function updateMembersPercentage(uint256 _percentage) external;

    /// @notice Adds/removes a member account
    /// @param _account The account to be modified
    /// @param _accountAdmin The admin of the account.
    /// Ignored if member account is removed
    /// @param _status Whether the account will be set as member or not
    function updateMember(
        address _account,
        address _accountAdmin,
        bool _status
    ) external;

    /// @notice Updates the member admin
    /// @param _member The target member
    /// @param _newMemberAdmin The new member admin
    function updateMemberAdmin(address _member, address _newMemberAdmin)
        external;

    /// @return True/false depending on whether a given address is member or not
    function isMember(address _member) external view returns (bool);

    /// @return The count of members in the members set
    function membersCount() external view returns (uint256);

    /// @return The address of a member at a given index
    function memberAt(uint256 _index) external view returns (address);

    /// @return The member admin
    function memberAdmin(address _member) external view returns (address);

    /// @return Checks if the provided signatures are enough for submission
    function hasValidSignaturesLength(uint256 _n) external view returns (bool);
}
