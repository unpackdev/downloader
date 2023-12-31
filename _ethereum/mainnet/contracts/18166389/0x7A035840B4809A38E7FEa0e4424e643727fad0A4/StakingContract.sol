// SPDX-License-Identifier: none
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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

contract StakingContract is Ownable {
    IERC20 public borat;
    uint256 public totalStakedAmount;
    uint256 public totalStakingScore;
    uint256 public stakingFee = 1; // 1%
    uint256 public unstakeCooldown = 1 days;

    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public requestedUnstakeAmount;
    mapping(address => uint256) public lastStakeTime;
    mapping(address => uint256) public lastUnstakeRequestTime;
    address[] public stakers;

    event Stake(address indexed user, uint256 amount);
    event RequestUnstake(address indexed user, uint256 amount);
    event CompleteUnstake(address indexed user, uint256 amount);

    constructor(IERC20 _borat) {
        borat = _borat;
    }

    modifier onlyStaker() {
        require(stakedAmount[msg.sender] > 0, "Must be staker");
        _;
    }

    function updateUnstakeCooldown(uint256 _unstakeCooldown) external onlyOwner {
        unstakeCooldown = _unstakeCooldown;
    }

    function updateStakingFee(uint256 _stakingFee) external onlyOwner {
        require(_stakingFee <= 100, "Invalid staking fee");
        stakingFee = _stakingFee;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0 tokens");

        uint256 fee = (_amount * stakingFee) / 100;
        uint256 amountAfterFee = _amount - fee;

        // Transfer BORAT tokens to this contract
        borat.transferFrom(msg.sender, address(this), _amount);

        // Burn the staking fee
        borat.transfer(address(0), fee);

        // Update the staking score and total staked amount
        totalStakingScore -= stakingScore(msg.sender);
        stakedAmount[msg.sender] += amountAfterFee;
        totalStakedAmount += amountAfterFee;
        totalStakingScore += stakingScore(msg.sender);

        // Update the last stake time
        lastStakeTime[msg.sender] = block.timestamp;

        // Add the user to the stakers array if they are not already in it
        if (stakedAmount[msg.sender] == amountAfterFee) {
            stakers.push(msg.sender);
        }

        emit Stake(msg.sender, amountAfterFee);
    }

    function requestUnstake(uint256 _amount) external onlyStaker {
        require(_amount > 0, "Cannot request unstake of 0 tokens");
        require(stakedAmount[msg.sender] >= _amount, "Not enough tokens staked");
        require(requestedUnstakeAmount[msg.sender] == 0, "Cannot request more tokens to unstake while there are tokens in cooldown");

        // Update the staking score and total staked amount
        totalStakingScore -= stakingScore(msg.sender);
        stakedAmount[msg.sender] -= _amount;
        totalStakedAmount -= _amount;
        totalStakingScore += stakingScore(msg.sender);

        requestedUnstakeAmount[msg.sender] += _amount;
        if (requestedUnstakeAmount[msg.sender] == _amount) {
            lastUnstakeRequestTime[msg.sender] = block.timestamp;
        }

        emit RequestUnstake(msg.sender, _amount);
    }

    function completeUnstake() external {
        require(requestedUnstakeAmount[msg.sender] > 0, "No unstake request found");
        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + unstakeCooldown, "Unstake cooldown not yet finished");

        uint256 amount = requestedUnstakeAmount[msg.sender];
        requestedUnstakeAmount[msg.sender] = 0;

        borat.transfer(msg.sender, amount);

        emit CompleteUnstake(msg.sender, amount);
    }

    function stakingScore(address _user) public view returns (uint256) {
        return stakedAmount[_user] * (block.timestamp - lastStakeTime[_user]);
    }

    function airdropPercentage(address _user) public view returns (uint256) {
        if (totalStakingScore == 0) {
            return 0;
        }
        return (stakingScore(_user) * 1000) / totalStakingScore;
    }

    function tokensInCooldown(address _user) public view returns (uint256) {
        return requestedUnstakeAmount[_user];
    }

    function timeUntilUnstakeComplete(address _user) public view returns (uint256) {
        uint256 cooldownEnd = lastUnstakeRequestTime[_user] + unstakeCooldown;
        if (block.timestamp >= cooldownEnd) {
            return 0;
        } else {
            return cooldownEnd - block.timestamp;
        }
    }

    function returnStakedTokensToHolders() external onlyOwner {
        for (uint i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 amount = stakedAmount[staker];
            stakedAmount[staker] = 0;
            totalStakedAmount -= amount;
            borat.transfer(staker, amount);
        }
    }
}