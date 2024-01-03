// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IAdminStructure.sol";
import "./IStrategyHelper.sol";
import "./IFeeManager.sol";
import "./IVault.sol";
import "./IWETH.sol";

/**
 * @title Dollet IStrategy
 * @author Dollet Team
 * @notice Interface with all types, events, external, and public methods for the Strategy contract.
 */
interface IStrategy {
    struct MinimumToCompound {
        address token;
        uint256 minAmount;
    }

    /**
     * @notice Logs information about deposit operation.
     * @param _token A token address that was used at the time of deposit.
     * @param _amount An amount of tokens that were deposited.
     * @param _user A user address who executed a deposit operation.
     * @param _depositedWant An amount of want tokens that were deposited in the underlying protocol.
     */
    event Deposit(address _token, uint256 _amount, address _user, uint256 _depositedWant);

    /**
     * @notice Logs information about withdrawal operation.
     * @param _token A token address that was used at the time of withdrawal.
     * @param _amount An amount of tokens that were withdrawn.
     * @param _user A user address who executed a withdraw operation.
     * @param _withdrawnWant An amount of want tokens that were withdrawn from the underlying protocol.
     */
    event Withdraw(address _token, uint256 _amount, address _user, uint256 _withdrawnWant);

    /**
     * @notice Logs information about compound operation.
     * @param _amount An amount of want tokens that were compounded and deposited in the underlying protocol.
     */
    event Compounded(uint256 _amount);

    /**
     * @notice Logs information when a new Vault contract address was set.
     * @param _vault A new Vault contract address.
     */
    event VaultSet(address indexed _vault);

    /**
     * @notice Logs information about the withdrawal of stuck tokens.
     * @param _caller An address of the admin who executed the withdrawal operation.
     * @param _token An address of a token that was withdrawn.
     * @param _amount An amount of tokens that were withdrawn.
     */
    event WithdrawStuckTokens(address _caller, address _token, uint256 _amount);

    /**
     * @notice Logs information about new slippage tolerance.
     * @param _slippageTolerance A new slippage tolerance that was set.
     */
    event SlippageToleranceSet(uint16 _slippageTolerance);

    /**
     * @notice Logs information when a fee is charged.
     * @param _feeType A type of fee charged.
     * @param _feeAmount An amount of fee charged.
     * @param _feeRecipient A recipient of the charged fee.
     * @param _token The addres of the token used.
     */
    event ChargedFees(IFeeManager.FeeType _feeType, uint256 _feeAmount, address _feeRecipient, address _token);

    /**
     * @notice Logs information when the minimum amount to compound is changed.
     * @param _token The address of the token.
     * @param _minimum The new minimum amount to compound.
     */
    event MinimumToCompoundChanged(address _token, uint256 _minimum);

    /**
     * @notice Deposit to the strategy.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     */
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external;

    /**
     * @notice Withdraw from the strategy.
     * @param _recipient Address of the recipient to receive the tokens.
     * @param _user Address of the owner of the deposit (shares).
     * @param _originalToken Address of the token deposited (useful when using ETH).
     * @param _token Address of the token to withdraw.
     * @param _wantToWithdraw Amount of want tokens to withdraw from the strategy.
     * @param _maxUserWant Maximum user want tokens available to withdraw.
     * @param _additionalData Additional encoded data for the withdrawal.
     */
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        bytes calldata _additionalData
    )
        external;

    /**
     * @notice Executes a compound on the strategy.
     * @param _data Encoded data which will be used in the time of compound.
     */
    function compound(bytes calldata _data) external;

    /**
     * @notice Allows the super admin to change the admin structure.
     * @param _adminStructure Admin structure contract address.
     */
    function setAdminStructure(address _adminStructure) external;

    /**
     * @notice Sets a Vault contract address. Only super admin is able to set a new Vault address.
     * @param _vault A new Vault contract address.
     */
    function setVault(address _vault) external;

    /**
     * @notice Sets a new slippage tolerance by super admin.
     * @param _slippageTolerance A new slippage tolerance (with 2 decimals).
     */
    function setSlippageTolerance(uint16 _slippageTolerance) external;

    /**
     * @notice Handles the case where tokens get stuck in the contract. Allows the admin to send the tokens to the super
     *         admin.
     * @param _token The address of the stuck token.
     */
    function inCaseTokensGetStuck(address _token) external;

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external;

    /**
     * @notice Returns the balance of the strategy held in the strategy or underlying protocols.
     * @return The balance of the strategy.
     */
    function balance() external view returns (uint256);

    /**
     * @notice Returns the total deposited want token amount by a user.
     * @param _user A user address to get the total deposited want token amount for.
     * @return The total deposited want token amount by a user.
     */
    function userWantDeposit(address _user) external view returns (uint256);

    /**
     * @notice Returns the minimum amount required to execute reinvestment for a specific token.
     * @param _token The address of the token.
     * @return The minimum amount required for reinvestment.
     */
    function minimumToCompound(address _token) external view returns (uint256);

    /**
     * @notice Returns AdminStructure contract address.
     * @return AdminStructure contract address.
     */
    function adminStructure() external view returns (IAdminStructure);

    /**
     * @notice Returns StrategyHelper contract address.
     * @return StrategyHelper contract address.
     */
    function strategyHelper() external view returns (IStrategyHelper);

    /**
     * @notice Returns FeeManager contract address.
     * @return FeeManager contract address.
     */
    function feeManager() external view returns (IFeeManager);

    /**
     * @notice Returns Vault contract address.
     * @return Vault contract address.
     */
    function vault() external view returns (IVault);

    /**
     * @notice Returns WETH token contract address.
     * @return WETH token contract address.
     */
    function weth() external view returns (IWETH);

    /**
     * @notice Returns total deposited want token amount.
     * @return Total deposited want token amount.
     */
    function totalWantDeposits() external view returns (uint256);

    /**
     * @notice Returns the token address that should be deposited in the underlying protocol.
     * @return The token address that should be deposited in the underlying protocol.
     */
    function want() external view returns (address);

    /**
     * @notice Returns a default slippage tolerance percentage (with 2 decimals).
     * @return A default slippage tolerance percentage (with 2 decimals).
     */
    function slippageTolerance() external view returns (uint16);

    /**
     * @notice Returns maximum slipage tolerance value (with two decimals).
     * @return Maximum slipage tolerance value (with two decimals).
     */
    function MAX_SLIPPAGE_TOLERANCE() external view returns (uint16);

    /**
     * @notice Returns 100% value (with two decimals).
     * @return 100% value (with two decimals).
     */
    function ONE_HUNDRED_PERCENTS() external view returns (uint16);
}
