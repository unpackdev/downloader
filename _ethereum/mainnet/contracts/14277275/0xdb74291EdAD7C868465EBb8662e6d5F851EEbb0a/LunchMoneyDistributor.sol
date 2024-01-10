// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./IBitBullies.sol";

contract LunchMoneyDistributor is Pausable, ReentrancyGuard, Ownable {
	using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    uint256 public immutable reward_start_time = 1645578000;
    uint256[6] public multipliers = [32, 16, 8, 4, 2, 1];
    uint256[6] public timestamps = [1645750800, 1646960400, 1648166400, 1649376000, 1650585600, 1708822800];

    // Daily emission rate base is 86 tokens per bully
    uint256 public BASE_RATE = 86 ether;

    IBitBullies public immutable bitbulliesContract;
    IERC20 public immutable lunchMoneyToken;

	event RewardPaid(address indexed user, uint256 reward);
    event TokenWithdrawnOwner(uint256 amount);

    constructor(address _bitbullies, address _lunchMoneyToken){
        bitbulliesContract = IBitBullies(_bitbullies);
        lunchMoneyToken = IERC20(_lunchMoneyToken);
    }

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
    
    function updateRewardOnMint(address _user) external {
        require(msg.sender == address(bitbulliesContract), "Can't call this");
        uint256 time = block.timestamp;
        uint256 lastUpdateUser = lastUpdate[_user];
        
        if (lastUpdateUser > 0)
            rewards[_user] += _calculateRewards(_user, lastUpdateUser, time);

        lastUpdate[_user] = time;
    }

    function updateRewardOnTransfer(address _from, address _to) external {
        require(msg.sender == address(bitbulliesContract), "Can't call this");
        uint256 time = block.timestamp;
        uint256 end_time = timestamps[timestamps.length-1];
        uint256 lastUpdateFrom = lastUpdate[_from];

        if (lastUpdateFrom < end_time){
            if (lastUpdateFrom > 0)
                rewards[_from] += _calculateRewards(_from, lastUpdateFrom, time);
            lastUpdate[_from] = time;
        }
        if (_to != address(0)) {
            uint256 lastUpdateTo = lastUpdate[_to];
            if (lastUpdateTo < end_time){
                if (lastUpdateTo > 0)
                    rewards[_to] += _calculateRewards(_to, lastUpdateTo, time);
                lastUpdate[_to] = time;
            }
        }
    }

    function _calculateRewards(address _user, uint256 start_time, uint256 end_time) internal view returns (uint256) {
        uint256 reward = 0;

        if (end_time < reward_start_time) return reward;

        uint256 current_start_time = start_time;

        for (uint i = 0; i < multipliers.length; i++){
            if (current_start_time > timestamps[i])
                continue;
            uint256 current_end_time = min(timestamps[i], end_time);
            reward += bitbulliesContract.bulliesBalance(_user).mul(BASE_RATE.mul(multipliers[i].mul((current_end_time.sub(current_start_time))))).div(86400);
            if (timestamps[i] > end_time)
                break;
            current_start_time = timestamps[i];
        }
        return reward;
    }

    function claim(address _user) external whenNotPaused nonReentrant {
        uint256 time = block.timestamp;
        uint256 lastUpdateUser = lastUpdate[_user];
        uint256 reward = 0;
        
        if (lastUpdateUser > 0)
            reward = rewards[_user] + _calculateRewards(_user, lastUpdateUser, time);

        lastUpdate[_user] = time;
        
        if (reward > 0) {
            rewards[_user] = 0;
            lunchMoneyToken.safeTransfer(_user, reward);

            emit RewardPaid(_user, reward);
        }
    }

    function getRewardAmount(address _user) external view returns(uint256) {
        uint256 time = block.timestamp;
        if (lastUpdate[_user] > 0)
            return rewards[_user] + _calculateRewards(_user, lastUpdate[_user], time);
        else
            return 0;
    }

    function pauseDistribution() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseDistribution() external onlyOwner whenPaused {
        _unpause();
    }

    function updateBaseRate(uint256 new_rate) external onlyOwner {
        BASE_RATE = new_rate;
    }

    function updateLastUpdateMap(address[] memory _addresses, uint256[] memory _updates) external onlyOwner {
        require (_addresses.length == _updates.length);
        for (uint256 i = 0; i < _addresses.length; i++){
            lastUpdate[_addresses[i]] = _updates[i];
        }
    }

    function updateRewardMap(address[] memory _addresses, uint256[] memory _rewards) external onlyOwner {
        require (_addresses.length == _rewards.length);
        for (uint256 i = 0; i < _addresses.length; i++){
            rewards[_addresses[i]] = _rewards[i];
        }
    }

    function withdrawTokenRewards(uint256 amount) external onlyOwner whenPaused {
        lunchMoneyToken.safeTransfer(msg.sender, amount);

        emit TokenWithdrawnOwner(amount);
    }
}