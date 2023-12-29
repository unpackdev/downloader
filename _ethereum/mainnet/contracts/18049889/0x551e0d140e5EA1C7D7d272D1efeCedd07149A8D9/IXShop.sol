// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
import "./IERC20.sol";

interface IXShop is IERC20 {
    event Snapshot(uint256 epoch, uint256 rewards, address indexed from);
    event Swapped(uint256 eth, uint256 shop);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 reward);
    event Reinvestment(address indexed user, bool status);

    // ========== State Changing Functions ==========
    // Deposit (stake) SHOP tokens and get XSHOP tokens of the same amount in return
    function deposit(uint256 _amount) external;

    // Withdraw (unstake) SHOP tokens and get XSHOP tokens back
    function withdraw(uint256 _amount) external;

    // Claim pending reward
    function claimReward() external;

    // Snapshot the current epoch and distribute rewards (ETH sent in msg.value)
    function snapshot() external payable;

    // Switch Autocompounding on/off
    function toggleReinvesting() external;

    // Get ETH from the contract
    function rescueETH(uint256 _weiAmount) external;

    // Get ERC20 from the contract
    function rescueERC20(address _tokenAdd, uint256 _amount) external;

    // ========== View functions ==========
    // Get pending rewards
    function calculateRewardForUser(address user) external view returns (uint256);

    // Get auto-compounding status
    function isReinvesting(address user) external view returns (bool);

    // Total rewards injected, - this is only for distribution
    function totalRewards() external view returns (uint256);

    // Current epoch ordinal number, starts from 0 and increases by 1 after each snapshot (by default every 24 hours)
    function currentEpoch() external view returns (uint256);
}
