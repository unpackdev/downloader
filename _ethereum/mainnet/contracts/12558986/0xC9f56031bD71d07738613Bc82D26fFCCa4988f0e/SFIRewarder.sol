// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract SFIRewarder is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public sfi;
    address public saffronStaking;

    constructor(address _sfi) public {
        require(_sfi != address(0), "invalid sfi address");
        sfi = IERC20(_sfi);
    }

    function setStakingAddress(address _staking) external onlyOwner {
        require(_staking != address(0), "invalid staking addr");
        saffronStaking = _staking;
    }

    event SupplyReward(address indexed to, uint256 amount, uint256 timestamp);

    function supplyRewards(address to, uint256 amount) external {
        require(saffronStaking != address(0), "staking addr is not set");
        require(msg.sender == saffronStaking, "only staking pool can call this func");

        uint256 _balance = sfi.balanceOf(address(this));
        if (_balance > amount) {
            sfi.safeTransfer(to, amount);
            emit SupplyReward(to, amount, block.timestamp);
        } else {
            sfi.safeTransfer(to, _balance);
            emit SupplyReward(to, _balance, block.timestamp);
        }
    }

    function emergencyWithdraw(address token, address to) external onlyOwner {
        uint256 _balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(to, _balance);
    }
}
