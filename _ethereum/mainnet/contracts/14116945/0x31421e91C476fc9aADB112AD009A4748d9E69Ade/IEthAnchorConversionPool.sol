// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0
pragma solidity ^0.8.0;
interface IConversionPool {
    /**
     * @notice Deposit of USDC to Eth Anchor using USDC token
     * @param _amount amount of USDC to transfer to Eth Anchor
     */
    function deposit(uint256 _amount) external;

    /**
     * @notice Retrieve USDC from Eth Anchor
     * @param _amount amount of aUSDC to retrieve from Eth Anchor
     */
    function redeem(uint256 _amount) external;
}
