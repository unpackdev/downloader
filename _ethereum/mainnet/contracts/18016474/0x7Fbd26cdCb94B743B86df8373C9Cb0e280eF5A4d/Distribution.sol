// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Owned.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./ERC20.sol";
import "./IPlatform.sol";

contract Distribution is Owned(msg.sender) {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /// @notice Token amount to claim for all users / tokens
    mapping(address => mapping(address => uint256)) public balances;

    /// @notice Treasury fee
    uint256 public fee = 4e16; // 4%

    /// @notice Claim multi struct.
    struct ClaimMulti {
        address[] users;
        uint256 bountyId;
    }

    event BatchClaimed(uint256 bountyId, address tokenReward, uint256 earned, uint256 treasuryRewardsFees);
    event Claimed(address user, address tokenReward, uint256 amount);
    event TreasuryClaimed(address tokenReward, uint256 amount);

    /// @notice Claim rewards for a batch users / bounty id.
    /// @param platform Contract where claim rewards
    /// @param claimMultis Struct array with user addresses / bounty id to claim
    function batchClaimForMulti(address platform, ClaimMulti[] calldata claimMultis) external onlyOwner {
        
        uint256 i = 0;
        uint256 length = claimMultis.length;

        for(; i < length;) {
            batchClaimFor(platform, claimMultis[i].users, claimMultis[i].bountyId);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim rewards for a batch users / bounty id.
    /// @param platform Contract where claim rewards
    /// @param users Users array to claim for
    /// @param bountyId Bounty id to claim for
    function batchClaimFor(address platform, address[] calldata users, uint256 bountyId) public onlyOwner {
        address tokenReward = IPlatform(platform).bounties(bountyId).rewardToken;
        
        uint256 i = 0;
        uint256 length = users.length;
        uint256 treasuryRewardsFees = 0;
        uint256 totalClaimableRewards = 0;

        for(; i < length;) {
            uint256 claimableRewards = IPlatform(platform).claimable(users[i], bountyId);
            totalClaimableRewards += claimableRewards;

            uint256 treasuryRewardsFee = claimableRewards.mulWadDown(fee);
            treasuryRewardsFees += treasuryRewardsFee;
            
            balances[users[i]][tokenReward] += (claimableRewards - treasuryRewardsFee);
            
            unchecked {
                ++i;
            }
        }

        IPlatform(platform).batchClaimFor(users, bountyId);
        balances[owner][tokenReward] += treasuryRewardsFees;

        emit BatchClaimed(bountyId, tokenReward, totalClaimableRewards, treasuryRewardsFees);
    }

    /// @notice Treasury fee take on all rewards amount claimed
    /// @param _fee New fee to set
    function setFee(uint256 _fee) external onlyOwner {
        require(_fee < 20e16, "Too high"); // Max 20%
        fee = _fee;
    }

    /// @notice Claim treasury fee per token
    function claimTreasuryFee(address token) external onlyOwner {
        uint256 treasuryFeeClaimable = balances[owner][token];
        balances[owner][token] = 0;

        ERC20(token).safeTransfer(owner, treasuryFeeClaimable);
        emit TreasuryClaimed(token, treasuryFeeClaimable);
    }

    /// @notice Claim rewards for a given token
    /// @param token Token address to claim
    function claim(address token) external {
        _claim(msg.sender, token);
    }

    /// @notice Claim rewards for several tokens
    /// @param tokens Token addresses to claim
    function claimMulti(address[] calldata tokens) external {
        uint256 length = tokens.length;
        uint256 i = 0;

        for(; i < length;) {
            _claim(msg.sender, tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Claim rewards for a given token and for another user
    /// @param user User address to claim for
    /// @param token Token address to claim
    function claimFor(address user, address token) external {
        _claim(user, token);
    }

    /// @notice Claim rewards for several tokens and for another user
    /// @param user User address to claim for
    /// @param tokens Token addresses to claim
    function claimMultiFor(address user, address[] calldata tokens) external {
        uint256 length = tokens.length;
        uint256 i = 0;

        for(; i < length;) {
            _claim(user, tokens[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Internal claim function to claim rewards 
    /// @param user User address to claim for
    /// @param token Token address to claim
    function _claim(address user, address token) internal {
        uint256 c = claimable(user, token);
        balances[user][token] = 0;

        ERC20(token).safeTransfer(user, c);
        emit Claimed(user, token, c);
    }

    /// @notice Returns token amount to claim
    /// @param user User address to claim
    /// @param token Token address to claim
    function claimable(address user, address token) public view returns(uint256) {
        return balances[user][token];
    }
}
