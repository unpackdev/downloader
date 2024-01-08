// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./Compound.sol";

/**
 * @title KCompound Interface
 * @author KeeperDAO
 * @notice Interface for the KCompound hiding vault plugin.
 */
interface IKCompound {
    /**
     * @notice Calculate the given cToken's balance of this contract.
     *
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOf(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the given cToken's underlying token's balance 
     * of this contract.
     * 
     * @param _cToken The address of the cToken contract.
     *
     * @return Outstanding balance of the given token.
     */
    function compound_balanceOfUnderlying(CToken _cToken) external returns (uint256);
    
    /**
     * @notice Calculate the unhealth of this account.
     * @dev    unhealth of an account starts from 0, if a position 
     *         has an unhealth of more than 100 then the position
     *         is liquidatable.
     *
     * @return Unhealth of this account.
     */
    function compound_unhealth() external view returns (uint256);

    /**
     * @notice Checks whether given position is underwritten.
     */
    function compound_isUnderwritten() external view returns (bool);

    /** Following functions can only be called by the owner */

    /** 
     * @notice Deposit funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_deposit(CToken _cToken, uint256 _amount) external payable;

    /**
     * @notice Repay funds to the Compound Protocol.
     *
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_repay(CToken _cToken, uint256 _amount) external payable;

    /** 
     * @notice Withdraw funds from the Compound Protocol.
     *
     * @param _to The address of the receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The amount to be withdrawn.
     */
    function compound_withdraw(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice Borrow funds from the Compound Protocol.
     *
     * @param _to The address of the amount receiver.
     * @param _cToken The address of the cToken contract.
     * @param _amount The value of partial loan.
     */
    function compound_borrow(address payable _to, CToken _cToken, uint256 _amount) external;

    /**
     * @notice The user can enter new markets by passing them here.
     */
    function compound_enterMarkets(address[] memory _cTokens) external;

    /** Following functions can only be called by JITU */

    /**
     * @notice Allows a user to migrate an existing compound position.
     * @dev The user has to approve all the cTokens (he owns) to this 
     * contract before calling this function, otherwise this contract will
     * be reverted.
     * @param  _amount The amount that needs to be flash lent (should be 
     *                 greater than the value of the compund position).
     */
    function compound_migrate(
        address account, 
        uint256 _amount, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external;

    /**
     * @notice Prempt liquidation for positions underwater if the provided 
     *         buffer is not considered on the Compound Protocol.
     *
     * @param _cTokenRepay The cToken for which the loan is being repaid for.
     * @param _repayAmount The amount that should be repaid.
     * @param _cTokenCollateral The collateral cToken address.
     */
    function compound_preempt(
        address _liquidator, 
        CToken _cTokenRepay, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable returns (uint256);

    /**
     * @notice Allows JITU to underwrite this contract, by providing cTokens.
     *
     * @param _cToken The address of the cToken.
     * @param _tokens The amount of the cToken tokens.
     */
    function compound_underwrite(CToken _cToken, uint256 _tokens) external payable;

    /**
     * @notice Allows JITU to reclaim the cTokens it provided.
     */
    function compound_reclaim() external; 
}