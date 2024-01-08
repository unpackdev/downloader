// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./IStakingRewards.sol";
import "./IOrionVoting.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";

contract OrionStakingReward is IStakingRewards, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ///////////////////////////////////////////////////
    //  Data fields
    //  NB: Only add new fields BELOW any fields in this section

    IERC20 public stakingToken;
    IOrionVoting public voting_contract_;

    uint256 public rewardPerTokenStored;
    uint256 public voting_pool_accumulator_stored_;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) public _balances;

    //  Add new data fields there....
    //      ...

    //  End of data fields
    /////////////////////////////////////////////////////

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _stakingToken,
        address voting_contract_address
    ) public initializer {
        OwnableUpgradeable.__Ownable_init();
        stakingToken = IERC20(_stakingToken);
        voting_contract_ = IOrionVoting(voting_contract_address);
    }

    /* ========== VIEWS ========== */

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    //  Actually it's thr reward per token
    //  i.e it's already have "time function" inside (grows with a time, if lastUpdateTime
    //  isn;'t changed
    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        //  Get value from voting contract
        //
        uint256 new_voting_pool_acc = voting_contract_.getPoolRewards(address(this));

        //  Substract the saved value
        uint256 pool_rewards = new_voting_pool_acc.sub(voting_pool_accumulator_stored_);

        return
            rewardPerTokenStored.add(
                pool_rewards.div(_totalSupply)
            );
    }

    function earned(address account) override public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) override external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function _stake(uint256 amount, address to) internal {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[to] = _balances[to].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(to, amount);
    }

    function stake(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        _stake(amount, msg.sender);
    }

    function stakeTo(uint256 amount, address to) virtual override public nonReentrant updateReward(to) {
        _stake(amount, to);
    }

    function withdraw(uint256 amount) virtual override public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() virtual override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            voting_contract_.claimRewards(uint56(reward), msg.sender);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() virtual override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function emergencyAssetWithdrawal(address asset) external onlyOwner {
      IERC20 token = IERC20(asset);
      token.safeTransfer(OwnableUpgradeable.owner(), token.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        emit TestRewardPerToken(rewardPerToken());
        rewardPerTokenStored = rewardPerToken();
        //  ???
        voting_pool_accumulator_stored_ = voting_contract_.getPoolRewards(address(this));

        if (account != address(0)) {
            //  All of earned
            //  return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
            emit TestEarnedCalc(
                _balances[account],
                rewardPerToken(),
                userRewardPerTokenPaid[account],
                rewards[account],
                voting_contract_.getPoolRewards(address(this))
            );

            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;

            emit TestUpdateRewardUser(rewards[account], userRewardPerTokenPaid[account]);
        }

        emit TestUpdateReward(rewardPerTokenStored, voting_pool_accumulator_stored_);
        _;
    }

    /* ========== EVENTS ========== */
    //  TEst event
    event TestUpdateReward(
        uint256 _rewardPerTokenStored,
        uint256 _voting_pool_accumulator_stored
    );

    event TestRewardPerToken(
        uint256 _rewardPerToken
    );


    event TestEarnedCalc
    (
        uint256 balances_account,
        uint256 rewardPerToken,
        uint256 userRewardPerTokenPaid_account,
        uint256 rewards_account,
        uint256 voting_contract_getPoolRewards
    );

    event TestUpdateRewardUser
    (
        uint256 rewards,
        uint256 userRewardPerTokenPaid
    );

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

