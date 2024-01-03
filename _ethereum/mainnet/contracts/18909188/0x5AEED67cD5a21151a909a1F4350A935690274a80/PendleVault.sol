// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Vault.sol";

/**
 * @title Dollet PendleVault contract
 * @author Dollet Team
 * @notice An implementation of the PendleVault contract.
 */
contract PendleVault is Vault {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this contract with initial values.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategy PendleStrategy contract address.
     * @param _weth WETH token contract address.
     * @param _calculations Calculations contract address.
     * @param _depositAllowedTokens Deposit allowed tokens list.
     * @param _withdrawalAllowedTokens Withdrawal allowed tokens list.
     * @param _depositLimits Deposit limits list in deposit allowed tokens.
     */
    function initialize(
        address _adminStructure,
        address _strategy,
        address _weth,
        address _calculations,
        address[] calldata _depositAllowedTokens,
        address[] calldata _withdrawalAllowedTokens,
        DepositLimit[] calldata _depositLimits
    )
        external
        initializer
    {
        _vaultInitUnchained(
            _adminStructure,
            _strategy,
            _weth,
            _calculations,
            _depositAllowedTokens,
            _withdrawalAllowedTokens,
            _depositLimits
        );
    }

    /**
     * @notice PendleVault specific implementation of the deposit.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function _deposit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        internal
        override
    {
        strategy.deposit(_user, _token, _amount, _additionalData);
    }

    /**
     * @notice PendleVault specific implementation of the withdraw.
     * @param _recipient Address of the recipient to receive tokens.
     * @param _user Address of the user who deposited.
     * @param _originalToken Address of the original token, useful on ETH deposits.
     * @param _token Address of the token to withdraw.
     * @param _wantToWithdraw Amount of want tokens to withdraw.
     * @param _maxUserWant Maximum available user want.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function _withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        bytes calldata _additionalData
    )
        internal
        override
    {
        strategy.withdraw(_recipient, _user, _originalToken, _token, _wantToWithdraw, _maxUserWant, _additionalData);
    }

    /**
     * @notice PendleVault specific implementation of the compound method that should be executed in the time of
     *         deposit.
     */
    function _depositCompound() internal virtual override {
        strategy.compound(hex"");
    }

    /**
     * @notice PendleVault specific implementation of the compound method that should be executed in the time of
     *         withdraw.
     */
    function _withdrawCompound() internal virtual override {
        strategy.compound(hex"");
    }
}
