// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./Math.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./ConvexInterfacesV2.sol";
import "./IVirtualBalanceWrapper.sol";

contract ConvexRewardPoolV2 is ReentrancyGuard, IConvexRewardPoolV2 {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public override rewardToken;
    uint256 public constant duration = 7 days;

    address public owner;
    address public depositer;
    address public virtualBalance;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    address[] public override extraRewards;

    mapping(address => uint256) public override userRewardPerTokenPaid;
    mapping(address => uint256) public override rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user);
    event Withdrawn(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(
        address _rewardToken,
        address _virtualBalance,
        address _depositer,
        address _owner
    ) public {
        rewardToken = _rewardToken;
        virtualBalance = _virtualBalance;
        depositer = _depositer;
        owner = _owner;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    function extraRewardsLength() external view override returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external override returns (bool) {
        require(msg.sender == owner, "ConvexRewardPool: !authorized addExtraReward");
        require(_reward != address(0), "!reward setting");

        extraRewards.push(_reward);
        return true;
    }

    function clearExtraRewards() external override {
        require(msg.sender == owner, "ConvexRewardPool: !authorized clearExtraRewards");

        delete extraRewards;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply()));
    }

    function earned(address _for) public view override returns (uint256) {
        return balanceOf(_for).mul(rewardPerToken().sub(userRewardPerTokenPaid[_for])).div(1e18).add(rewards[_for]);
    }

    function stake(address _for) public override nonReentrant updateReward(_for) {
        require(msg.sender == depositer, "ConvexRewardPool: !authorized stake");

        //also stake to linked rewards
        uint256 length = extraRewards.length;
        for (uint256 i = 0; i < length; i++) {
            IConvexRewardPool(extraRewards[i]).stake(_for);
        }

        emit Staked(_for);
    }

    function withdraw(address _for) public override nonReentrant updateReward(_for) {
        require(msg.sender == depositer, "ConvexRewardPool: !authorized withdraw");

        //also stake to linked rewards
        uint256 length = extraRewards.length;
        for (uint256 i = 0; i < length; i++) {
            IConvexRewardPool(extraRewards[i]).withdraw(_for);
        }

        emit Withdrawn(_for);
    }

    function getReward(address _for) public override nonReentrant updateReward(_for) {
        uint256 reward = rewards[_for];

        if (reward > 0) {
            rewards[_for] = 0;

            if (rewardToken != address(0)) {
                IERC20(rewardToken).safeTransfer(_for, reward);
            } else {
                require(address(this).balance >= reward, "!address(this).balance");

                payable(_for).sendValue(reward);
            }

            emit RewardPaid(_for, reward);
        }

        for (uint256 i = 0; i < extraRewards.length; i++) {
            IConvexRewardPool(extraRewards[i]).getReward(_for);
        }
    }

    function donate(uint256 _amount) external payable returns (bool) {
        require(_amount > 0, "!_amount");

        if (rewardToken == address(0)) {
            require(msg.value == _amount, "!_amount");
        } else {
            IERC20(rewardToken).safeTransferFrom(msg.sender, address(this), _amount);
        }

        notifyRewardAmount(_amount);

        return true;
    }

    function notifyRewardAmount(uint256 reward) public override updateReward(address(0)) {
        require(msg.sender == owner, "ConvexRewardPool: !authorized notifyRewardAmount");
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(reward < uint256(-1) / 1e18, "the notified reward cannot invoke multiplication overflow");

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);

        emit RewardAdded(reward);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

contract ConvexRewardFactoryV2 {
    address public owner;

    event CreateReward(IConvexRewardPool rewardPool, address rewardToken);

    constructor(address _owner) public {
        owner = _owner;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "ConvexRewardFactory: !authorized setOwner");

        owner = _owner;
    }

    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _depositer,
        address _owner
    ) external returns (address) {
        require(msg.sender == owner, "ConvexRewardFactory: !authorized createReward");

        IConvexRewardPool rewardPool = IConvexRewardPool(address(new ConvexRewardPoolV2(_rewardToken, _virtualBalance, _depositer, _owner)));

        emit CreateReward(rewardPool, _rewardToken);

        return address(rewardPool);
    }
}
