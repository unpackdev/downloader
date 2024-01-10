// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./SafeERC20.sol";

import "./IGovernanceV2.sol";
import "./LibDiamond.sol";
import "./LibFeeCalculator.sol";
import "./LibGovernance.sol";
import "./LibPayment.sol";
import "./LibRouter.sol";

contract GovernanceV2Facet is IGovernanceV2 {
    using SafeERC20 for IERC20;

    /// @notice Adds/removes a member account
    /// @dev Replaces existing {GovernanceFacet-updateMember} function.
    /// Given that {GovernanceFacet-updateMember} has the same function selector,
    /// only one of the two functions can exist within the Diamond standard implementation.
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

            for (uint256 i = 0; i < LibPayment.tokensCount(); i++) {
                LibFeeCalculator.addNewMember(_account, LibPayment.tokenAt(i));
            }
        } else {
            address accountAdmin = LibGovernance.memberAdmin(_account);

            for (uint256 i = 0; i < LibRouter.nativeTokensCount(); i++) {
                address token = LibRouter.nativeTokenAt(i);
                uint256 claimableFees = LibFeeCalculator.claimReward(
                    _account,
                    token
                );
                IERC20(token).safeTransfer(accountAdmin, claimableFees);
            }

            for (uint256 i = 0; i < LibPayment.tokensCount(); i++) {
                address token = LibPayment.tokenAt(i);
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
}
