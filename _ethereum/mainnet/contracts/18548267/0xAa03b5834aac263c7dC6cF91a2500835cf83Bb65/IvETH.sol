// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;


/**
 * @title vETH
 * @author Riley - Two Brothers Crypto (riley@twobrotherscrypto.dev)
 * @notice Holds Ethereum on behalf of end users to be used in ToadSwap operations without subsequent approvals being required.
 * In essence, a privileged version of WETH9. Implements the WETH9 spec, but with extra functions.
 */
abstract contract IvETH {



    function balanceOf(address account) public virtual view returns (uint);

    function deposit() external virtual payable;

    function withdraw(uint wad) public virtual;

    function convertFromWETH9(uint256 amount, address recipient) external virtual;

    function convertToWETH9(uint256 amount, address recipient) external virtual;

    function addToFullApproval(address account) external virtual;

    function removeFromFullApproval(address account) external virtual;

    /**
     * Performs a WETH9->vETH conversion with pre-deposited WETH9
     * @param amount amount to convert 
     * @param recipient recipient to credit
     */
    function approvedConvertFromWETH9(uint256 amount, address recipient) external virtual;
    /**
     * Performs a vETH->WETH9 conversion on behalf of a user. Approved contracts only.
     * @param user user to perform on behalf of
     * @param amount amount to convert
     * @param recipient recipient wallet to send to
     */
    function approvedConvertToWETH9(address user, uint256 amount, address recipient) external virtual;
    /**
     * Performs a withdrawal on behalf of a user. Approved contracts only.
     * @param user user to perform on behalf of
     * @param amount amount to withdraw
     * @param recipient recipient wallet to send to
     */
    function approvedWithdraw(address user, uint256 amount, address recipient) external virtual;

    function approvedTransferFrom(address user, uint256 amount, address recipient) external virtual;

    function transfer(address to, uint value) public virtual;


}