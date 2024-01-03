// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "./IERC20.sol";

/**
 * @dev Modified Interface of the ERC20 standard.
 */
interface IARVO is IERC20 {

    /**
     * Creates `amount` tokens and assigns them to `Terminal Contract`, increasing the total supply.
     * This function will be used to mint only rewards per blocks with maximum supply of the governance decision.
     */
    function mint(address _beneficiary, uint256 _amount) external;

    /**
     * Burn function will burn arvo when the stablecoin returns be used to buy Arvo from Uniswap and burn through this function
     */
    function burn(address _beneficiary, uint256 _amount) external;
}
