// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;


/**
 * @notice sHEGIC token & staking pool: 0xf4128B00AFdA933428056d0F0D1d7652aF7e2B35
 */
interface ISHegic {
    function deposit(uint _amount) external;
    function transfer(address recipient, uint256 amount) external returns (bool);
    function claimAllProfit() external;
    function profitOf(address _account, uint _asset) external view returns (uint);
}
