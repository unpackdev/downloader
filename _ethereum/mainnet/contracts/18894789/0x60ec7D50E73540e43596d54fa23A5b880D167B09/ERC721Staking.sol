// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./Ownable.sol";

/// @author Andrei Toma
/// @title ERC721 NFT Staking Contract
/// @notice Staking Contract that uses the Synthetix Staking model to distribute ERC20 token rewards in a dynamic way,
/// proportionally based on the amount of ERC721 tokens staked by each staker at any given time.

contract ERC721Staking is ERC721Holder, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    IERC721 public immutable nftCollection;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 private rewardPerTokenStored;
    uint256 public totalStakedSupply;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) private rewards;
    mapping(uint256 => address) public stakedAssets;
    mapping(address => uint256[]) private tokensStaked;
    mapping(uint256 => uint256) public tokenIdToIndex;

    /// @param _nftCollection the address of the ERC721 Contract
    /// @param _rewardToken the address of the ERC20 token used for rewards
    constructor(IERC721 _nftCollection, IERC20 _rewardToken) {
        nftCollection = _nftCollection;
        rewardToken = _rewardToken;
    }

    /// @notice functon called by the users to Stake NFTs
    /// @param tokenIds array of Token IDs of the NFTs to be staked
    /// @dev the Token IDs have to be prevoiusly approved for transfer in the
    /// ERC721 contract with the address of this contract
    function stake(uint256[] calldata tokenIds) external updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount = tokenIds.length;
        for (uint256 i; i < amount;) {
            nftCollection.safeTransferFrom(msg.sender, address(this), tokenIds[i]);

            stakedAssets[tokenIds[i]] = msg.sender;
            tokensStaked[msg.sender].push(tokenIds[i]);
            tokenIdToIndex[tokenIds[i]] = tokensStaked[msg.sender].length - 1;
            unchecked {
                i++;
            }
        }
        totalStakedSupply += amount;

        emit Staked(msg.sender, tokenIds);
    }

    /// @notice function called by the user to Withdraw NFTs from staking
    /// @param tokenIds array of Token IDs of the NFTs to be withdrawn
    function withdraw(uint256[] memory tokenIds) public updateReward(msg.sender) {
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        uint256 amount = tokenIds.length;
        for (uint256 i; i < amount;) {
            require(stakedAssets[tokenIds[i]] == msg.sender, "Staking: Not the staker of the token");

            delete stakedAssets[tokenIds[i]];

            uint256[] storage userTokens = tokensStaked[msg.sender];

            uint256 index = tokenIdToIndex[tokenIds[i]];
            uint256 lastTokenIdIndex = userTokens.length - 1;
            if (index != lastTokenIdIndex) {
                uint256 lastTokenId = userTokens[lastTokenIdIndex];
                userTokens[index] = lastTokenId;
                tokenIdToIndex[lastTokenId] = index;
            }
            userTokens.pop();

            nftCollection.safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }
        totalStakedSupply -= amount;

        emit Withdrawn(msg.sender, tokenIds);
    }

    /// @notice function called by the user to claim his accumulated rewards
    function claimRewards() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            delete rewards[msg.sender];

            rewardToken.safeTransfer(msg.sender, reward);

            emit RewardPaid(msg.sender, reward);
        }
    }

    /// @notice function called by the user to withdraw all NFTs and claim the rewards in one transaction
    function withdrawAll() external {
        withdraw(tokensStaked[msg.sender]);
        claimRewards();
    }

    /// @notice function useful for Front End to see the stake and rewards for users
    /// @param _user the address of the user to get informations for
    /// @return _tokensStaked an array of NFT Token IDs that are staked by the user
    /// @return _availableRewards the rewards accumulated by the user
    function userStakeInfo(address _user)
        public
        view
        returns (uint256[] memory _tokensStaked, uint256 _availableRewards)
    {
        _tokensStaked = tokensStaked[_user];
        _availableRewards = calculateRewards(_user);
    }

    /// @notice getter function to get the reward per second for staking one NFT
    /// @return _rewardPerToken the amount of token per second rewarded for staking one NFT
    function getRewardPerToken() external view returns (uint256 _rewardPerToken) {
        return rewardRate / totalStakedSupply;
    }

    /// @notice function for the Owner of the Contract to start a Staking period and set the
    /// amount of ERC20 Tokens to be distributed as rewards in said period
    /// @param _amount the amount of Reward Tokens to be distributed
    /// @param _duration the duration in with the rewards will be distributed, in seconds
    /// @dev  the Staking Contract have to already own enough Rewards Tokens to distribute all the rewards,
    /// so make sure to send all the tokens to the contract before calling this function
    function startStakingPeriod(uint256 _amount, uint256 _duration) external onlyOwner {
        require(_amount > 0, "Staking: Amount must be greater than 0");
        require(_duration > 0, "Staking: Duration must be greater than 0");
        require(
            block.timestamp > periodFinish,
            "Staking: Previous rewards period must be complete before changing the duration for the new period"
        );

        rewardsDuration = _duration;

        emit RewardsDurationUpdated(rewardsDuration);

        rewardRate = _amount / rewardsDuration;

        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "Staking: Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit RewardAdded(_amount);
    }

    /// @return _lastRewardsApplicable the last time the rewards were applicable,
    /// returns block.timestamp if the rewards period is not ended
    function lastTimeRewardApplicable() public view returns (uint256 _lastRewardsApplicable) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    /// @notice calculates the rewards per token for the current time whenever a new deposit/withdraw
    /// is made to keep track of the correct token distribution between stakers
    function rewardPerToken() public view returns (uint256) {
        if (totalStakedSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored
            + (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalStakedSupply);
    }

    /// @notice used to calculate the earned rewards for a user
    /// @param _user the address of the user to calculate available rewards for
    /// @return _rewards the amount of tokens available as rewards for the passed address
    function calculateRewards(address _user) public view returns (uint256 _rewards) {
        return
            ((tokensStaked[_user].length * (rewardPerToken() - userRewardPerTokenPaid[_user])) / 1e18) + rewards[_user];
    }

    /// @return _distributedTokens the total amount of ERC20 Tokens distributed as rewards for the set staking period
    function getRewardForDuration() external view returns (uint256 _distributedTokens) {
        return rewardRate * rewardsDuration;
    }

    /// @notice modifier used to keep track of the dynamic rewards for user each time a deposit or withdrawal is made
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = calculateRewards(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256[] tokenIds);
    event Withdrawn(address indexed user, uint256[] tokenIds);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
}
