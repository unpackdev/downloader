// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./IKCompound.sol";

/**
 * @title JITU Compound interface
 * @author KeeperDAO
 * @notice Interface for the Compound JITU plugin.
 */
interface IJITUCompound {
    /** Following functions can only be called by the owner */

    /** 
     * @notice borrow given amount of tokens from the liquidity pool.
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens 
     */ 
    function borrow(CToken _cToken, uint256 _amount) external;

    /** 
     * @notice repay given amount back to the LiquidityPool
     *
     * @param _cToken the address of the cToken
     * @param _amount the amount of underlying tokens
     */
    function repay(CToken _cToken, uint256 _amount) external payable;

    /** Following functions can only be called by a whitelisted keeper */

    /** 
     * @notice underwrite the given vault, with the given amount of
     * compound tokens.
     *
     * @param _vault the address of the compound vault
     * @param _cToken the address of the cToken
     * @param _tokens the amount of cToken
     */
    function underwrite(address _vault, CToken _cToken, uint256 _tokens) external;

    /**
     * @notice reclaim the given amount of compound tokens from the given vault 
     *
     * @param _vault the address of the compound vault
     */
    function reclaim(address _vault) external;

    /** Following functions can only be called by the vault owner */

    /**
     * @notice return the provided compound tokens from the given vault,
     * and change the protection status of the vault.
     *
     * @param _vault the address of the compound vault
     */
    function removeProtection(address _vault, bool _permanent) external;

    /**
     * @notice protect the vault when it is close to liquidation.
     *
     * @param _vault the address of the compound vault
     */
    function protect(address _vault) external;

    /**
     * @notice withdraw COMP that got accrued due to holding cTokens.
     *
     * @param _to the address of the receiver
     * @param _amount the amount of COMP tokens to be sent
     */
    function withdrawCOMP(address _to, uint256 _amount) external;

    /**
     * @notice Allows a user to migrate an existing compound position.
     * @dev The user has to approve all the cTokens (he uses as collateral)
     * to his hiding vault contract before calling this function, otherwise 
     * this contract will be reverted.
     * 
     * @param _tokens the amount that needs to be flash lent (should be 
     * greater than the value of the compund position).
     */
    function migrate(
        IKCompound _vault,
        address _account, 
        uint256 _tokens, 
        address[] memory _collateralMarkets, 
        address[] memory _debtMarkets
    ) external;

    /** Following function can only be called by a whitelisted keeper */

    /**
     * @notice preempt a liquidation without considering the buffer provided by JITU
     *
     * @param _vault the address of the compound vault
     * @param _cTokenRepaid the address of the compound token that needs to be repaid
     * @param _repayAmount the amount of the token that needs to be repaid
     * @param _cTokenCollateral the compound token that the user would receive for repaying the
     * loan
     *
     * @return seized token amount
     */
    function preempt(
        address _vault, 
        CToken _cTokenRepaid, 
        uint _repayAmount, 
        CToken _cTokenCollateral
    ) external payable returns (uint256);
}