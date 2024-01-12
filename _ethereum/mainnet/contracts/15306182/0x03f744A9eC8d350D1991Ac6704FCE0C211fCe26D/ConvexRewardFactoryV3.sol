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
import "./ConvexInterfacesV3.sol";
import "./IVirtualBalanceWrapper.sol";

contract ConvexRewardPoolV3 is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant PRECISION = 1e18;

    struct RewardPool {
        IERC20 rewardToken;
        uint256 accRewardPerShare;
        bool isActive;
        mapping(address => uint256) rewardPerSharePaid;
        mapping(address => uint256) rewards;
    }

    address public virtualBalance;
    address public depositer;
    address public owner;

    address[] public activeRewardPools;
    mapping(address => RewardPool) public rewardPools;

    event RewardAdded(uint256 rewards);
    event Staked(address indexed user);
    event Withdrawn(address indexed user);
    event RewardPaid(address indexed user, uint256 rewards);

    constructor(
        address _virtualBalance,
        address _depositer,
        address _owner
    ) public {
        virtualBalance = _virtualBalance;
        depositer = _depositer;
        owner = _owner;
    }

    function activeRewardPoolsLength() external view returns (uint256) {
        return activeRewardPools.length;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    function _getReward(address _rewardToken, address _for) internal {
        _updateRewards(_rewardToken, _for);

        RewardPool storage rewardPool = rewardPools[_rewardToken];
        uint256 rewards = rewardPool.rewards[_for];

        if (rewards > 0) {
            rewardPool.rewards[_for] = 0;

            if (!isETH(address(rewardPool.rewardToken))) {
                IERC20(rewardPool.rewardToken).safeTransfer(_for, rewards);
            } else {
                require(
                    address(this).balance >= rewards,
                    "!address(this).balance"
                );

                payable(_for).sendValue(rewards);
            }

            emit RewardPaid(_for, rewards);
        }
    }

    function getReward(address _for) public nonReentrant {
        for (uint256 i = 0; i < activeRewardPools.length; i++) {
            _getReward(activeRewardPools[i], _for);
        }
    }

    function getReward(address _rewardToken, address _for) public nonReentrant {
        _getReward(_rewardToken, _for);
    }

    function earned(address _rewardToken, address _for)
        public
        view
        returns (uint256)
    {
        RewardPool storage rewardPool = rewardPools[_rewardToken];

        return
            rewardPool.rewards[_for].add(
                rewardPool
                    .accRewardPerShare
                    .sub(rewardPool.rewardPerSharePaid[_for])
                    .mul(balanceOf(_for)) / PRECISION
            );
    }

    function rewardPerSharePaid(address _rewardToken, address _for)
        public
        view
        returns (uint256)
    {
        RewardPool storage rewardPool = rewardPools[_rewardToken];

        require(rewardPool.isActive, "!isActive");

        return rewardPool.rewardPerSharePaid[_for];
    }

    function _updateRewards(address _rewardToken, address _for) internal {
        uint256 rewards = earned(_rewardToken, _for);

        RewardPool storage rewardPool = rewardPools[_rewardToken];

        rewardPool.rewardPerSharePaid[_for] = rewardPool.accRewardPerShare;
        rewardPool.rewards[_for] = rewards;
    }

    function addRewardPool(address _rewardToken) public {
        require(
            msg.sender == owner,
            "ConvexRewardPool: !authorized notifyRewardAmount"
        );

        for (uint256 i = 0; i < activeRewardPools.length; i++) {
            require(
                activeRewardPools[i] != _rewardToken,
                "ConvexRewardPool: duplicate pool"
            );
        }

        activeRewardPools.push(_rewardToken);
        rewardPools[_rewardToken] = RewardPool({
            rewardToken: IERC20(_rewardToken),
            accRewardPerShare: 0,
            isActive: true
        });
    }

    function stake(address _for) public nonReentrant {
        require(msg.sender == depositer, "ConvexRewardPool: !authorized stake");

        for (uint256 i = 0; i < activeRewardPools.length; i++) {
            _updateRewards(activeRewardPools[i], _for);
        }

        emit Staked(_for);
    }

    function withdraw(address _for) public nonReentrant {
        require(
            msg.sender == depositer,
            "ConvexRewardPool: !authorized withdraw"
        );

        for (uint256 i = 0; i < activeRewardPools.length; i++) {
            _updateRewards(activeRewardPools[i], _for);
        }

        emit Withdrawn(_for);
    }

    function donate(address _rewardToken, uint256 _amount)
        external
        payable
        returns (bool)
    {
        RewardPool storage rewardPool = rewardPools[_rewardToken];

        require(rewardPool.isActive, "!isActive");

        if (isETH(_rewardToken)) {
            require(msg.value == _amount, "!_amount");
        }

        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        notifyRewardAmount(_rewardToken, _amount);

        return true;
    }

    function notifyRewardAmount(address _rewardToken, uint256 _rewards) public {
        require(
            _rewards < uint256(-1) / 1e18,
            "the notified reward cannot invoke multiplication overflow"
        );

        RewardPool storage rewardPool = rewardPools[_rewardToken];

        require(rewardPool.isActive, "!isActive");

        rewardPool.accRewardPerShare = rewardPool.accRewardPerShare.add(
            _rewards.mul(PRECISION) / totalSupply()
        );
    }

    function isETH(address _v) internal pure returns (bool) {
        return
            _v == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE ||
            _v == address(0);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

contract ConvexRewardFactoryV3 {
    address public owner;

    event CreateReward(address rewardPool);

    constructor(address _owner) public {
        owner = _owner;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "ConvexRewardFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createReward(
        address _virtualBalance,
        address _depositer,
        address _owner
    ) external returns (address) {
        require(
            msg.sender == owner,
            "ConvexRewardFactory: !authorized createReward"
        );

        address rewardPool = address(
            new ConvexRewardPoolV3(_virtualBalance, _depositer, _owner)
        );

        emit CreateReward(rewardPool);

        return rewardPool;
    }
}
