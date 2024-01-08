// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuard.sol";
import "./OwnableUpgradeable.sol";

import "./IUniswapV2Pair.sol";

import "./IContractsRegistry.sol";
import "./IBrightStaking.sol";
import "./ILiquidityMiningStaking.sol";
import "./IERC20Permit.sol";

import "./Globals.sol";
import "./AbstractCooldownStaking.sol";

contract LiquidityMiningStaking is
    ILiquidityMiningStaking,
    AbstractCooldownStaking,
    OwnableUpgradeable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public rewardsToken;
    address public stakingToken;
    IBrightStaking public brightStaking;

    uint256 public rewardPerBlock;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) internal _rewards;

    uint256 public totalStaked;
    mapping(address => uint256) public staked;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardRestaked(address indexed user, uint256 reward);
    event RewardTokensRecovered(uint256 amount);

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function __LiquidityMiningStaking_init(uint256 _rewardPerBlock, IContractsRegistry _contractsRegistry) external initializer {
        __Ownable_init();
        rewardPerBlock = _rewardPerBlock;
        rewardsToken = IERC20(_contractsRegistry.getBrightContract());
        brightStaking = IBrightStaking(_contractsRegistry.getBrightStakingContract());
        stakingToken = _contractsRegistry.getUniswapBrightToETHPairContract();
    }

    function stake(uint256 _amount) external override nonReentrant updateReward(_msgSender()) {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_msgSender(), _amount);
    }

    function stakeFor(address _user, uint256 _amount) external override {
        require(_amount > 0, "LMS: Amount should be greater than 0");

        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_user, _amount);
    }

    function stakeWithPermit(uint256 _stakingAmount, uint8 _v, bytes32 _r, bytes32 _s) external override nonReentrant updateReward(_msgSender()){
        IERC20Permit(address(stakingToken)).permit(
            _msgSender(),
            address(this),
            _stakingAmount,
            MAX_INT,
            _v,
            _r,
            _s
        );

        IERC20(stakingToken).safeTransferFrom(_msgSender(), address(this), _stakingAmount);
        _stake(_msgSender(), _stakingAmount);
    }

    function _stake(address _user, uint256 _amount) internal {
        totalStaked = totalStaked.add(_amount);
        staked[_user] = staked[_user].add(_amount);

        emit Staked(_user, _amount);
    }

    function withdraw(uint256 _amount) public override nonReentrant updateReward(_msgSender()) {
        require(_amount > 0, "LMS: Amount should be greater than 0");
        uint256 userStaked = staked[_msgSender()];
        require(userStaked >= _amount, "LMS: Insufficient staked amount");

        totalStaked = totalStaked.sub(_amount);
        staked[_msgSender()] = userStaked.sub(_amount);
        IERC20(stakingToken).safeTransfer(_msgSender(), _amount);

        emit Withdrawn(_msgSender(), _amount);
    }


    /**
	 * @dev Available after cooldown on callGetReward()
	 */
    function exit() external override {
        withdraw(staked[_msgSender()]);
        getReward();
    }

    /**
	 * @dev Available without cooldown
	 */
    function restake() external override nonReentrant updateReward(_msgSender()) {
        uint256 _reward = _rewards[_msgSender()];

        if (_reward > 0) {
            delete _rewards[_msgSender()];
            rewardsToken.approve(address(brightStaking), _reward);
            brightStaking.stakeFor(_msgSender(), _reward);
            emit RewardRestaked(_msgSender(), _reward);
        }
    }

    /**
     * @dev Caller asks for rewards, which still will keep growing over the cooldown period
     */
    function callGetReward() external override nonReentrant updateReward(_msgSender()){
        require(_rewards[_msgSender()] > 0, "LMS: No rewards at stake");

        withdrawalsInfo[_msgSender()] = WithdrawalInfo(
            block.timestamp.add(WITHDRAWING_COOLDOWN_DURATION),
            0                                                   //not used
        );
    }

    function getReward() public override nonReentrant updateReward(_msgSender()) {
        uint256 _whenCanWithdrawBrightReward = whenCanWithdrawBrightReward(_msgSender());
        require(_whenCanWithdrawBrightReward != 0, "LMS: unlock not started/exp");
        require(_whenCanWithdrawBrightReward <= block.timestamp, "LMS: cooldown not reached");

        delete withdrawalsInfo[_msgSender()];

        uint256 _reward = _rewards[_msgSender()];

        if (_reward > 0) {
            delete _rewards[_msgSender()];
            rewardsToken.safeTransfer(_msgSender(), _reward);
            emit RewardPaid(_msgSender(), _reward);
        }
    }

    function setRewards(
        uint256 _rewardPerBlock
    ) external onlyOwner updateReward(address(0)) {
        rewardPerBlock = _rewardPerBlock;
    }

    function _updateReward(address account) internal {
        uint256 currentRewardPerToken = rewardPerToken();

        rewardPerTokenStored = currentRewardPerToken;
        lastUpdateBlock = block.number;

        if (account != address(0)) {
            _rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = currentRewardPerToken;
        }
    }

    function recoverRewards() external onlyOwner {
        uint256 _remaining = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransfer(owner(), _remaining);
        emit RewardTokensRecovered(_remaining);
    }

    /// @dev returns APY with 10**5 precision
    function getAPY() external view override returns (uint256) {
        uint256 totalSupply = IUniswapV2Pair(stakingToken).totalSupply();
        (uint256 reserveBright, , ) = IUniswapV2Pair(stakingToken).getReserves();

        if (totalSupply == 0 || reserveBright == 0) {
            return 0;
        }

        return rewardPerBlock.mul(BLOCKS_PER_YEAR).mul(PERCENTAGE_100).div(
            totalStaked.add(APY_TOKENS).mul(reserveBright.mul(2).mul(10**20).div(totalSupply))
        );
    }

    function rewardPerToken() public view override returns (uint256) {
        uint256 totalPoolStaked = totalStaked;

        if (totalPoolStaked == 0) {
            return rewardPerTokenStored;
        }
        uint256 _blocksPassed = lastUpdateBlock == 0 ? 0 : block.number.sub(lastUpdateBlock);
        uint256 accumulatedReward = _blocksPassed.mul(rewardPerBlock).mul(DECIMALS18).div(totalPoolStaked);

        return rewardPerTokenStored.add(accumulatedReward);
    }

    function earned(address _account) public view override returns (uint256) {
        uint256 rewardsDifference = rewardPerToken().sub(userRewardPerTokenPaid[_account]);
        uint256 newlyAccumulated = staked[_account].mul(rewardsDifference).div(DECIMALS18);

        return _rewards[_account].add(newlyAccumulated);
    }

}
