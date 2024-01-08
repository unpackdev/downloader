// SPDX-License-Identifier: None
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IRewardDistributionRecipient.sol";
import "./TokenToVotePowerStaking.sol";

/// @title Fees functionality for the voting power.
/// @notice Fees are paid to this contracts in the erc20 token.
/// This contract distributes fees between voting power holders.
/// @dev Fees value is claimable.
contract VotingPowerFees is TokenToVotePowerStaking, ReentrancyGuard {
    /// @dev Token in which fees are paid.
    IERC20 internal feesToken;

    /// @dev Accumulated ratio of the voting power to the fees. This is used to calculate
    uint256 internal accumulatedRatio = 0;

    /// @dev Fees savings amount fixed by the contract after the last claim.
    uint256 internal lastBal = 0;

    /// @notice User => accumulated ratio fixed after the last user's claim
    mapping(address => uint256) public userAccumulatedRatio;

    /// @notice Token in which fees are paid.
    function getFeesToken() external view returns (IERC20 _feesToken) {
        return feesToken;
    }

    /// @notice Accumulated ratio of the voting power to the fees. This is used to calculate
    function getAccumulatedRatio() external view returns (uint256 _accumulatedRatio) {
        return accumulatedRatio;
    }

    /// @notice Fees savings amount fixed by the contract after the last claim.
    function getLastBal() external view returns (uint256 _lastBal) {
        return lastBal;
    }

    /// @notice User => accumulated ratio fixed after the last user's claim
    function getUserAccumulatedRatio(address _user) external view returns (uint256 _userAccumulatedRatio) {
        return userAccumulatedRatio[_user];
    }

    /// @notice Contract's constructor
    /// @param _stakingToken Sets staking token
    /// @param _feesToken Sets fees token
    constructor(IERC20 _stakingToken, IERC20 _feesToken) public TokenToVotePowerStaking(_stakingToken) {
        feesToken = _feesToken;
    }

    /// @notice Makes contract update its fee (token) balance
    /// @dev Updates accumulatedRatio and lastBal
    function updateFees() public {
        if (totalSupply() > 0) {
            uint256 _lastBal = IERC20(feesToken).balanceOf(address(this));
            if (_lastBal > 0) {
                uint256 _diff = _lastBal.sub(lastBal);
                if (_diff > 0) {
                    uint256 _ratio = _diff.mul(1e18).div(totalSupply());
                    if (_ratio > 0) {
                        accumulatedRatio = accumulatedRatio.add(_ratio);
                        lastBal = _lastBal;
                    }
                }
            }
        }
    }

    /// @notice Transfers fees part (token amount) to the user accordingly to the user's voting power share
    function withdrawFees() external {
        _withdrawFeesFor(msg.sender);
    }

    /// @dev bug WIP: Looks like it won't work properly if all of the users
    /// will claim their rewards (balance will be 0) and then new user will receive
    /// voting power and try to claim (revert). Or new user will claim reward after
    /// @param recipient User who will receive its fee part.
    function _withdrawFeesFor(address recipient) nonReentrant internal {
        updateFees();
        uint256 _supplied = balanceOf(recipient);
        if (_supplied > 0) {
            uint256 _supplyIndex = userAccumulatedRatio[recipient];
            userAccumulatedRatio[recipient] = accumulatedRatio;
            uint256 _delta = accumulatedRatio.sub(_supplyIndex);
            if (_delta > 0) {
                uint256 _share = _supplied.mul(_delta).div(1e18);

                IERC20(feesToken).safeTransfer(recipient, _share);
                lastBal = IERC20(feesToken).balanceOf(address(this));
            }
        } else {
            userAccumulatedRatio[recipient] = accumulatedRatio;
        }
    }
}
