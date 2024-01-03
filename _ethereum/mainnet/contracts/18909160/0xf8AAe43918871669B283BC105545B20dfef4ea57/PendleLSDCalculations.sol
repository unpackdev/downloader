// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "./IERC20Upgradeable.sol";
import "./PendleLpOracleLib.sol";
import "./IPendleCalculations.sol";
import "./Initializable.sol";
import "./IPendleStrategy.sol";
import "./IStrategyHelper.sol";
import "./CalculationsErrors.sol";
import "./Calculations.sol";
import "./IStrategy.sol";

/**
 * @title Dollet PendleLSDCalculations contract
 * @author Dollet Team
 * @notice Contract for doing PendleLSDStrategy calculations.
 */
contract PendleLSDCalculations is Calculations, IPendleCalculations {
    using PendleLpOracleLib for IPMarket;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes this PendleLSDCalculations contract.
     * @param _adminStructure AdminStructure contraxct address.
     */
    function initialize(address _adminStructure) external initializer {
        _calculationsInitUnchained(_adminStructure);
    }

    /// @inheritdoc IPendleCalculations
    function getPendingToCompound(bytes memory _rewardData)
        public
        view
        returns (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        )
    {
        (_rewardTokens, _rewardAmounts) = abi.decode(_rewardData, (address[], uint256[]));
        uint256 _rewardTokensLength = _rewardTokens.length;

        if (_rewardTokensLength != _rewardAmounts.length) revert CalculationsErrors.LengthsMismatch();

        address _strategy = strategy;

        _enoughRewards = new bool[](_rewardTokensLength);

        for (uint256 _i; _i < _rewardTokensLength;) {
            _rewardAmounts[_i] += IERC20Upgradeable(_rewardTokens[_i]).balanceOf(_strategy);
            _enoughRewards[_i] = _rewardAmounts[_i] >= IStrategy(_strategy).minimumToCompound(_rewardTokens[_i]);

            if (_enoughRewards[_i]) _atLeastOne = true;

            unchecked {
                ++_i;
            }
        }
    }

    /// @inheritdoc IPendleCalculations
    function convertTargetToWant(uint256 _amountTarget) public view returns (uint256) {
        IPendleStrategy _strategy = IPendleStrategy(strategy);
        uint256 _lpToAssetRate = IPMarket(address(_strategy.pendleMarket())).getLpToAssetRate(_strategy.twapPeriod());

        return _lpToAssetRate == 0 ? 0 : _amountTarget * 1e18 / _lpToAssetRate;
    }

    /// @inheritdoc IPendleCalculations
    function convertWantToTarget(uint256 _amountWant) public view returns (uint256) {
        IPendleStrategy _strategy = IPendleStrategy(strategy);

        return IPMarket(address(_strategy.pendleMarket())).getLpToAssetRate(_strategy.twapPeriod()) * _amountWant / 1e18;
    }

    /**
     * @notice Calculates the amount of the user deposit in terms of the specified token.
     * @param _user The address of the user to calculate the deposit amount for.
     * @param _token The address of the token to use.
     * @return The amount of the user deposit in the specified token.
     */
    function _userDeposit(address _user, address _token) internal view override returns (uint256) {
        address _strategy = strategy;

        return strategyHelper.convert(
            IPendleStrategy(_strategy).targetAsset(),
            _token,
            convertWantToTarget(IStrategy(_strategy).userWantDeposit(_user))
        );
    }

    /**
     * @notice Calculates the amount of the total deposits in terms of the specified token.
     * @param _token The address of the token to use.
     * @return The amount of total deposit in the specified token.
     */
    function _totalDeposits(address _token) internal view override returns (uint256) {
        address _strategy = strategy;

        return strategyHelper.convert(
            IPendleStrategy(_strategy).targetAsset(),
            _token,
            convertWantToTarget(IStrategy(_strategy).totalWantDeposits())
        );
    }

    /**
     * @notice Estimates the want balance after a compound operation.
     * @param _slippageTolerance The allowed slippage percentage to use.
     * @param _rewardData Encoded bytes with information about the reward tokens.
     * @return Returns the new want tokens amount.
     */
    function _estimateWantAfterCompound(
        uint16 _slippageTolerance,
        bytes memory _rewardData
    )
        internal
        view
        override
        returns (uint256)
    {
        (
            uint256[] memory _rewardAmounts,
            address[] memory _rewardTokens,
            bool[] memory _enoughRewards,
            bool _atLeastOne
        ) = getPendingToCompound(_rewardData);
        address _strategy = strategy;
        uint256 _wantBalance = IStrategy(_strategy).balance();

        if (!_atLeastOne) return _wantBalance;

        uint256 _rewardAmountsLength = _rewardAmounts.length;
        uint256 _totalInTargetToken;
        IStrategyHelper _strategyHelper = strategyHelper;
        address _targetAsset = IPendleStrategy(_strategy).targetAsset();

        for (uint256 _i; _i < _rewardAmountsLength;) {
            _totalInTargetToken += _enoughRewards[_i]
                ? getMinimumOutputAmount(
                    _strategyHelper.convert(_rewardTokens[_i], _targetAsset, _rewardAmounts[_i]), _slippageTolerance
                )
                : 0;

            unchecked {
                ++_i;
            }
        }

        return _wantBalance + getMinimumOutputAmount(convertTargetToWant(_totalInTargetToken), _slippageTolerance);
    }

    /**
     * @notice Returns the expected amount of want tokens to be obtained from a deposit.
     * @param _token The token to be used for deposit.
     * @param _amount The amount of tokens to be deposited.
     * @param _slippageTolerance The slippage tolerance for the deposit.
     * @return The minimum LP expected to be obtained from the deposit.
     */
    function _estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippageTolerance,
        bytes calldata
    )
        internal
        view
        override
        returns (uint256)
    {
        address _targetAsset = IPendleStrategy(strategy).targetAsset();
        uint256 _amountInTarget = strategyHelper.convert(_token, _targetAsset, _amount);

        return getMinimumOutputAmount(convertTargetToWant(_amountInTarget), _slippageTolerance);
    }

    /**
     * @notice Estimates an `_amount` of want tokens in the `_token`.
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
        override
        returns (uint256)
    {
        if (_amount == 0 || _token == address(0)) return 0;

        uint256 _targetAmount = getMinimumOutputAmount(convertWantToTarget(_amount), _slippageTolerance);

        return getMinimumOutputAmount(
            strategyHelper.convert(IPendleStrategy(strategy).targetAsset(), _token, _targetAmount), _slippageTolerance
        );
    }
}
