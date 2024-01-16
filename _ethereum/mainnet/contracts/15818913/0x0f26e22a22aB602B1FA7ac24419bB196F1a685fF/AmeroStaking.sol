// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract AmeroStaking {

    address owner;
    address public tokenContract;
    uint[] public profits;
    uint[] public mins;
    bool public lock = false;
    uint decimals;

    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        uint8 tier;
    }

    Stake[] public stakes;

    mapping(address => uint256) public stakeholders;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notLocked {
        require(lock == false);
        _;
    }

    event Staked(address indexed user, uint256 index, uint256 amount, uint8 tier, uint256 timestamp);
    event Withdrawed(address indexed user, uint256 reward, uint256 index, uint256 timestamp);

    constructor(address _tokenContract, uint _decimals) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        decimals = _decimals;

        profits.push(3);
        profits.push(5);
        profits.push(7);
        profits.push(10);
        
        mins.push(14 * 10 ** decimals);
        mins.push(29 * 10 ** decimals);
        mins.push(294 * 10 ** decimals);
        mins.push(2942 * 10 ** decimals);

        stakes.push();
    }
    
    function _addStake(address _user) private returns (uint256) {
        stakes.push();
        uint256 index = stakes.length - 1;
        stakes[index].user = _user;
        stakeholders[_user] = index;
        return index;
    }

    function stake(uint256 _amount) public returns (bool) {
        require(stakeholders[msg.sender] == 0);
        require(_amount >= mins[0]);

        IERC20 token = IERC20(tokenContract);
        token.transferFrom(msg.sender, address(this), _amount);

        return _stake(_amount);
    }

    function _stake(uint256 _amount) private returns (bool) {
        uint256 index = _addStake(msg.sender);

        stakes[index].amount = _amount;
        stakes[index].since = block.timestamp;
        stakes[index].tier = getStakeTier(_amount);

        emit Staked(msg.sender, index, _amount, stakes[index].tier, block.timestamp);

        return true;
    }

    function withdrawStake() public notLocked returns (bool) {
        uint256 index = stakeholders[msg.sender];

        require(index > 0);
        
        uint256 reward = getStakeReward(index);
        
        stakeholders[msg.sender] = 0;
        
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, reward);

        emit Withdrawed(msg.sender, reward, index, block.timestamp);

        return true;
    }

    function getStakeTier(uint256 _amount) public view returns (uint8) {
        uint8 tier;

        for(uint8 q = 0; q < 4; q++) {
            if(_amount >= mins[q]) {
                tier = q;
            }
        }

        return tier;
    }

    function getStakeReward(uint256 _index) public view returns (uint256) {
        uint256 diff = block.timestamp - stakes[_index].since;
        uint256 diff_date = diff / 60 / 60 / 24 / 30;

        uint256 factor = diff_date * profits[stakes[_index].tier];

        uint256 reward = stakes[_index].amount + stakes[_index].amount / 100 * factor;
        return reward;
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(tokenContract);
        if(_amount == 0) {
            _amount = token.balanceOf(address(this));
        }
        require(token.balanceOf(address(this)) >= _amount);
        token.transfer(owner, _amount);
    }

    function setParams(address _tokenContract, uint256 _decimals) external onlyOwner {
        tokenContract = _tokenContract;
        decimals = _decimals;
    }

    function setProfits(uint _profit1, uint _profit2, uint _profit3, uint _profit4) external onlyOwner {
        profits[0] = _profit1;
        profits[1] = _profit2;
        profits[2] = _profit3;
        profits[3] = _profit4;
    }

    function setMins(uint _min1, uint _min2, uint _min3, uint _min4) external onlyOwner  {
        mins[0] = _min1;
        mins[1] = _min2;
        mins[2] = _min3;
        mins[3] = _min4;
    }

    function setLock(bool _lock) external onlyOwner {
        lock = _lock;
    }

    function transferOwnership(address _owner) external onlyOwner {
        owner = _owner;
    }
}