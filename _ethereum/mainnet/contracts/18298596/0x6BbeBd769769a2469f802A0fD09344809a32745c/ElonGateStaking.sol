// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract ElonGateStaking is Ownable {
    IERC20 public elonGate = IERC20(0xcC6c4F450f1d4aeC71C46f240a6bD50c4E556B8A);
    uint256 public totalStaked;

    struct UserStake {
        uint256 totalAmount;
        uint256 lastClaimTime;
        uint256 stakingTime;
    }

    mapping(address => UserStake) public userStakes;

    uint256 public constant APY = 5000;
    uint256 public constant lockupPeriod = 3 days;

    constructor() {
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");

        UserStake storage user = userStakes[msg.sender];

        if (user.stakingTime == 0) {
            user.stakingTime = block.timestamp;
        } else {
            uint256 rewards = calculateRewards(user);
            if (rewards > 0) {
                elonGate.transfer(msg.sender, rewards);
            }
        }
        
        elonGate.transferFrom(msg.sender, address(this), _amount);
        user.totalAmount += _amount;
        user.lastClaimTime = block.timestamp;
        totalStaked += _amount;
    }

    function harvest() external {
        UserStake storage user = userStakes[msg.sender];
        require(user.stakingTime > 0, "You have not staked yet");

        uint256 rewards = calculateRewards(user);

        user.lastClaimTime = block.timestamp;
        
        elonGate.transfer(msg.sender, rewards);
    }

    function withdraw() external {
        UserStake storage user = userStakes[msg.sender];
        require(user.stakingTime > 0, "You have not staked yet");
        require(
            block.timestamp >= user.stakingTime + lockupPeriod,
            "Lockup period has not ended yet"
        );

        uint256 amountToWithdraw = user.totalAmount + calculateRewards(user);
        elonGate.transfer(msg.sender, amountToWithdraw);
        
        delete userStakes[msg.sender];
    }

    function getReward(address _user) external view returns (uint256) {
        UserStake storage user = userStakes[_user];

        if (user.stakingTime == 0) {
            return 0;
        }

        uint256 rewards = calculateRewards(user);

        return rewards;
    }

    function calculateRewards(
        UserStake storage user
    ) internal view returns (uint256) {
        uint256 currentTime = block.timestamp;
        uint256 lastClaimTime = user.lastClaimTime;

        if (currentTime <= lastClaimTime) {
            return 0;
        }

        uint256 timeDiff = currentTime - lastClaimTime;
        uint256 rewards = (user.totalAmount * APY * timeDiff) / (100 * 365 days);

        return rewards;
    }

    function emergencyWithdraw() external onlyOwner {
        elonGate.transfer(msg.sender, elonGate.balanceOf(address(this)));
    }
}
