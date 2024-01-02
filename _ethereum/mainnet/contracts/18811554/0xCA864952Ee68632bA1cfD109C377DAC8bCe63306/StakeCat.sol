// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IStake.sol";
import "./SafeMath.sol";
import "./Pausable.sol";

contract StakeCat is ReentrancyGuard, IStake, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public rewardSS = 11574074074074;
    uint256 public baseAmount = 3 * 1E7 * 1E18;
    address public tokenAddress;

    uint256 public pausedTime;

    mapping(address => StakeInfo) private stakes;

    struct StakeInfo {
        uint256 lastTime;
        uint256 amount;
        uint256 reward;
    }

    event Stake(
        address indexed sender,
        uint256 amount
    );

    event UnStake(
        address indexed sender,
        uint256 amount
    );

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function getStakeInfo(address addr) public virtual view returns (uint256 lastTime, uint256 amount, uint256 reward){
        StakeInfo memory info = stakes[addr];
        lastTime = info.lastTime;
        amount = info.amount;
        reward = getReward(addr);
    }

    function getReward(address sender) public override virtual view returns (uint256 reward){
        StakeInfo memory info = stakes[sender];
        if (info.lastTime > 0) {
            uint256 time;
            if (paused()) time = pausedTime >= info.lastTime ? pausedTime - info.lastTime : 0;
            else time = block.timestamp - info.lastTime;
            reward = time * rewardSS * info.amount / baseAmount + info.reward;
        } else reward = 0;
    }

    function stakeBatch(
        address[] memory tos,
        uint256[] memory amounts
    ) public virtual {
        require(tos.length == amounts.length, "length error");
        for (uint256 i = 0; i < tos.length; i++) {
            stakeFrom(tos[i], amounts[i]);
        }
    }

    function stakeFrom(address _receiver, uint256 _amount) public override virtual {
        require(_amount > 0, 'Error: _amount == 0');
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_receiver, _amount);
    }

    function stake(uint256 _amount) public override virtual {
        stakeFrom(_msgSender(), _amount);
    }

    function _stake(address _sender, uint256 _amount) internal {
        StakeInfo memory info = stakes[_sender];
        info.reward = getReward(_sender);
        info.lastTime = block.timestamp;
        info.amount += _amount;
        stakes[_sender] = info;
        emit Stake(_sender, _amount);
    }

    function unStake(uint256 _amount) external {
        StakeInfo memory info = stakes[_msgSender()];
        require(_amount > 0 && _amount <= info.amount, 'Error: _amount');
        info.reward = getReward(_msgSender());
        info.lastTime = block.timestamp;
        info.amount -= _amount;
        stakes[_msgSender()] = info;
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(_msgSender(), _amount);
        emit UnStake(_msgSender(), _amount);
    }

    function pause() public onlyOwner {
        _pause();
        pausedTime = block.timestamp;
    }

    function setRewardSS(uint256 _rewardSS) public onlyOwner {
        rewardSS = _rewardSS;
    }

    function setBaseAmount(uint256 _baseAmount) public onlyOwner {
        require(_baseAmount > 0, 'Error: _baseAmount = 0');
        baseAmount = _baseAmount;
    }
}
