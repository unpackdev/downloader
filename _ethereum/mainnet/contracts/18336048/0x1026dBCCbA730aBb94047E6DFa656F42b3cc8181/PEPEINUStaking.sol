/**
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


interface IERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}


abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() private view returns (bool) {
        return _status == _ENTERED;
    }
}



contract PEPEINUStaking is Ownable, ReentrancyGuard {
    struct PoolInfo {
        uint256 lockupDuration;
        uint256 returnPer;
    }
    struct OrderInfo {
        address beneficiary;
        uint256 amount;
        uint256 lockupDuration;
        uint256 returnPer;
        uint256 starttime;
        uint256 endtime;
        uint256 claimedReward;
        bool claimed;
    }
    uint256 private constant _days7 = 7 days;
    uint256 private constant _days14 = 14 days;
    uint256 private constant _days365 = 365 days;
    IERC20 public token;
    bool public started = true;
    uint256 public emergencyWithdrawFeesPercentage = 0;

    uint256 private _7daysPercentage = 1080;
    uint256 private _14daysPercentage = 1180;

    uint256 private latestOrderId = 0;
    uint public totalStakers ; // use 
    uint public totalStaked ; // use 
    uint256 public totalStake = 0;
    uint256 public totalWithdrawal = 0;
    uint256 public totalRewardPending = 0;
    uint256 public totalRewardsDistribution = 0;

    mapping(uint256 => PoolInfo) public pooldata;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public totalRewardEarn;
    mapping(uint256 => OrderInfo) public orders;
    mapping(address => uint256[]) private orderIds;

    mapping(address => mapping(uint => bool)) public hasStaked;
    mapping(uint => uint) public stakeOnPool;
    mapping(uint => uint) public rewardOnPool;
    mapping(uint => uint) public stakersPlan;

    event Deposit(
        address indexed user,
        uint256 indexed lockupDuration,
        uint256 amount,
        uint256 returnPer
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 reward,
        uint256 total
    );
    event WithdrawAll(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RefRewardClaimed(address indexed user, uint256 reward);

    constructor(address _token, bool _started) {
        token = IERC20(_token);
        started = _started;

        pooldata[7].lockupDuration = _days7; // 7 days
        pooldata[7].returnPer = _7daysPercentage;

        pooldata[14].lockupDuration = _days14; // 14 days
        pooldata[14].returnPer = _14daysPercentage;


    }

    function deposit(
        uint256 _amount,
        uint256 _lockupDuration
    ) external {


        PoolInfo storage pool = pooldata[_lockupDuration];
        require(
            pool.lockupDuration > 0,
            "TokenStakingSAFU: asked pool does not exist"
        );
        require(started, "TokenStakingSAFU: staking not yet started");
        require(_amount > 0, "TokenStakingSAFU: stake amount must be non zero");

        uint256 APY = (_amount * pool.returnPer) / 100;
        uint256 userReward = (APY * pool.lockupDuration) / _days365;
        uint256 requiredToken = (totalStake - totalWithdrawal) +
            totalRewardPending +
            userReward;
        require(
            requiredToken <= token.balanceOf(address(this)),
            "TokenStakingSAFU: insufficient contract balance to return rewards"
        );
        require(
            token.transferFrom(_msgSender(), address(this), _amount),
            "TokenStakingSAFU: token transferFrom via deposit not succeeded"
        );

        orders[++latestOrderId] = OrderInfo(
            _msgSender(),
            _amount,
            pool.lockupDuration,
            pool.returnPer,
            block.timestamp,
            block.timestamp + pool.lockupDuration,
            0,
            false
        );

          if (!hasStaked[msg.sender][_lockupDuration]) {
             stakersPlan[_lockupDuration] = stakersPlan[_lockupDuration] + 1;
             totalStakers = totalStakers + 1 ;
        }

        hasStaked[msg.sender][_lockupDuration] = true;
        stakeOnPool[_lockupDuration] = stakeOnPool[_lockupDuration] + _amount ;
        totalStaked = totalStaked + _amount ;
        totalStake += _amount;
        totalRewardPending += userReward;
        balanceOf[_msgSender()] += _amount;
        orderIds[_msgSender()].push(latestOrderId);
        emit Deposit(
            _msgSender(),
            pool.lockupDuration,
            _amount,
            pool.returnPer
        );
    }


    function withdraw(uint256 orderId) external nonReentrant {
        require(
            orderId <= latestOrderId,
            "TokenStakingSAFU: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(
            _msgSender() == orderInfo.beneficiary,
            "TokenStakingSAFU: caller is not the beneficiary"
        );
        require(!orderInfo.claimed, "TokenStakingSAFU: order already unstaked");
    
        uint256 claimAvailable = pendingRewards(orderId);
        uint256 total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable;
        totalRewardsDistribution += claimAvailable;
        orderInfo.claimedReward += claimAvailable;
        totalRewardPending -= claimAvailable;

        balanceOf[_msgSender()] -= orderInfo.amount;
        totalWithdrawal += orderInfo.amount;
        orderInfo.claimed = true;

        require(
            token.transfer(address(_msgSender()), total),
            "TokenStakingSAFU: token transfer via withdraw not succeeded"
        );
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit Withdraw(_msgSender(), orderInfo.amount, claimAvailable, total);
    }


    function claimRewards(uint256 orderId) external nonReentrant {
        require(
            orderId <= latestOrderId,
            "TokenStakingSAFU: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        require(
            _msgSender() == orderInfo.beneficiary,
            "TokenStakingSAFU: caller is not the beneficiary"
        );
        require(!orderInfo.claimed, "TokenStakingSAFU: order already unstaked");

        uint256 claimAvailable = pendingRewards(orderId);
        totalRewardEarn[_msgSender()] += claimAvailable;
        totalRewardsDistribution += claimAvailable;
        totalRewardPending -= claimAvailable;
        orderInfo.claimedReward += claimAvailable;

        require(
            token.transfer(address(_msgSender()), claimAvailable),
            "TokenStakingSAFU: token transfer via claim rewards not succeeded"
        );
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function pendingRewards(uint256 orderId) public view returns (uint256) {
        require(
            orderId <= latestOrderId,
            "TokenStakingSAFU: INVALID orderId, orderId greater than latestOrderId"
        );

        OrderInfo storage orderInfo = orders[orderId];
        if (!orderInfo.claimed) {
            if (block.timestamp >= orderInfo.endtime) {
                uint256 APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint256 reward = (APY * orderInfo.lockupDuration) / _days365;
                uint256 claimAvailable = reward - orderInfo.claimedReward;
                return claimAvailable;
            } else {
                uint256 stakeTime = block.timestamp - orderInfo.starttime;
                uint256 APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint256 reward = (APY * stakeTime) / _days365;
                uint256 claimAvailableNow = reward - orderInfo.claimedReward;
                return claimAvailableNow;
            }
        } else {
            return 0;
        }
    }

    function toggleStaking(bool _start) external onlyOwner returns (bool) {
        started = _start;
        return true;
    }

    function investorOrderIds(
        address investor
    ) external view returns (uint256[] memory ids) {
        uint256[] memory arr = orderIds[investor];
        return arr;
    }

    function _totalRewards(address ref) private view returns (uint256) {
        uint256 rewards;
        uint256[] memory arr = orderIds[ref];
        for (uint256 i = 0; i < arr.length; i++) {
            OrderInfo memory order = orders[arr[i]];
            rewards += (order.claimedReward + pendingRewards(arr[i]));
        }
        return rewards;
    }


    function transferAnyERC20Token(
        address payaddress,
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        IERC20(tokenAddress).transfer(payaddress, amount);
    }
}