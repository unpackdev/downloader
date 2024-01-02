// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    error NotOwner();

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract OZKStake is Ownable {
    error StakingWindowClosed();
    error StakingInProgress();
    error StakingNotInProgress();
    error InsufficientBalance();
    error NothingStaked();
    error NotAllowed();

    event Stake(address sender, uint256 cycle, uint256 amount);
    event Unstake(address sender, uint256 cycle, uint256 amount);

    uint256 public constant STAKING_OPEN_WINDOW = 3 days;
    address public immutable TOKEN;
    uint256 public immutable STAKING_DURATION;

    mapping(uint256 => uint256) public depositedAmount;
    mapping(uint256 => mapping(address => uint256)) public userStakedAmountMap;
    mapping(uint256 => uint256) public totalStakedToken;

    bool public allowEmergencyTokenWithdraw = false;
    uint256 public cycle;
    uint256 public openTime;

    constructor(address token_, uint256 stakingDuration_) {
        TOKEN = token_;
        STAKING_DURATION = stakingDuration_;
    }

    receive() external payable {}

    // owners
    function open() external payable onlyOwner {
        uint256 __openTime = openTime;
        if (block.timestamp >= __openTime && block.timestamp <= __openTime + STAKING_DURATION) {
            revert StakingInProgress();
        }
        cycle += 1;
        openTime = block.timestamp;
        _deposit();
    }

    function deposit() public payable onlyOwner {
        if (!isInProgress()) revert StakingNotInProgress();
        _deposit();
    }

    function emergencyWithdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    function syncDepositedAmount(uint256 amount, uint256 cycle_) external onlyOwner {
        if (address(this).balance < amount) revert InsufficientBalance();
        depositedAmount[cycle_] = amount;
    }

    function setAllowTokenWithdrawal(bool allow_) external onlyOwner {
        allowEmergencyTokenWithdraw = allow_;
    }

    // external
    function stake(uint256 amount_) external {
        if (!isOpen()) revert StakingWindowClosed();

        uint256 __cycle = cycle;

        userStakedAmountMap[__cycle][msg.sender] += amount_;
        totalStakedToken[__cycle] += amount_;

        emit Stake(msg.sender, __cycle, amount_);

        IERC20(TOKEN).transferFrom(msg.sender, address(this), amount_);
    }

    function unstake(uint256 cycle_) external {
        if (cycle_ == cycle && block.timestamp <= openTime + STAKING_DURATION) revert StakingInProgress();

        // check amount staked
        uint256 __amountStaked = userStakedAmountMap[cycle_][msg.sender];
        if (__amountStaked == 0) revert NothingStaked();

        // calculate amount
        uint256 __totalStaked = totalStakedToken[cycle_];
        uint256 claimableReward = 0;
        if (__totalStaked != 0) {
            claimableReward = depositedAmount[cycle_] * __amountStaked / __totalStaked;
        }

        // update state
        userStakedAmountMap[cycle_][msg.sender] -= __amountStaked;

        emit Unstake(msg.sender, cycle_, __amountStaked);

        // withdraw
        IERC20(TOKEN).transfer(msg.sender, __amountStaked);
        (bool success,) = msg.sender.call{value: claimableReward}("");
        require(success);
    }

    function emergencyTokenWithdraw(uint256 cycle_) external {
        if (!allowEmergencyTokenWithdraw) revert NotAllowed();

        // check amount staked
        uint256 __amountStaked = userStakedAmountMap[cycle_][msg.sender];
        if (__amountStaked == 0) revert NothingStaked();

        // update state
        userStakedAmountMap[cycle_][msg.sender] -= __amountStaked;

        emit Unstake(msg.sender, cycle_, __amountStaked);

        // withdraw
        IERC20(TOKEN).transfer(msg.sender, __amountStaked);
    }

    // views
    function isOpen() public view returns (bool) {
        uint256 __openTime = openTime;
        if (block.timestamp >= __openTime && block.timestamp <= __openTime + STAKING_OPEN_WINDOW) {
            return true;
        }

        return false;
    }

    function isInProgress() public view returns (bool) {
        uint256 __openTime = openTime;
        if (block.timestamp >= __openTime && block.timestamp <= __openTime + STAKING_DURATION) {
            return true;
        }

        return false;
    }

    function claimable(uint256 cycle_, address addr) external view returns (uint256) {
        uint256 __amountStaked = userStakedAmountMap[cycle_][addr];
        uint256 __totalStaked = totalStakedToken[cycle_];

        if (__totalStaked == 0) return 0;
        return depositedAmount[cycle_] * __amountStaked / __totalStaked;
    }

    // private
    function _deposit() private {
        depositedAmount[cycle] += msg.value;
    }
}