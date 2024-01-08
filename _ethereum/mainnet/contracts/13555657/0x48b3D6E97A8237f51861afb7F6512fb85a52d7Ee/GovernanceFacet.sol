// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./SafeERC20.sol";
import "./IGovernance.sol";
import "./LibDiamond.sol";
import "./LibGovernance.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";

contract GovernanceFacet is IGovernance {
    using SafeERC20 for IERC20;

    function initGovernance(
        address[] memory _members,
        address[] memory _membersAdmins,
        uint256 _percentage,
        uint256 _precision
    ) external override {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        require(!gs.initialized, "GovernanceFacet: already initialized");
        require(
            _members.length > 0,
            "GovernanceFacet: Member list must contain at least 1 element"
        );
        require(
            _members.length == _membersAdmins.length,
            "GovernanceFacet: not matching members length"
        );
        require(_precision != 0, "GovernanceFacet: precision must not be zero");
        require(
            _percentage < _precision,
            "GovernanceFacet: percentage must be less than precision"
        );
        gs.percentage = _percentage;
        gs.precision = _precision;
        gs.initialized = true;

        for (uint256 i = 0; i < _members.length; i++) {
            LibGovernance.updateMember(_members[i], true);
            LibGovernance.updateMemberAdmin(_members[i], _membersAdmins[i]);
            emit MemberUpdated(_members[i], true);
            emit MemberAdminUpdated(_members[i], _membersAdmins[i]);
        }
    }

    /// @return The current admin
    function admin() external view override returns (address) {
        return LibGovernance.admin();
    }

    /// @return The current percentage for minimum amount of members signatures
    function membersPercentage() external view override returns (uint256) {
        return LibGovernance.percentage();
    }

    /// @return The current precision for minimum amount of members signatures
    function membersPrecision() external view override returns (uint256) {
        return LibGovernance.precision();
    }

    /// @notice Updates the admin address
    /// @param _newAdmin The address of the new admin
    function updateAdmin(address _newAdmin) external override {
        LibDiamond.enforceIsContractOwner();
        address previousAdmin = LibGovernance.admin();
        LibGovernance.updateAdmin(_newAdmin);

        emit AdminUpdated(previousAdmin, _newAdmin);
    }

    /// @notice Updates the percentage of minimum amount of members signatures required
    /// @param _percentage The new percentage
    function updateMembersPercentage(uint256 _percentage) external override {
        LibDiamond.enforceIsContractOwner();
        LibGovernance.updateMembersPercentage(_percentage);

        emit MembersPercentageUpdated(_percentage);
    }

    /// @notice Adds/removes a member account
    /// @param _account The account to be modified
    /// @param _accountAdmin The admin of the account.
    /// Ignored if member account is removed
    /// @param _status Whether the account will be set as member or not
    function updateMember(
        address _account,
        address _accountAdmin,
        bool _status
    ) external override {
        LibDiamond.enforceIsContractOwner();

        if (_status) {
            for (uint256 i = 0; i < LibRouter.nativeTokensCount(); i++) {
                LibFeeCalculator.addNewMember(
                    _account,
                    LibRouter.nativeTokenAt(i)
                );
            }
        } else {
            for (uint256 i = 0; i < LibRouter.nativeTokensCount(); i++) {
                address accountAdmin = LibGovernance.memberAdmin(_account);
                address token = LibRouter.nativeTokenAt(i);
                uint256 claimableFees = LibFeeCalculator.claimReward(
                    _account,
                    token
                );
                IERC20(token).safeTransfer(accountAdmin, claimableFees);
            }
            _accountAdmin = address(0);
        }

        LibGovernance.updateMember(_account, _status);
        emit MemberUpdated(_account, _status);

        LibGovernance.updateMemberAdmin(_account, _accountAdmin);
        emit MemberAdminUpdated(_account, _accountAdmin);
    }

    /// @notice Updates the member admin
    /// @param _member The target member
    /// @param _newMemberAdmin The new member admin
    function updateMemberAdmin(address _member, address _newMemberAdmin)
        external
        override
    {
        require(
            LibGovernance.isMember(_member),
            "GovernanceFacet: _member is not an actual member"
        );
        require(
            msg.sender == LibGovernance.memberAdmin(_member),
            "GovernanceFacet: caller is not the old admin"
        );

        LibGovernance.updateMemberAdmin(_member, _newMemberAdmin);
        emit MemberAdminUpdated(_member, _newMemberAdmin);
    }

    /// @return True/false depending on whether a given address is member or not
    function isMember(address _member) external view override returns (bool) {
        return LibGovernance.isMember(_member);
    }

    /// @return The count of members in the members set
    function membersCount() external view override returns (uint256) {
        return LibGovernance.membersCount();
    }

    /// @return The address of a member at a given index
    function memberAt(uint256 _index) external view override returns (address) {
        return LibGovernance.memberAt(_index);
    }

    /// @return The member admin
    function memberAdmin(address _member)
        external
        view
        override
        returns (address)
    {
        return LibGovernance.memberAdmin(_member);
    }

    /// @return Checks if the provided signatures are enough for submission
    function hasValidSignaturesLength(uint256 _n)
        external
        view
        override
        returns (bool)
    {
        return LibGovernance.hasValidSignaturesLength(_n);
    }
}
