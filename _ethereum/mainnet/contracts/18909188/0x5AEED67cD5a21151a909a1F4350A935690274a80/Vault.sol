// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./IAdminStructure.sol";
import "./ICalculations.sol";
import "./ERC20Lib.sol";
import "./IStrategy.sol";
import "./AddressUtils.sol";
import "./VaultErrors.sol";
import "./IVault.sol";
import "./IWETH.sol";

/**
 * @title Dollet Vault contract
 * @author Dollet Team
 * @notice Abstract Vault contract. All Vaults should inherit from it because it contains the common logic for all
 *         Vaults.
 */
abstract contract Vault is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IVault {
    using AddressUtils for address;

    uint256 private constant _ALLOWED = 1;

    mapping(address user => uint256 amount) public userShares;
    mapping(address token => uint256 isAllowed) public depositAllowedTokens;
    mapping(address token => uint256 isAllowed) public withdrawalAllowedTokens;
    mapping(address token => DepositLimit limit) public depositLimit;
    address[] public listDepositAllowedTokens;
    address[] public listWithdrawalAllowedTokens;
    IAdminStructure public adminStructure;
    ICalculations public calculations;
    IStrategy public strategy;
    IWETH public weth;
    uint256 public totalShares;

    /// @inheritdoc IVault
    function deposit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData
    )
        external
        payable
        whenNotPaused
        nonReentrant
    {
        Signature memory _signature;

        _processDeposit(_user, _token, _amount, _additionalData, _signature);
    }

    /// @inheritdoc IVault
    function depositWithPermit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData,
        Signature calldata _signature
    )
        external
        whenNotPaused
        nonReentrant
    {
        _processDeposit(_user, _token, _amount, _additionalData, _signature);
    }

    /// @inheritdoc IVault
    function withdraw(
        address _recipient,
        address _token,
        uint256 _amountShares,
        bytes calldata _additionalData
    )
        external
        nonReentrant
    {
        if (withdrawalAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedWithdrawalToken(_token);

        uint256 _userShares = userShares[msg.sender];

        if (_userShares < _amountShares) revert VaultErrors.InsufficientAmount();

        _withdrawCompound();

        address _originalToken = _token;

        _token = _token == address(0) ? address(weth) : _token;

        _withdraw(
            _recipient,
            msg.sender,
            _originalToken,
            _token,
            sharesToWant(_amountShares),
            sharesToWant(_userShares),
            _additionalData
        );

        unchecked {
            userShares[msg.sender] -= _amountShares;
            totalShares -= _amountShares;
        }
    }

    /// @inheritdoc IVault
    function setAdminStructure(address _adminStructure) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /// @inheritdoc IVault
    function editDepositAllowedTokens(address _token, uint256 _status) external {
        _onlySuperAdmin();
        _editAllowedTokens(depositAllowedTokens, listDepositAllowedTokens, _token, _status, TokenType.Deposit);
    }

    /// @inheritdoc IVault
    function editWithdrawalAllowedTokens(address _token, uint256 _status) external {
        _onlySuperAdmin();

        if (listWithdrawalAllowedTokens.length == 1 && _status != _ALLOWED) {
            revert VaultErrors.MustKeepOneToken(TokenType.Withdrawal);
        }

        _editAllowedTokens(withdrawalAllowedTokens, listWithdrawalAllowedTokens, _token, _status, TokenType.Withdrawal);
    }

    /// @inheritdoc IVault
    function editDepositLimit(DepositLimit[] calldata _depositLimits) external {
        _onlyAdmin();
        _setDepositLimits(_depositLimits);
    }

    /// @inheritdoc IVault
    function togglePause() external {
        _onlyAdmin();

        bool _isPaused = paused();

        if (_isPaused) _unpause();
        else _pause();

        emit PauseStatusChanged(!_isPaused);
    }

    /// @inheritdoc IVault
    function inCaseTokensGetStuck(address _token) external {
        _onlyAdmin();

        if (_token == address(strategy.want())) revert VaultErrors.WithdrawStuckWrongToken();

        uint256 _amount = IERC20Upgradeable(_token).balanceOf(address(this));

        ERC20Lib.push(_token, adminStructure.superAdmin(), _amount);

        emit WithdrawStuckTokens(msg.sender, _token, _amount);
    }

    /// @inheritdoc IVault
    function getListAllowedTokens(TokenType _tokenType) external view returns (address[] memory) {
        if (_tokenType == TokenType.Deposit) return listDepositAllowedTokens;
        else return listWithdrawalAllowedTokens;
    }

    /// @inheritdoc IVault
    function wantToShares(uint256 _wantAmount) external view returns (uint256) {
        uint256 _totalShares = totalShares;

        if (_totalShares == 0) return _wantAmount;

        return (_wantAmount * _totalShares) / balance();
    }

    /// @inheritdoc IVault
    function userDeposit(address _user, address _token) external view returns (uint256) {
        if (depositAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedDepositToken(_token);
        if (_token == address(0)) _token = address(weth);

        return calculations.userDeposit(_user, _token);
    }

    /// @inheritdoc IVault
    function totalDeposits(address _token) external view returns (uint256) {
        if (depositAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedDepositToken(_token);
        if (_token == address(0)) _token = address(weth);

        return calculations.totalDeposits(_token);
    }

    /// @inheritdoc IVault
    function getUserMaxWant(address _user) external view returns (uint256) {
        return sharesToWant(userShares[_user]);
    }

    /// @inheritdoc IVault
    function calculateSharesToWithdraw(
        address _user,
        uint256 _wantToWithdraw,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        bool _withdrawAll
    )
        external
        view
        returns (uint256 _sharesToWithdraw)
    {
        uint256 _userShares = userShares[_user];

        if (_withdrawAll) return _userShares;
        if (_wantToWithdraw == 0) return 0;

        ICalculations.WithdrawalEstimation memory _withdrawalEstimation =
            _estimateWithdrawal(_user, _slippageTolerance, _addionalData, address(0));
        uint256 _wantDeposit = _withdrawalEstimation.wantDeposit;
        uint256 _wantRewards = _withdrawalEstimation.wantRewards;
        uint256 _wantDepositAfterFee = _withdrawalEstimation.wantDepositAfterFee;
        uint256 _wantRewardsAfterFee = _withdrawalEstimation.wantRewardsAfterFee;

        if (_wantDepositAfterFee + _wantRewardsAfterFee < _wantToWithdraw) revert VaultErrors.WantToWithdrawTooHigh();

        uint256 _wantRemaining;
        uint256 _wantRewardsAfterFeePercentage;

        if (_wantToWithdraw >= _wantRewardsAfterFee) {
            // Withdraw full rewards
            _wantRewardsAfterFeePercentage = 1e18;
            _wantRemaining = _wantToWithdraw - _wantRewardsAfterFee;
        } else {
            // Withdraw some rewards
            _wantRewardsAfterFeePercentage = (_wantToWithdraw * 1e18) / _wantRewardsAfterFee;
        }

        uint256 _wantUsed = (_wantRewards * _wantRewardsAfterFeePercentage) / 1e18;

        if (_wantRemaining != 0) {
            uint256 _wantDepositAfterFeePercentage = (_wantRemaining * 1e18) / _wantDepositAfterFee;

            _wantUsed += (_wantDeposit * _wantDepositAfterFeePercentage) / 1e18;
        }

        uint256 _totalWant = _wantDeposit + _wantRewards;
        uint256 _totalPercentageUsed = (_wantUsed * 1e18) / (_totalWant);

        return (_userShares * _totalPercentageUsed) / 1e18;
    }

    /// @inheritdoc IVault
    function getDepositLimit(address _token) external view returns (DepositLimit memory) {
        return depositLimit[_token];
    }

    /// @inheritdoc IVault
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance,
        bytes calldata _data,
        bytes calldata _addionalData
    )
        external
        view
        returns (uint256 _amountShares, uint256 _amountWant)
    {
        if (depositAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedDepositToken(_token);
        if (_token == address(0)) _token = address(weth);

        ICalculations _calculations = calculations;

        uint256 _before = _calculations.estimateWantAfterCompound(_slippageTolerance, _addionalData);

        _amountWant = _calculations.estimateDeposit(_token, _amount, _slippageTolerance, _data);

        uint256 _totalShares = totalShares;

        if (_totalShares == 0) _amountShares = _amountWant;
        else _amountShares = _amountWant * _totalShares / _before;
    }

    /// @inheritdoc IVault
    function sharesToWant(uint256 _sharesAmount) public view returns (uint256) {
        return (_sharesAmount * balance()) / totalShares;
    }

    /// @inheritdoc IVault
    function sharesToWantAfterCompound(
        uint256 _sharesAmount,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        public
        view
        returns (uint256)
    {
        return (_sharesAmount * calculations.estimateWantAfterCompound(_slippageTolerance, _addionalData)) / totalShares;
    }

    /// @inheritdoc IVault
    function getUserMaxWantWithCompound(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData
    )
        public
        view
        returns (uint256)
    {
        // Calculates the amount for a specific user or for the entire strategy
        uint256 _userShares = _user == address(strategy) ? totalShares : userShares[_user];

        if (_userShares == 0) return 0;

        return sharesToWantAfterCompound(_userShares, _slippageTolerance, _addionalData);
    }

    /// @inheritdoc IVault
    function estimateWithdrawal(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        address _token
    )
        public
        view
        returns (ICalculations.WithdrawalEstimation memory)
    {
        if (withdrawalAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedWithdrawalToken(_token);
        if (_token == address(0)) _token = address(weth);

        return _estimateWithdrawal(_user, _slippageTolerance, _addionalData, _token);
    }

    /// @inheritdoc IVault
    function balance() public view returns (uint256) {
        return strategy.balance();
    }

    /**
     * @notice Initializes this Vault contract.
     * @param _adminStructure AdminStructure contract address.
     * @param _strategy Strategy contract address.
     * @param _weth WETH token contract address.
     * @param _calculations Calculations contract address.
     * @param _depositAllowedTokens A list of tokens that will be allowed for deposits.
     * @param _withdrawalAllowedTokens A list of tokens that will be allowed for withdrawals.
     */
    function _vaultInitUnchained(
        address _adminStructure,
        address _strategy,
        address _weth,
        address _calculations,
        address[] calldata _depositAllowedTokens,
        address[] calldata _withdrawalAllowedTokens,
        DepositLimit[] calldata _depositLimits
    )
        internal
        onlyInitializing
    {
        AddressUtils.onlyContract(_adminStructure);
        AddressUtils.onlyContract(_strategy);
        AddressUtils.onlyContract(_weth);
        AddressUtils.onlyContract(_calculations);

        adminStructure = IAdminStructure(_adminStructure);
        strategy = IStrategy(_strategy);
        weth = IWETH(_weth);
        calculations = ICalculations(_calculations);

        uint256 _depositAllowedTokensLength = _depositAllowedTokens.length;
        uint256 _withdrawalAllowedTokensLength = _withdrawalAllowedTokens.length;

        if (_depositAllowedTokensLength == 0) revert VaultErrors.WrongDepositAllowedTokensCount();
        if (_withdrawalAllowedTokensLength == 0) revert VaultErrors.WrongWithdrawalAllowedTokensCount();

        for (uint256 _i; _i < _depositAllowedTokensLength;) {
            AddressUtils.onlyTokenContract(_depositAllowedTokens[_i]);
            if (depositAllowedTokens[_depositAllowedTokens[_i]] == _ALLOWED) {
                revert VaultErrors.DuplicateDepositAllowedToken();
            }
            depositAllowedTokens[_depositAllowedTokens[_i]] = _ALLOWED;
            listDepositAllowedTokens.push(_depositAllowedTokens[_i]);

            unchecked {
                ++_i;
            }
        }

        for (uint256 _i; _i < _withdrawalAllowedTokensLength;) {
            AddressUtils.onlyTokenContract(_withdrawalAllowedTokens[_i]);
            if (withdrawalAllowedTokens[_withdrawalAllowedTokens[_i]] == _ALLOWED) {
                revert VaultErrors.DuplicateWithdrawalAllowedToken();
            }
            withdrawalAllowedTokens[_withdrawalAllowedTokens[_i]] = _ALLOWED;
            listWithdrawalAllowedTokens.push(_withdrawalAllowedTokens[_i]);

            unchecked {
                ++_i;
            }
        }

        _setDepositLimits(_depositLimits);
    }

    /**
     * @notice Validates if the amount of native tokens attached to the transaction is valid. Then converts ETH to WETH
     *         and transfers it to the strategy contract.
     * @param _amount An amount of ETH tokens to validate and to convert to WETH.
     */
    function _pullNative(uint256 _amount) internal {
        if (msg.value != _amount) revert VaultErrors.ValueAndAmountMismatch();

        weth.deposit{ value: _amount }();
        ERC20Lib.push(address(weth), address(strategy), _amount);
    }

    /**
     * @notice Edits a specified list of allowed tokens.
     * @param allowedTokens A mapping of allowed tokens to modify.
     * @param listAllowedTokens A list of allowed tokens to modify.
     * @param _token A token to allow/disallow.
     * @param _status An indicator (true or false) that allows/disallows specified token.
     * @param _tokenType A type of the token to allow/disallow.
     */
    function _editAllowedTokens(
        mapping(address => uint256) storage allowedTokens,
        address[] storage listAllowedTokens,
        address _token,
        uint256 _status,
        TokenType _tokenType
    )
        internal
    {
        address[] memory _tokensList = listAllowedTokens;
        uint256 _tokensLength = _tokensList.length;

        if (_status > _ALLOWED) revert VaultErrors.InvalidTokenStatus();
        if (_status == allowedTokens[_token]) revert VaultErrors.TokenWontChange(_tokenType, _token);

        if (_status == _ALLOWED) {
            allowedTokens[_token] = _ALLOWED;
            listAllowedTokens.push(_token);
        } else {
            for (uint256 _i; _i < _tokensLength;) {
                if (_token != _tokensList[_i]) {
                    unchecked {
                        ++_i;
                    }

                    continue;
                }

                delete allowedTokens[_token];

                listAllowedTokens[_i] = _tokensList[_tokensLength - 1];
                listAllowedTokens.pop();

                unchecked {
                    ++_i;
                }

                break;
            }
        }

        emit TokenStatusChanged(_tokenType, _token, _status);
    }

    /**
     * @notice Prototype of the _deposit method that should be implemented in each vault.
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
        virtual;

    /**
     * @notice Prototype of the _withdraw method that should be implemented in each vault.
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
        virtual;

    /**
     * @notice Prototype of the _depositCompound method that should be implemented in each vault.
     */
    function _depositCompound() internal virtual;

    /**
     * @notice Prototype of the _withdrawCompound method that should be implemented in each vault.
     */
    function _withdrawCompound() internal virtual;

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
     * @notice Internal method to process deposits.
     * @param _user Address of the user providing the deposit tokens.
     * @param _token Address of the token to deposit.
     * @param _amount Amount of tokens to deposit.
     * @param _additionalData Additional encoded data for the deposit.
     * @param _signature Signature to allow deposits with a permit.
     */
    function _processDeposit(
        address _user,
        address _token,
        uint256 _amount,
        bytes calldata _additionalData,
        Signature memory _signature
    )
        private
    {
        if (depositAllowedTokens[_token] != _ALLOWED) revert VaultErrors.NotAllowedDepositToken(_token);

        _depositCompound();

        if (depositLimit[_token].minAmount > _amount) revert VaultErrors.InvalidDepositAmount(_token, _amount);

        IStrategy _strategy = strategy;

        if (_signature.r != bytes32(0)) {
            ERC20Lib.pullPermit(_token, msg.sender, address(_strategy), _amount, _signature);
        } else {
            if (_token == address(0)) _pullNative(_amount);
            else ERC20Lib.pull(_token, msg.sender, address(_strategy), _amount);
        }

        uint256 _before = balance();

        _deposit(_user, _token == address(0) ? address(weth) : _token, _amount, _additionalData);

        uint256 _provided = balance() - _before;
        uint256 _shares = _provided;
        uint256 _totalShares = totalShares;

        if (_totalShares != 0) _shares = (_provided * _totalShares) / _before;

        totalShares += _shares;
        unchecked {
            userShares[_user] += _shares;
        }
    }

    /**
     * @notice Edits the deposit limits for specific tokens.
     * @param _depositLimits The array of DepositLimit structs representing the new deposit limits.
     */
    function _setDepositLimits(DepositLimit[] calldata _depositLimits) private {
        uint256 _depositLimitsLength = _depositLimits.length;

        for (uint256 _i; _i < _depositLimitsLength;) {
            if (_depositLimits[_i].minAmount == 0) revert VaultErrors.ZeroMinDepositAmount();
            if (depositAllowedTokens[_depositLimits[_i].token] != _ALLOWED) {
                revert VaultErrors.NotAllowedDepositToken(_depositLimits[_i].token);
            }

            emit DepositLimitsSet(depositLimit[_depositLimits[_i].token], _depositLimits[_i]);

            depositLimit[_depositLimits[_i].token] = _depositLimits[_i];

            unchecked {
                ++_i;
            }
        }
    }

    /**
     * @notice Calculates the maximum withdrawable amounts in the specified token.
     * @param _user The user to be analyzed.
     * @param _slippageTolerance The slippage tolerance for the compounding.
     * @param _addionalData Encoded bytes with information about the reward tokens.
     * @param _token The token to use for the withdrawal.
     * @return WithdrawalEstimation a struct including the data about the withdrawal:
     * wantDepositUsed Portion of the total want tokens that belongs to the deposit of the user.
     * wantRewardsUsed Portion of the total want tokens that belongs to the rewards of the user.
     * wantDepositAfterFee Portion of the total want tokens after fee that belongs to the deposit of the user.
     * wantRewardsAfterFee Portion of the total want tokens after fee that belongs to the rewards of the user.
     * depositInToken Deposit amount valued in token.
     * rewardsInToken Deposit amount valued in token.
     */
    function _estimateWithdrawal(
        address _user,
        uint16 _slippageTolerance,
        bytes calldata _addionalData,
        address _token
    )
        private
        view
        returns (ICalculations.WithdrawalEstimation memory)
    {
        uint256 _maxUserWantWithCompound = getUserMaxWantWithCompound(_user, _slippageTolerance, _addionalData);

        return calculations.getWithdrawableAmount(
            _user, _maxUserWantWithCompound, _maxUserWantWithCompound, _token, _slippageTolerance
        );
    }

    uint256[100] private __gap;
}
