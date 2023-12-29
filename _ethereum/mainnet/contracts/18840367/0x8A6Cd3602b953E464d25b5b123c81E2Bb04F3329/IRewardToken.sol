// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./IERC20Upgradeable.sol";
interface IRewardToken is IERC20Upgradeable{
   
    /**
     * @dev Update accumulatedPerBlock and user.debt when stake() is called
     */
    function updateAccumulatedWhenStake(address account, uint256 amount) external;
    /**
     * @dev Update accumulatedPerBlock and user.debt when unstake() is called
     */
    function updateAccumulatedWhenUnstake(address account, uint256 amount) external;

}
