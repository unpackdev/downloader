// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC20.sol";

contract LPStaking {
    IERC20 public landToken;
    IERC20 public stakingToken;

    uint public constant rewardRate = 70e18;
    uint public immutable startBlock;
    uint public immutable endBlock;
    uint public lastUpdateBlock;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    constructor(address _landToken, address _stakingToken)
    {
        stakingToken = IERC20(_stakingToken);
        landToken = IERC20(_landToken);
        startBlock = block.number;
        endBlock = block.number + 1e6;
    }

    function lastBlock() public view returns (uint256) {
        return block.number < endBlock ? block.number : endBlock;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored +
        (((lastBlock() - lastUpdateBlock) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
        ((_balances[account] *
        (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
        rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = lastBlock();
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        require(_amount > 0, "Cannot stake 0");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdrawAndGetReward(uint _amount) external {
        withdraw(_amount);
        getReward();
    }

    function withdraw(uint256 _amount) public updateReward(msg.sender) {
        require(_amount > 0, "Cannot withdraw 0");
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        landToken.transfer(msg.sender, reward);
    }
}
