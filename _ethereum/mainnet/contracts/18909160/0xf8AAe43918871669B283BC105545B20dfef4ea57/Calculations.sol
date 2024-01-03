// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./Initializable.sol";
import "./IAdminStructure.sol";
import "./IStrategyHelper.sol";
import "./CalculationsErrors.sol";
import "./ICalculations.sol";
import "./IFeeManager.sol";
import "./IStrategy.sol";
import "./AddressUtils.sol";

/**
 * @title Dollet Calculations contract
 * @author Dollet Team
 * @notice Contract for doing strategy calculations.
 */
abstract contract Calculations is Initializable, ICalculations {
    using AddressUtils for address;

    uint16 public constant ONE_HUNDRED_PERCENTS = 10_000; // 100.00%

    IAdminStructure public adminStructure;
    IStrategyHelper public strategyHelper;
    address public strategy;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc ICalculations
    function setStrategyValues(address _strategy) external {
        _onlySuperAdmin();

        AddressUtils.onlyContract(_strategy);

        strategy = _strategy;

        emit StrategySet(_strategy);

        strategyHelper = IStrategy(_strategy).strategyHelper();

        emit StrategyHelperSet(address(strategyHelper));
    }

    /// @inheritdoc ICalculations
    function userDeposit(address _user, address _token) external view returns (uint256) {
        return _userDeposit(_user, _token);
    }

    /// @inheritdoc ICalculations
    function totalDeposits(address _token) external view returns (uint256) {
        return _totalDeposits(_token);
    }

    /// @inheritdoc ICalculations
    function estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes memory _rewardData
    )
        external
        view
        returns (uint256)
    {
        return _estimateWantAfterCompound(_slippageTolerance, _rewardData);
    }

    /// @inheritdoc ICalculations
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _additionalData
    )
        external
        view
        returns (uint256)
    {
        return _estimateDeposit(_token, _amount, _slippageTolerance, _additionalData);
    }

    /// @inheritdoc ICalculations
    function estimateWantToToken(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        external
        view
        returns (uint256 _amountInToken)
    {
        return _estimateWantToToken(_token, _amount, _slippageTolerance);
    }

    /// @inheritdoc ICalculations
    function getWithdrawableAmount(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        address _token,
        uint16 _slippageTolerance
    )
        external
        view
        returns (WithdrawalEstimation memory)
    {
        address _strategy = strategy;
        IFeeManager _feeManager = IStrategy(_strategy).feeManager();
        (uint256 _wantDeposit, uint256 _wantRewards) =
            calculateWithdrawalDistribution(_user, _wantToWithdraw, _maxUserWant);
        uint256 _wantDepositAfterFee;
        uint256 _wantRewardsAfterFee;

        if (_wantDeposit != 0) {
            (, uint16 _fee) = _feeManager.fees(_strategy, IFeeManager.FeeType.MANAGEMENT);

            _wantDepositAfterFee = _wantDeposit - ((_wantDeposit * _fee) / ONE_HUNDRED_PERCENTS);
        }

        if (_wantRewards != 0) {
            (, uint16 _fee) = _feeManager.fees(_strategy, IFeeManager.FeeType.PERFORMANCE);

            _wantRewardsAfterFee = _wantRewards - ((_wantRewards * _fee) / ONE_HUNDRED_PERCENTS);
        }

        return WithdrawalEstimation({
            wantDeposit: _wantDeposit,
            wantRewards: _wantRewards,
            wantDepositAfterFee: _wantDepositAfterFee,
            wantRewardsAfterFee: _wantRewardsAfterFee,
            depositInToken: _estimateWantToToken(_token, _wantDepositAfterFee, _slippageTolerance),
            rewardsInToken: _estimateWantToToken(_token, _wantRewardsAfterFee, _slippageTolerance)
        });
    }

    /// @inheritdoc ICalculations
    function calculateWithdrawalDistribution(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant
    )
        public
        view
        returns (uint256 _wantDeposit, uint256 _wantRewards)
    {
        if (_wantToWithdraw > _maxUserWant) revert CalculationsErrors.WantToWithdrawIsTooHigh();

        address _strategy = strategy;
        // Calculates the amount for a specific user or for the entire strategy
        uint256 _userDeposited =
            _user == _strategy ? IStrategy(_strategy).totalWantDeposits() : IStrategy(_strategy).userWantDeposit(_user);

        if (_maxUserWant > _userDeposited) {
            uint256 _rewards = _maxUserWant - _userDeposited;

            if (_rewards >= _wantToWithdraw) {
                _wantRewards = _wantToWithdraw;
            } else {
                _wantRewards = _rewards;
                _wantDeposit = _wantToWithdraw - _rewards;
            }
        } else {
            _wantDeposit = _wantToWithdraw;
        }
    }

    /// @inheritdoc ICalculations
    function calculateUsedAmounts(
        address _user,
        uint256 _wantToWithdraw,
        uint256 _maxUserWant,
        uint256 _withdrawalTokenOut
    )
        public
        view
        returns (uint256 _depositUsed, uint256 _rewardsUsed, uint256 _wantDeposit, uint256 _wantRewards)
    {
        (_wantDeposit, _wantRewards) = calculateWithdrawalDistribution(_user, _wantToWithdraw, _maxUserWant);

        uint256 _wantTotal = _wantDeposit + _wantRewards;
        uint256 _depositPercentage = _wantTotal == 0 ? 0 : (_wantDeposit * 1e18) / _wantTotal;

        _depositUsed = (_withdrawalTokenOut * _depositPercentage) / 1e18;
        _rewardsUsed = _withdrawalTokenOut - _depositUsed;
    }

    /// @inheritdoc ICalculations
    function getMinimumOutputAmount(
        uint256 _amount,
        uint256 _slippageTolerance
    )
        public
        pure
        returns (uint256 _result)
    {
        return _amount - ((_amount * _slippageTolerance) / ONE_HUNDRED_PERCENTS);
    }

    /**
     * @notice Initializes this Calculations contract.
     * @param _adminStructure AdminStructure contract address.
     */
    function _calculationsInitUnchained(address _adminStructure) internal onlyInitializing {
        AddressUtils.onlyContract(_adminStructure);

        adminStructure = IAdminStructure(_adminStructure);
    }

    /**
     * @notice Returns the amount of the user deposit in terms of the token specified. Must be implemented in each
     *         child Calculations contract.
     * @param _user The address of the user to get the deposit value for.
     * @param _token The address of the token to use.
     * @return The estimated user deposit in the specified token.
     */
    function _userDeposit(address _user, address _token) internal view virtual returns (uint256);

    /**
     * @notice Returns the amount of the total deposits in terms of the token specified. Must be implemented in each
     *         child Calculations contract.
     * @param _token The address of the token to use.
     * @return The amount of total deposit in the specified token.
     */
    function _totalDeposits(address _token) internal view virtual returns (uint256);

    /**
     * @notice Returns the balance of the want token of the strategy after making a compound. Must be implemented in
     *         each child Calculations contract.
     * @param _slippageTolerance Slippage to use for the calculation.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return The want token balance after a compound.
     */
    function _estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes memory _rewardData
    )
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Returns the expected amount of want tokens to be obtained from a deposit. Must be implemented in each
     *         child Calculations contract.
     * @param _token The token to be used for deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param _slippageTolerance The slippage tolerance for the deposit.
     * @param _data Extra information used to estimate.
     * @return The minimum want tokens expected to be obtained from the deposit.
     */
    function _estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata _data
    )
        internal
        view
        virtual
        returns (uint256);

    /**
     * @notice Estimates an `_amount` of want tokens in the `_token`. Must be implemented in each child Calculations
     *         contract.
     * @param _token A token address to use for the estimation.
     * @param _amount An number of want tokens to use for the estimation.
     * @param _slippageTolerance A slippage tolerance to apply at the time of the estimation.
     * @return A number of tokens in the `_token` that is equivalent to the `_amount` in the want token.
     */
    function _estimateWantToToken(
        address _token,
        uint256 _amount,
        uint16 _slippageTolerance
    )
        internal
        view
        virtual
        returns (uint256);

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

    uint256[50] private __gap;
}
