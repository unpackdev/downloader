pragma solidity 0.8.6;

import "./IERC20.sol";
import "./Ownable.sol";

import "./StakingRewards.sol";

contract StakingRewardsFactory is Ownable {
    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint256 varenRewardAmount;
        address extraRewardToken;
        uint256 extraRewardTokenAmount;
    }

    // immutables
    address public varenToken;
    uint256 public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(address _varenToken, uint256 _stakingRewardsGenesis) Ownable() {
        require(_varenToken != address(0), "varenToken=0x0");
        require(_stakingRewardsGenesis >= block.timestamp, "genesis<timestamp");
        varenToken = _varenToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(
        address _stakingToken,
        uint256 _varenRewardAmount,
        address _extraRewardToken, // optional
        uint256 _extraRewardTokenAmount,
        uint256 _rewardsDuration
    ) external onlyOwner {
        require(_stakingToken != address(0), "stakingToken=0x0");
        require(_stakingToken != varenToken, "stakingToken=varenToken");
        require(_stakingToken != _extraRewardToken, "stakingToken=extraRewardToken");
        require(_extraRewardToken != varenToken, "extraRewardToken=varenToken");
        require(_varenRewardAmount > 0 || _extraRewardTokenAmount > 0, "amounts=0");
        if (_extraRewardToken == address(0)) {
            require(_extraRewardTokenAmount == 0, "extraRewardTokenAmount!=0");
        } else {
            require(_extraRewardTokenAmount > 0, "extraRewardTokenAmount=0");
        }
        require(_rewardsDuration > 0, "rewardsDuration=0");
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_stakingToken];
        require(info.stakingRewards == address(0), "already deployed");

        info.stakingRewards = address(
            new StakingRewards(
                _stakingToken,
                address(this), // rewardsDistributor
                varenToken,
                _extraRewardToken,
                _rewardsDuration,
                owner()
            )
        );
        info.varenRewardAmount = _varenRewardAmount;
        info.extraRewardToken = _extraRewardToken;
        info.extraRewardTokenAmount = _extraRewardTokenAmount;
        stakingTokens.push(_stakingToken);
    }

    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() external {
        require(stakingTokens.length > 0, "no deploys yet");
        for (uint256 i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address _stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, "timestamp<genesis");

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[_stakingToken];
        require(info.stakingRewards != address(0), "not deployed");

        uint256 rewardAmount = info.varenRewardAmount;
        uint256 extraRewardAmount = info.extraRewardTokenAmount;
        if (rewardAmount == 0 && extraRewardAmount == 0) return;

        if (rewardAmount > 0) {
            info.varenRewardAmount = 0;
            require(
                IERC20(varenToken).transfer(info.stakingRewards, rewardAmount),
                "transfer failed"
            );
        }
        if (extraRewardAmount > 0) {
            info.extraRewardTokenAmount = 0;
            require(
                IERC20(info.extraRewardToken).transfer(info.stakingRewards, extraRewardAmount),
                "transfer failed"
            );
        }
        StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount, extraRewardAmount);
    }
}