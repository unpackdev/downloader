// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IERC20.sol";

import "./IFarm.sol";
import "./IFarmDistributor.sol";

// Adapted from https://github.com/trusttoken/smart-contracts/blob/master/contracts/truefi/TrueFarm.sol
contract Farm is IFarm {
    using SafeMath for uint256;
    uint256 constant PRECISION = 1e30;

    string public name;
    IERC20 public override stakingToken;
    IERC20 public override rewardToken;
    IFarmDistributor public farmDistributor;

    // track stakes
    uint256 public override totalStaked;
    mapping(address => uint256) public staked;

    // track overall cumulative rewards
    uint256 public cumulativeRewardPerToken;
    // track previous cumulate rewards for accounts
    mapping(address => uint256) public previousCumulatedRewardPerToken;
    // track claimable rewards for accounts
    mapping(address => uint256) public claimableReward;

    // track total rewards
    uint256 public totalClaimedRewards;
    uint256 public totalFarmRewards;

    address public gov;

    /**
     * @dev Emitted when an account stakes
     * @param who Account staking
     * @param amountStaked Amount of tokens staked
     */
    event Stake(address indexed who, uint256 amountStaked);

    /**
     * @dev Emitted when an account unstakes
     * @param who Account unstaking
     * @param amountUnstaked Amount of tokens unstaked
     */
    event Unstake(address indexed who, uint256 amountUnstaked);

    /**
     * @dev Emitted when an account claims rewards
     * @param who Account claiming
     * @param amountClaimed Amount of claimed
     */
    event Claim(address indexed who, uint256 amountClaimed);

    event GovChange(address gov);
    event DistributorChange(address distributor);

    modifier onlyGov() {
        require(msg.sender == gov, "Farm: forbidden");
        _;
    }

    constructor(string memory _name, IERC20 _stakingToken, IERC20 _rewardToken) public {
        name = _name;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        gov = msg.sender;
    }

    function setGov(address _gov) public onlyGov {
        gov = _gov;
        emit GovChange(_gov);
    }

    function setFarmDistributor(IFarmDistributor _farmDistributor) public onlyGov {
        farmDistributor = _farmDistributor;
        emit DistributorChange(address(_farmDistributor));
    }

    /**
     * @dev Stake tokens for rewards.
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) external override update {
        staked[msg.sender] = staked[msg.sender].add(amount);
        totalStaked = totalStaked.add(amount);
        require(stakingToken.transferFrom(msg.sender, address(this), amount));
        emit Stake(msg.sender, amount);
    }

    /**
     * @dev Internal unstake function
     * @param amount Amount of tokens to unstake
     */
    function _unstake(address receiver, uint256 amount) internal {
        require(amount <= staked[msg.sender], "Farm: Cannot withdraw amount bigger than available balance");
        staked[msg.sender] = staked[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        stakingToken.transfer(receiver, amount);
        emit Unstake(receiver, amount);
    }

    /**
     * @dev Internal claim function
     */
    function _claim(address receiver) internal {
        totalClaimedRewards = totalClaimedRewards.add(claimableReward[msg.sender]);
        uint256 rewardToClaim = claimableReward[msg.sender];
        claimableReward[msg.sender] = 0;

        rewardToken.transfer(receiver, rewardToClaim);
        emit Claim(receiver, rewardToClaim);
    }

    /**
     * @dev Remove staked tokens
     * @param amount Amount of tokens to unstake
     */
    function unstake(address receiver, uint256 amount) external override update {
        _unstake(receiver, amount);
    }

    /**
     * @dev Claim rewards
     */
    function claim(address receiver) external override update {
        _claim(receiver);
    }

    /**
     * @dev Unstake amount and claim rewards
     * @param amount Amount of tokens to unstake
     */
    function exit(address receiver, uint256 amount) external override update {
        _unstake(receiver, amount);
        _claim(receiver);
    }

    /**
     * @dev Update state and get rewards from distributor
     */
    modifier update() {
        // pull from distributor
        if (address(farmDistributor) != address(0)) {
            farmDistributor.distribute(address(this));
        }
        // calculate total rewards
        uint256 newTotalFarmRewards = rewardToken.balanceOf(address(this)).add(totalClaimedRewards).mul(PRECISION);
        // calculate block reward
        uint256 totalBlockReward = newTotalFarmRewards.sub(totalFarmRewards);
        // update farm rewards
        totalFarmRewards = newTotalFarmRewards;
        // if there are stakers
        if (totalStaked > 0) {
            cumulativeRewardPerToken = cumulativeRewardPerToken.add(totalBlockReward.div(totalStaked));
        }
        // update claimable reward for sender
        claimableReward[msg.sender] = claimableReward[msg.sender].add(
            staked[msg.sender].mul(cumulativeRewardPerToken.sub(previousCumulatedRewardPerToken[msg.sender])).div(PRECISION)
        );
        // update previous cumulative for sender
        previousCumulatedRewardPerToken[msg.sender] = cumulativeRewardPerToken;
        _;
    }
}
