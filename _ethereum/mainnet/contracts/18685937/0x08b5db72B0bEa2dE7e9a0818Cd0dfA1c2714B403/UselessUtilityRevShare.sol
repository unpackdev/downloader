// SPDX-License-Identifier: Unlicensed 
/*
USELESS OFFICIAL LINKS
TWITTER: https://twitter.com/UtilityUseless 
DISCORD: https://discord.gg/qfxVfCduHw 
WEBSITE: https://uselessutility.com/ 
APP: https://app.uselessutility.com/
---------------------------------------------------------------------
OFFICIAL MIDDLEMEN: https://t.me/uselessutilityescrow 
OTC TELEGRAM: https://t.me/uselessutilityotc 
TELEGRAM: https://t.me/uselessutility
---------------------------------------------------------------------
YOUTUBE: https://www.youtube.com/@UselessUtility 
MEDIUM: https://medium.com/@uselessutility 
GITHUB: https://github.com/UselessUtility 
GITBOOK: https://useless-utility.gitbook.io/useless-utility/
*/


// Official revshare contract
pragma solidity 0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

contract UselessUtilityRevShare is Ownable {

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 startTime;
        uint256 totalRewards;
    }

    IERC20 public uselessUtilityToken;
    uint256 public lastRewardTimestamp;
    uint256 public accTokenPerShare;
    uint256 public rewardPerSecond;
    uint256 public rewardSupply;

    mapping(address => UserInfo) public userInfo;
    uint256 public totalStaked;

    uint256 public startTime;
    bool public started;
    bool public finished;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC20 _uselessUtilityToken, uint256 _rewardPerSecond) {
        uselessUtilityToken = _uselessUtilityToken;
        rewardPerSecond = _rewardPerSecond;
    }

    function pending(address _user) external view returns (uint256) {
        UserInfo memory user = userInfo[_user];
        uint256 _accTokenPerShare = accTokenPerShare;
        uint256 balance = uselessUtilityToken.balanceOf(address(this));
        if (block.timestamp > lastRewardTimestamp && balance != 0) {
            uint256 tokenReward = (block.timestamp - lastRewardTimestamp) * rewardPerSecond;
            _accTokenPerShare += (tokenReward * 1e36 / balance);
        }
        return (user.amount * _accTokenPerShare / 1e36) - user.rewardDebt;
    }

    function updatePool() public {
        uint256 timestamp = block.timestamp;
        if (!started) {
            revert("not started");
        }
        if (timestamp <= lastRewardTimestamp) {
            return;
        }
        uint256 _totalStaked = totalStaked;
        if (_totalStaked == 0) {
            lastRewardTimestamp = timestamp;
            return;
        }
        uint256 reward = (timestamp - lastRewardTimestamp) * rewardPerSecond;
        accTokenPerShare += (reward * 1e36 / _totalStaked);
        lastRewardTimestamp = timestamp;
        rewardSupply += reward;
    }

    function _claimRewards(uint256 amount, uint256 rewardDebt) internal returns (uint256 amountToSend) {
        uint256 totalRewards = (amount * accTokenPerShare / 1e36) - rewardDebt;
        uint bal = uselessUtilityToken.balanceOf(address(this)) - totalStaked;
        amountToSend = totalRewards > bal ? bal : totalRewards;
        IERC20(uselessUtilityToken).transfer(msg.sender, amountToSend);
        rewardSupply -= totalRewards;
        emit RewardClaimed(msg.sender, totalRewards);
    }

    function stake(uint256 _tokenAmount) external {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        }
        if (_tokenAmount > 0) {
            uselessUtilityToken.transferFrom(address(msg.sender), address(this), _tokenAmount);
            //for apy calculations
            if (user.amount == 0) {
                user.startTime = block.timestamp;
                user.totalRewards = 0;
            }
            //update balances
            user.amount += _tokenAmount;
            totalStaked += _tokenAmount;
            emit Deposit(msg.sender, _tokenAmount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function unstakeToken(uint256 _tokenAmount, bool unstake_) external {
        unstake_;
        UserInfo storage user = userInfo[msg.sender];
        if (_tokenAmount > user.amount) {
            revert("Not enough balance");
        }
        updatePool();
        if (user.amount > 0) {
            uint256 amountTransferred = _claimRewards(user.amount, user.rewardDebt);
            user.totalRewards += amountTransferred;
        }
        if (_tokenAmount > 0) {
            user.amount -= _tokenAmount;
            uselessUtilityToken.transfer(address(msg.sender), _tokenAmount);
            totalStaked -= _tokenAmount;
            emit Withdraw(msg.sender, _tokenAmount);
        }
        user.rewardDebt = user.amount * accTokenPerShare / 1e36;
    }

    function setRewards(uint256 _rewardPerSecond) external onlyOwner {
        if (finished) {
            revert("Done");
        }
        rewardPerSecond = _rewardPerSecond;
    }

    function openPool(uint256 _startTime) external onlyOwner {
        if (started) {
            revert("Already on");
        }
        started = true;
        startTime = _startTime;
        lastRewardTimestamp = _startTime;
    }

    function finishPool() external onlyOwner {
        if (finished) {
            revert("Already finished");
        }
        finished = true;
        updatePool();
        rewardPerSecond = 0;
        
        if (totalStaked > rewardSupply) {
            IERC20(uselessUtilityToken).transfer(owner(), totalStaked - rewardSupply);
        }
    }
}