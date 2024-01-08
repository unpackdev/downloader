// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./PRBMathUD60x18.sol";

contract StakeFarm {
    using PRBMathUD60x18 for uint256;
    using SafeERC20 for IERC20;

    address immutable private homeToken;
    uint24 internal constant _SECONDS_IN_ONE_MONTH = 2592000;
    address private owner;

    struct UserStake {
        uint amount;
        uint stakeDate;
        uint rewards;
    }

    mapping(address => UserStake) private balances;

    event HomeTokenStaked(address _user, uint _amount);
    event Withdraw(address _user, uint _homeAmount, uint _rewardsAmount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _homeToken) {
        homeToken = _homeToken;
        owner = msg.sender;
    }

    function stake(address _user, uint _amount) external {
        require(_amount > 0, "InvalidAmount");
        require(IERC20(homeToken).balanceOf(msg.sender) >= _amount, "NoEnoughTokens");

        if (balances[_user].amount == 0) {
            balances[_user] = UserStake({
                amount: _amount,
                stakeDate: block.timestamp,
                rewards: 0
            });
        } else {
            balances[_user].rewards += _calculateRewards(_user);
            balances[_user].stakeDate = block.timestamp;
            balances[_user].amount += _amount;
        }

        IERC20(homeToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit HomeTokenStaked(_user, _amount);
    }

    function withdraw() external {
        require(balances[msg.sender].stakeDate > 0, "NoStaked");
        uint256 rewards = balances[msg.sender].rewards + _calculateRewards(msg.sender);
        uint256 homes = balances[msg.sender].amount;

        delete balances[msg.sender];

        IERC20(homeToken).safeTransfer(msg.sender, homes + rewards);

        emit Withdraw(msg.sender, homes, rewards);
    }

    function withdraw(address _user) external {
        require(msg.sender == owner, "BadOwner");
        require(balances[_user].stakeDate > 0, "NoStaked");
        uint256 rewards = balances[_user].rewards + _calculateRewards(_user);
        uint256 homes = balances[_user].amount;

        delete balances[_user];

        IERC20(homeToken).safeTransfer(_user, homes + rewards);

        emit Withdraw(_user, homes, rewards);
    }

    function changeOwner(address _owner) external {
        require(msg.sender == owner, "BadOwner");
        owner = _owner;
        emit OwnershipTransferred(msg.sender, _owner);
    }

    function getUserData(address _user) external view returns(uint256 homeTokens, uint256 pendingRewards, uint256 stakeDate, uint256 multiplier) {
        homeTokens = balances[_user].amount;
        pendingRewards = balances[_user].rewards + _calculateRewards(_user);
        stakeDate = balances[_user].stakeDate;
        multiplier = _calculateMultiplier(stakeDate);
    }

    function _calculateRewards(address _user) internal view returns(uint256) {
        uint256 amount = balances[_user].amount;
        uint256 multiplier = _calculateMultiplier(balances[_user].stakeDate);

        return amount.mul(multiplier);
    }

    function _calculateMultiplier(uint256 _stakeDate) internal view returns(uint256 multiplier) {
        uint256 one = 1;
        uint256 eight = 8;
        if ((block.timestamp - _stakeDate) / _SECONDS_IN_ONE_MONTH > 0) {
            uint256 secondsToCalculate = (block.timestamp - _stakeDate).div(_SECONDS_IN_ONE_MONTH);
            multiplier = eight.div(100).mul(secondsToCalculate.pow(one.div(3)));
            if (multiplier > 250000000000000000) multiplier = 250000000000000000;   // No more than 25% interest rate
        } else {
            uint256 maxOneMonth = 80000000000000000;
            uint256 secondsToCalculate = block.timestamp - _stakeDate;
            multiplier = secondsToCalculate.mul(maxOneMonth).div(_SECONDS_IN_ONE_MONTH);
        }
    }
}
