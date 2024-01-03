// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20.sol";

/**
 * @title Dollet IWETH
 * @author Dollet Team
 * @notice Wrapped Ether (WETH) Interface. This interface defines the functions for interacting with the Wrapped Ether
 *         (WETH) contract.
 */
interface IWETH is IERC20 {
    /**
     * @notice Deposits ETH to mint WETH tokens. This function is payable, and the amount of ETH sent will be converted
     *         to WETH.
     */
    function deposit() external payable;

    /**
     * @notice Withdraws WETH and receives ETH.
     * @param _amount The amount of WETH to burn, represented in wei.
     */
    function withdraw(uint256 _amount) external;
}
