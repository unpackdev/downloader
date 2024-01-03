// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IAdminStructure.sol";
import "./IStrategyHelper.sol";
import "./ICalculations.sol";
import "./IFeeManager.sol";
import "./StrategyErrors.sol";
import "./IStrategy.sol";
import "./AddressUtils.sol";
import "./IVault.sol";
import "./ERC20Lib.sol";
import "./IWETH.sol";

/**
 * @title Dollet Strategy contract
 * @author Dollet Team
 * @notice Abstract Strategy contract. All strategies should inherit from it because it contains the common logic for
 *         all strategies.
 */
abstract contract Strategy is Initializable, ReentrancyGuardUpgradeable, IStrategy {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUtils for address;

    uint16 public constant ONE_HUNDRED_PERCENTS = 10_000; // 100.00%
    uint16 public constant MAX_SLIPPAGE_TOLERANCE = 3000; // 30.00%

    mapping(address user => uint256 amount) public userWantDeposit;
    mapping(address token => uint256 minimum) public minimumToCompound;
    IAdminStructure public adminStructure;
    IStrategyHelper public strategyHelper;
    IFeeManager public feeManager;
    IVault public vault;
    IWETH public weth;
    ICalculations public calculations;
    uint256 public totalWantDeposits;
    address public want;
    uint16 public slippageTolerance;

    // Allows to receive native tokens
    receive() external payable { }

    /// @inheritdoc IStrategy
    function deposit(address _user, address _token, uint256 _amount, bytes calldata _additionalData) external {
        _onlyVault();

        uint256 _wantBefore = balance();

        _deposit(_token, _amount, _additionalData);

        uint256 _depositedWant = balance() - _wantBefore;

        totalWantDeposits += _depositedWant;
        unchecked {
            userWantDeposit[_user] += _depositedWant;
        }

        emit Deposit(_token, _amount, _user, _depositedWant);
    }

    /// @inheritdoc IStrategy
    function withdraw(
        address _recipient,
        address _user,
        address _originalToken,
        address _token,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        bytes calldata _additionalData
    )
        external
    {
        _onlyVault();

        uint256 _tokenBalanceBefore = _getTokenBalance(_token);

        _withdraw(_token, _wantToWithdraw, _additionalData);

        uint256 _withdrawalTokenOut = _getTokenBalance(_token) - _tokenBalanceBefore;
        (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDepositUsed,) =
            calculations.calculateUsedAmounts(_user, _wantToWithdraw, _maxUserWant, _withdrawalTokenOut);

        if (_wantDepositUsed != 0) {
            userWantDeposit[_user] -= _wantDepositUsed;
            unchecked {
                totalWantDeposits -= _wantDepositUsed;
            }
        }

        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.MANAGEMENT, _token, _depositUsed);
        _withdrawalTokenOut -= _chargeFees(IFeeManager.FeeType.PERFORMANCE, _token, _rewardsUsed);

        _pushTokens(_originalToken, _recipient, _withdrawalTokenOut);

        emit Withdraw(_originalToken, _withdrawalTokenOut, _recipient, _wantToWithdraw);
    }

    /// @inheritdoc IStrategy
    function compound(bytes memory _data) external nonReentrant {
        _compound(_data);
    }

    /// @inheritdoc IStrategy
    function setAdminStructure(address _adminStructure) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IStrategy
    function setVault(address _vault) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_vault);

        vault = IVault(_vault);

        emit VaultSet(_vault);
    }

    /// @inheritdoc IStrategy
    function setSlippageTolerance(uint16 _slippageTolerance) external {
        _onlySuperAdmin();

        if (_slippageTolerance > MAX_SLIPPAGE_TOLERANCE) revert StrategyErrors.SlippageToleranceTooHigh();

        slippageTolerance = _slippageTolerance;

        emit SlippageToleranceSet(_slippageTolerance);
    }

    /// @inheritdoc IStrategy
    function inCaseTokensGetStuck(address _token) external {
        _onlyAdmin();

        if (_token == want) revert StrategyErrors.WrongStuckToken();

        uint256 _amount;

        if (_token != address(0)) {
            _amount = IERC20Upgradeable(_token).balanceOf(address(this));

            ERC20Lib.push(_token, adminStructure.superAdmin(), _amount);
        } else {
            _amount = address(this).balance;

            payable(msg.sender).transfer(_amount);
        }

        emit WithdrawStuckTokens(msg.sender, _token, _amount);
    }

    /// @inheritdoc IStrategy
    function editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) external {
        _onlyAdmin();
        _editMinimumTokenCompound(_tokens, _minAmounts);
    }

    /// @inheritdoc IStrategy
    function balance() public view virtual returns (uint256);

    /**
     * @notice Initializes this Strategy contract.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategyHelper A helper contract address that is used in every strategy.
     * @param _feeManager FeeManager contract address.
     * @param _weth WETH token contract address.
     * @param _want A token address that should be deposited in the underlying protocol.
     * @param _tokensToCompound An array of the tokens to set the minimum to compound.
     * @param _minimumsToCompound An array of the minimum amounts to compound.
     */
    function _strategyInitUnchained(
        address _adminStructure,
        address _strategyHelper,
        address _feeManager,
        address _weth,
        address _want,
        address _calculations,
        address[] calldata _tokensToCompound,
        uint256[] calldata _minimumsToCompound
    )
        internal
        onlyInitializing
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_strategyHelper);
        AddressUtils.onlyContract(_feeManager);
        AddressUtils.onlyContract(_weth);
        AddressUtils.onlyContract(_want);
        AddressUtils.onlyContract(_calculations);

        adminStructure = IAdminStructure(_adminStructure);
        strategyHelper = IStrategyHelper(_strategyHelper);
        feeManager = IFeeManager(_feeManager);
        weth = IWETH(_weth);
        want = _want;
        calculations = ICalculations(_calculations);

        _editMinimumTokenCompound(_tokensToCompound, _minimumsToCompound);
    }

    /**
     * @notice Transfers ETH/ERC-20 tokens to the user.
     * @param _token A token address to transfer. Zero address for ETH.
     * @param _recipient A recipient of the tokens.
     * @param _amount An amount of tokens to transfer.
     */
    function _pushTokens(address _token, address _recipient, uint256 _amount) internal {
        if (_token == address(0)) {
            weth.withdraw(_amount);

            (bool _success,) = _recipient.call{ value: _amount }("");

            if (!_success) revert StrategyErrors.ETHTransferError();
        } else {
            ERC20Lib.push(_token, _recipient, _amount);
        }
    }

    /**
     * @notice Edits the minimum token compound amounts.
     * @param _tokens An array of token addresses to edit.
     * @param _minAmounts An array of minimum harvest amounts corresponding to the tokens.
     */
    function _editMinimumTokenCompound(address[] calldata _tokens, uint256[] calldata _minAmounts) internal {
        uint256 _tokensLength = _tokens.length;

        if (_tokensLength != _minAmounts.length) revert StrategyErrors.LengthsMismatch();

        for (uint256 _i; _i < _tokensLength;) {
            minimumToCompound[_tokens[_i]] = _minAmounts[_i];

            emit MinimumToCompoundChanged(_tokens[_i], _minAmounts[_i]);

            unchecked {
                ++_i;
            }
        }
    }

    /**
     * @notice Prototype of the `_deposit()` method that should be implemented in each strategy.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of the token to deposit.
     * @param _additionalData Encoded data which will be used in the time of deposit.
     */
    function _deposit(address _token, uint256 _amount, bytes calldata _additionalData) internal virtual;

    /**
     * @notice Prototype of the `_withdraw()` method that should be implemented in each strategy.
     * @param _tokenOut Address of the token to withdraw in.
     * @param _wantToWithdraw The want amount to withdraw.
     * @param _additionalData Encoded data which will be used in the time of withdraw.
     */
    function _withdraw(address _tokenOut, uint256 _wantToWithdraw, bytes calldata _additionalData) internal virtual;

    /**
     * @notice Prototype of the `_compound()` method that should be implemented in each strategy.
     * @param _data Encoded data to use at the time of the compound operation.
     */
    function _compound(bytes memory _data) internal virtual;

    /**
     * @notice Checks if a transaction sender is a super admin.
     */
    function _onlySuperAdmin() internal view {
        adminStructure.isValidSuperAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is an admin.
     */
    function _onlyAdmin() internal view {
        adminStructure.isValidAdmin(msg.sender);
    }

    /**
     * @notice Checks if a transaction sender is a vault contract.
     */
    function _onlyVault() internal view {
        if (msg.sender != address(vault)) revert StrategyErrors.NotVault(msg.sender);
    }

    /**
     * @notice Retrieves the balance of the specified token held by the strategy,
     * @param _token The address of the token to retrieve the balance for.
     * @return The balance of the token.
     */
    function _getTokenBalance(address _token) internal view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(this));
    }

    /**
     * @notice Calculates the minimum output amount applying a slippage tolerance percentage to the amount.
     * @param _amount The amount of tokens to use.
     * @param _slippageTolerance The slippage percentage to apply.
     * @return _result The minimum output amount.
     */
    function _getMinimumOutputAmount(
        uint256 _amount,
        uint16 _slippageTolerance
    )
        internal
        pure
        returns (uint256 _result)
    {
        return _amount - ((_amount * _slippageTolerance) / ONE_HUNDRED_PERCENTS);
    }

    /**
     * @notice Charges fees in the specified token.
     * @param _feeType The type of fee to charge.
     * @param _token The token in which to charge the fees.
     * @param _amount The amount of tokens to charge fees on.
     * @return The amount taken charged as fee.
     */
    function _chargeFees(IFeeManager.FeeType _feeType, address _token, uint256 _amount) private returns (uint256) {
        if (_amount == 0) return 0;

        IFeeManager _feeManager = feeManager;
        (address _feeRecipient, uint16 _fee) = _feeManager.fees(address(this), _feeType);

        if (_fee == 0) return 0;

        uint256 _feeAmount = (_amount * _fee) / ONE_HUNDRED_PERCENTS;

        IERC20Upgradeable(_token).safeTransfer(_feeRecipient, _feeAmount);

        emit ChargedFees(_feeType, _feeAmount, _feeRecipient, _token);

        return _feeAmount;
    }

    uint256[100] private __gap;
}
