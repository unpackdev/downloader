// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IStake.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./EnumerableSet.sol";

contract StakeToken is ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private users;

    uint256 public rewardSS = 231481481481;
    uint256 public baseAmount = 1E18;
    address public tokenAddress;
    address public rewardToken;

    uint256 public pausedTime;

    mapping(address => StakeInfo) private stakes;

    struct StakeInfo {
        uint256 lastTime;
        uint256 amount;
        uint256 reward;
        uint256 claimed;
    }

    event Stake(
        address indexed sender,
        uint256 amount
    );

    event UnStake(
        address indexed sender,
        uint256 amount
    );

    event Claim(
        address indexed sender,
        uint256 amount
    );

    constructor(address _tokenAddress, address _rewardToken) {
        tokenAddress = _tokenAddress;
        rewardToken = _rewardToken;
    }

    function getStakeInfo(address addr) public virtual view returns (uint256 lastTime, uint256 amount, uint256 reward, uint256 claimed){
        StakeInfo memory info = stakes[addr];
        lastTime = info.lastTime;
        amount = info.amount;
        reward = getReward(addr);
        claimed = info.claimed;
    }

    function getReward(address sender) public virtual view returns (uint256 reward){
        StakeInfo memory info = stakes[sender];
        if (info.lastTime > 0) {
            uint256 time;
            if (paused()) time = pausedTime >= info.lastTime ? pausedTime - info.lastTime : 0;
            else time = block.timestamp - info.lastTime;
            reward = time * rewardSS * info.amount / baseAmount + info.reward;
        } else reward = 0;
    }

    function stake(uint256 _amount) public virtual {
        require(_amount > 0, 'Error: _amount == 0');
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(_msgSender(), address(this), _amount);
        _stake(_msgSender(), _amount);
    }

    function _stake(address _sender, uint256 _amount) internal {
        users.add(_sender);
        StakeInfo storage info = stakes[_sender];
        info.reward = getReward(_sender);
        info.lastTime = block.timestamp;
        info.amount += _amount;
        uint256 claimed = info.reward - info.claimed;
        info.claimed += claimed;
        if (claimed > 0) _safeTransferReward(_sender, claimed);
        emit Stake(_sender, _amount);
    }

    function unStake(uint256 _amount) external {
        StakeInfo storage info = stakes[_msgSender()];
        require(_amount > 0 && _amount <= info.amount, 'Error: _amount');
        info.reward = getReward(_msgSender());
        info.lastTime = block.timestamp;
        info.amount -= _amount;
        uint256 claimed = info.reward - info.claimed;
        info.claimed += claimed;
        if (claimed > 0) _safeTransferReward(_msgSender(), claimed);
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(_msgSender(), _amount);
        emit UnStake(_msgSender(), _amount);
    }

    function claim() external {
        StakeInfo storage info = stakes[_msgSender()];
        info.reward = getReward(_msgSender());
        info.lastTime = block.timestamp;
        uint256 claimed = info.reward - info.claimed;
        info.claimed += claimed;
        if (claimed > 0) _safeTransferReward(_msgSender(), claimed);
        emit Claim(_msgSender(), claimed);
    }

    function withdraw(uint256 _amount) public onlyOwner {
        _safeTransferReward(_msgSender(), _amount);
    }

    function userList() public view virtual returns (address[] memory list){
        list = new address[](users.length());
        for (uint256 i = 0; i < users.length(); ++i) {
            list[i] = users.at(i);
        }
    }

    function _safeTransferReward(address _sender, uint256 _amount) internal {
        IERC20 token = IERC20(rewardToken);
        uint256 balance = token.balanceOf(address(this));
        if (balance < _amount) _amount = balance;
        token.safeTransfer(_sender, _amount);
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
