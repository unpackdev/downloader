//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./SafeERC20.sol";
import "./Counters.sol";
import "./IGovernance.sol";
import "./LibGovernance.sol";
import "./LibFeeCalculator.sol";
import "./LibRouter.sol";

contract GovernanceFacet is IGovernance {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    function initGovernance(address[] memory _members) external override {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        require(!gs.initialized, "Governance: already initialized");
        require(_members.length > 0, "Governance: Member list must contain at least 1 element");
        gs.initialized = true;

        for(uint256 i = 0; i < _members.length; i++) {
            LibGovernance.updateMember(_members[i], true);
            emit MemberUpdated(_members[i], true);
        }
    }

    /**
     *  @notice Adds/removes a member account
     *  @param _account The account to be modified
     *  @param _status Whether the account will be set as member or not
     *  @param _signatures The signatures of the validators authorizing this member update
     */
    function updateMember(address _account, bool _status, bytes[] calldata _signatures)
        onlyValidSignatures(_signatures.length)
        external override
    {
        bytes32 ethHash = LibGovernance.computeMemberUpdateMessage(_account, _status);
        LibGovernance.validateSignatures(ethHash, _signatures);

        if (_status) {
            LibFeeCalculator.addNewMember(_account);
        } else {
            LibRouter.Storage storage rs = LibRouter.routerStorage();
            uint256 claimableFees = LibFeeCalculator.claimReward(_account);
            IERC20(rs.albtToken).safeTransfer(_account, claimableFees);
        }

        LibGovernance.updateMember(_account, _status);
        emit MemberUpdated(_account, _status);
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

    /// @return The current administrative nonce
    function administrativeNonce() external view override returns (uint256) {
        LibGovernance.Storage storage gs = LibGovernance.governanceStorage();
        return gs.administrativeNonce.current();
    }

    /// @notice Accepts number of signatures in the range (n/2; n] where n is the number of members
    modifier onlyValidSignatures(uint256 _n) {
        uint256 members = LibGovernance.membersCount();
        require(_n <= members, "Governance: Invalid number of signatures");
        require(_n > members / 2, "Governance: Invalid number of signatures");
        _;
    }
}