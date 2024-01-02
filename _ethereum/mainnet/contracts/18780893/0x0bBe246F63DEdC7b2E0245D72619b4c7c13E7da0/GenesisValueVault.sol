// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./Math.sol";
import "./SafeCast.sol";
// interfaces
import "./IGenesisValueVault.sol";
// libraries
import "./Contracts.sol";
import "./Constants.sol";
import "./RoundingUint256.sol";
import "./RoundingInt256.sol";
// mixins
import "./MixinAddressResolver.sol";
// utils
import "./Proxyable.sol";
// storages
import "./GenesisValueVaultStorage.sol";

/**
 * @notice Implements the management of the genesis value as an amount for Lending positions.
 */
contract GenesisValueVault is IGenesisValueVault, MixinAddressResolver, Proxyable {
    using SafeCast for uint256;
    using SafeCast for int256;
    using RoundingUint256 for uint256;
    using RoundingInt256 for int256;

    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _resolver The address of the Address Resolver contract
     */
    function initialize(address _resolver) public initializer onlyProxy {
        registerAddressResolver(_resolver);
    }

    // @inheritdoc MixinAddressResolver
    function requiredContracts() public pure override returns (bytes32[] memory contracts) {
        contracts = new bytes32[](2);
        contracts[0] = Contracts.LENDING_MARKET_CONTROLLER;
        contracts[1] = Contracts.RESERVE_FUND;
    }

    /**
     * @notice Gets if the currency is initialized.
     * @param _ccy Currency name in bytes32
     * @return The boolean if the currency is initialized or not
     */
    function isInitialized(bytes32 _ccy) public view override returns (bool) {
        return Storage.slot().isInitialized[_ccy];
    }

    /**
     * @notice Gets if the decimals of the genesis value.
     * @param _ccy Currency name in bytes32
     * @return The decimals of the genesis value.
     */
    function decimals(bytes32 _ccy) public view override returns (uint8) {
        return Storage.slot().decimals[_ccy];
    }

    /**
     * @notice Gets the total supply of lending
     * @param _ccy Currency name in bytes32
     * @return The total supply of lending
     */
    function getTotalLendingSupply(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().totalLendingSupplies[_ccy];
    }

    /**
     * @notice Gets the total supply of borrowing
     * @param _ccy Currency name in bytes32
     * @return The total supply of borrowing
     */
    function getTotalBorrowingSupply(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().totalBorrowingSupplies[_ccy];
    }

    /**
     * @notice Gets the user balance.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @return The user balance
     */
    function getBalance(bytes32 _ccy, address _user) public view override returns (int256) {
        (int256 balance, int256 fluctuation) = _getActualBalance(
            _ccy,
            _user,
            getCurrentMaturity(_ccy)
        );
        return balance + fluctuation;
    }

    /**
     * @notice Gets the future value of the user balance.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @return The future value of the user balance
     */
    function getBalanceInFutureValue(
        bytes32 _ccy,
        address _user
    ) external view override returns (int256) {
        // NOTE: The formula is:
        // futureValue = genesisValue * currentCompoundFactor.
        return
            (getBalance(_ccy, _user) * getLendingCompoundFactor(_ccy).toInt256()).div(
                (10 ** decimals(_ccy)).toInt256()
            );
    }

    /**
     * @notice Gets the current total supply per maturity
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity
     * @return The current total supply
     */
    function getMaturityGenesisValue(
        bytes32 _ccy,
        uint256 _maturity
    ) external view override returns (int256) {
        return Storage.slot().maturityBalances[_ccy][_maturity];
    }

    /**
     * @notice Gets the current maturity
     * @param _ccy Currency name in bytes32
     * @return The current maturity
     */
    function getCurrentMaturity(bytes32 _ccy) public view override returns (uint256) {
        return Storage.slot().currentMaturity[_ccy];
    }

    /**
     * @notice Gets the lending compound factor
     * @param _ccy Currency name in bytes32
     * @return The lending compound factor
     */
    function getLendingCompoundFactor(bytes32 _ccy) public view override returns (uint256) {
        return Storage.slot().lendingCompoundFactors[_ccy];
    }

    /**
     * @notice Gets the borrowing compound factor
     * @param _ccy Currency name in bytes32
     * @return The lending compound factor
     */
    function getBorrowingCompoundFactor(bytes32 _ccy) public view override returns (uint256) {
        return Storage.slot().borrowingCompoundFactors[_ccy];
    }

    /**
     * @notice Gets the auto-roll log
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity
     * @return The auto-roll log
     */
    function getAutoRollLog(
        bytes32 _ccy,
        uint256 _maturity
    ) external view override returns (AutoRollLog memory) {
        return Storage.slot().autoRollLogs[_ccy][_maturity];
    }

    /**
     * @notice Gets the latest auto-roll log
     * @param _ccy Currency name in bytes32
     * @return The auto-roll log
     */
    function getLatestAutoRollLog(
        bytes32 _ccy
    ) external view override returns (AutoRollLog memory) {
        return Storage.slot().autoRollLogs[_ccy][Storage.slot().currentMaturity[_ccy]];
    }

    /**
     * @notice Calculates the future value from the basis maturity to the destination maturity using the compound factor.
     * @param _ccy Currency name in bytes32
     * @return The future value at the destination maturity
     */
    function calculateFVFromFV(
        bytes32 _ccy,
        uint256 _basisMaturity,
        uint256 _destinationMaturity,
        int256 _futureValue
    ) external view override returns (int256) {
        if (_futureValue == 0) {
            return 0;
        } else if (_basisMaturity == _destinationMaturity) {
            return _futureValue;
        } else {
            // NOTE: These calculation steps "FV -> GV -> FV" are needed to match the actual conversion step.
            // Otherwise, Solidity's truncation specification creates a difference in the calculated values.
            // The formula is:
            // genesisValue = featureValueInMaturity / compoundFactorInMaturity.
            // currentFeatureValue = genesisValue * currentCompoundFactor
            int256 genesisValue = calculateGVFromFV(_ccy, _basisMaturity, _futureValue);
            return calculateFVFromGV(_ccy, _destinationMaturity, genesisValue);
        }
    }

    /**
     * @notice Calculates the genesis value from the future value at the basis maturity using the compound factor.
     * @param _ccy Currency name in bytes32
     * @return The genesis value
     */
    function calculateGVFromFV(
        bytes32 _ccy,
        uint256 _basisMaturity,
        int256 _futureValue
    ) public view override returns (int256) {
        uint256 compoundFactor = _basisMaturity == 0 ||
            _basisMaturity == Storage.slot().currentMaturity[_ccy]
            ? getLendingCompoundFactor(_ccy)
            : Storage.slot().autoRollLogs[_ccy][_basisMaturity].lendingCompoundFactor;

        if (compoundFactor == 0) revert NoCompoundFactorExists({maturity: _basisMaturity});

        // NOTE: The formula is: genesisValue = featureValue / compoundFactor.
        bool isPlus = _futureValue > 0;
        uint256 absFv = (isPlus ? _futureValue : -_futureValue).toUint256();
        uint256 absGv = (absFv * 10 ** decimals(_ccy)).div(compoundFactor);
        return isPlus ? absGv.toInt256() : -(absGv.toInt256());
    }

    /**
     * @notice Calculates the future value at the basis maturity from the genesis value using the compound factor.
     * @param _ccy Currency name in bytes32
     * @return The future value
     */
    function calculateFVFromGV(
        bytes32 _ccy,
        uint256 _basisMaturity,
        int256 _genesisValue
    ) public view override returns (int256) {
        uint256 compoundFactor = _basisMaturity == 0 ||
            _basisMaturity == Storage.slot().currentMaturity[_ccy]
            ? getLendingCompoundFactor(_ccy)
            : Storage.slot().autoRollLogs[_ccy][_basisMaturity].lendingCompoundFactor;

        if (compoundFactor == 0) revert NoCompoundFactorExists({maturity: _basisMaturity});

        bool isPlus = _genesisValue > 0;
        uint256 absGv = (isPlus ? _genesisValue : -_genesisValue).toUint256();
        uint256 absFv = (absGv * compoundFactor).div(10 ** decimals(_ccy));

        return isPlus ? absFv.toInt256() : -(absFv.toInt256());
    }

    /**
     * @notice Initializes the currency setting.
     * @param _ccy Currency name in bytes32
     * @param _decimals Compound factor decimals
     * @param _compoundFactor Initial compound factor
     * @param _maturity Initial maturity
     */
    function initializeCurrencySetting(
        bytes32 _ccy,
        uint8 _decimals,
        uint256 _compoundFactor,
        uint256 _maturity
    ) external override onlyLendingMarketController {
        if (_compoundFactor == 0) revert CompoundFactorIsZero();
        if (isInitialized(_ccy)) revert CurrencyAlreadyInitialized();

        Storage.slot().isInitialized[_ccy] = true;
        Storage.slot().decimals[_ccy] = _decimals;
        Storage.slot().initialCompoundFactors[_ccy] = _compoundFactor;
        Storage.slot().lendingCompoundFactors[_ccy] = _compoundFactor;
        Storage.slot().borrowingCompoundFactors[_ccy] = _compoundFactor;
        Storage.slot().currentMaturity[_ccy] = _maturity;

        // Update autoRollLogs by initial compound factor.
        // These values are updated by the first Itayose call of the nearest maturity market
        // if it is executed.
        Storage.slot().autoRollLogs[_ccy][_maturity] = AutoRollLog({
            unitPrice: Constants.PRICE_DIGIT,
            lendingCompoundFactor: _compoundFactor,
            borrowingCompoundFactor: _compoundFactor,
            prev: 0,
            next: 0
        });
    }

    /**
     * @notice Update the currency setting.
     * @dev This function is allowed to be called only before the initial compound factor is finalized.
     * @param _ccy Currency name in bytes32
     * @param _unitPrice The unit price used to calculate the compound factor
     */
    function updateInitialCompoundFactor(
        bytes32 _ccy,
        uint256 _unitPrice
    ) external override onlyLendingMarketController {
        uint256 maturity = Storage.slot().currentMaturity[_ccy];

        if (Storage.slot().autoRollLogs[_ccy][maturity].prev != 0) {
            revert InitialCompoundFactorAlreadyFinalized();
        }

        _updateCompoundFactor(_ccy, _unitPrice, 0, 0);
        Storage.slot().autoRollLogs[_ccy][maturity] = AutoRollLog({
            unitPrice: _unitPrice,
            lendingCompoundFactor: Storage.slot().lendingCompoundFactors[_ccy],
            borrowingCompoundFactor: Storage.slot().borrowingCompoundFactors[_ccy],
            prev: 0,
            next: 0
        });
    }

    /**
     * @notice Executes the auto-roll.
     * @param _ccy Currency name in bytes32
     * @param _maturity Current maturity
     * @param _nextMaturity Next maturity to be rolled
     * @param _unitPrice Unit price of auto-roll
     * @param _orderFeeRate Order fee rate used to calculate the auto-roll fee
     */
    function executeAutoRoll(
        bytes32 _ccy,
        uint256 _maturity,
        uint256 _nextMaturity,
        uint256 _unitPrice,
        uint256 _orderFeeRate
    ) external override onlyLendingMarketController {
        if (_unitPrice == 0) revert UnitPriceIsZero();
        if (_nextMaturity <= _maturity) revert InvalidMaturity();

        _updateCompoundFactor(_ccy, _unitPrice, _orderFeeRate, _nextMaturity - _maturity);
        _updateAutoRollLogs(_ccy, _maturity, _nextMaturity, _unitPrice);

        emit AutoRollExecuted(
            _ccy,
            Storage.slot().lendingCompoundFactors[_ccy],
            Storage.slot().borrowingCompoundFactors[_ccy],
            _unitPrice,
            _nextMaturity,
            _maturity
        );
    }

    function _updateAutoRollLogs(
        bytes32 _ccy,
        uint256 _maturity,
        uint256 _nextMaturity,
        uint256 _unitPrice
    ) private {
        AutoRollLog memory currentLog = Storage.slot().autoRollLogs[_ccy][_maturity];
        AutoRollLog memory nextLog = Storage.slot().autoRollLogs[_ccy][_nextMaturity];

        if (
            currentLog.next != 0 ||
            currentLog.lendingCompoundFactor == 0 ||
            currentLog.borrowingCompoundFactor == 0 ||
            nextLog.lendingCompoundFactor != 0
        ) {
            revert AutoRollLogAlreadyUpdated({
                currentMaturity: _maturity,
                nextMaturity: _nextMaturity
            });
        }

        Storage.slot().currentMaturity[_ccy] = _nextMaturity;
        Storage.slot().autoRollLogs[_ccy][_maturity].next = _nextMaturity;
        Storage.slot().autoRollLogs[_ccy][_nextMaturity] = AutoRollLog({
            unitPrice: _unitPrice,
            lendingCompoundFactor: Storage.slot().lendingCompoundFactors[_ccy],
            borrowingCompoundFactor: Storage.slot().borrowingCompoundFactors[_ccy],
            prev: _maturity,
            next: 0
        });
    }

    /**
     * @notice Updates the user's balance of the genesis value with the input future value.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _basisMaturity The basis maturity
     * @param _fvAmount The amount in the future value
     */
    function updateGenesisValueWithFutureValue(
        bytes32 _ccy,
        address _user,
        uint256 _basisMaturity,
        int256 _fvAmount
    ) external override onlyLendingMarketController {
        int256 amount = calculateGVFromFV(_ccy, _basisMaturity, _fvAmount);

        _updateBalance(_ccy, _user, _basisMaturity, amount);
    }

    /**
     * @notice Updates the user's balance of the genesis value without the input future value.
     * @dev This function is used only in the case that the user is the last person who updates the genesis value at maturity,
     * and called only one time per maturity.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _basisMaturity The basis maturity
     */
    function updateGenesisValueWithResidualAmount(
        bytes32 _ccy,
        address _user,
        uint256 _basisMaturity
    ) external override onlyLendingMarketController {
        int256 residualGVAmount = Storage.slot().maturityBalances[_ccy][_basisMaturity];

        _updateBalance(_ccy, _user, _basisMaturity, -residualGVAmount);

        if (Storage.slot().maturityBalances[_ccy][_basisMaturity] != 0) {
            revert ResidualAmountIsNotZero();
        }
    }

    /**
     * @notice Transfers the genesis value from sender to receiver.
     * @param _ccy Currency name in bytes32
     * @param _sender Sender's address
     * @param _receiver Receiver's address
     * @param _amount Amount of funds to sent
     */
    function transferFrom(
        bytes32 _ccy,
        address _sender,
        address _receiver,
        int256 _amount
    ) external override onlyLendingMarketController {
        Storage.slot().balances[_ccy][_sender] -= _amount;
        Storage.slot().balances[_ccy][_receiver] += _amount;

        emit Transfer(_ccy, _sender, _receiver, _amount);
    }

    /**
     * @notice Clean up balance of the user per maturity.
     * @dev The genesis value of borrowing fluctuates when it is auto-rolled, but it is not updated in real-time.
     * This function removes the fluctuation amount calculated by lazy evaluation to reduce gas costs.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _maturity The maturity
     */
    function cleanUpBalance(
        bytes32 _ccy,
        address _user,
        uint256 _maturity
    ) external override onlyLendingMarketController {
        uint256 maturity = _maturity == 0 ? getCurrentMaturity(_ccy) : _maturity;
        int256 fluctuation = _getBalanceFluctuationByAutoRolls(_ccy, _user, maturity);

        if (fluctuation < 0) {
            address reserveFundAddr = address(reserveFund());

            _updateTotalSupply(_ccy, fluctuation, Storage.slot().balances[_ccy][_user]);
            _updateTotalSupply(_ccy, -fluctuation, Storage.slot().balances[_ccy][reserveFundAddr]);

            Storage.slot().userMaturities[_ccy][_user] = maturity;
            Storage.slot().balances[_ccy][_user] += fluctuation;
            Storage.slot().balances[_ccy][reserveFundAddr] += -fluctuation;

            emit Transfer(_ccy, _user, reserveFundAddr, -fluctuation);
        }
    }

    /**
     * @notice Forces a reset of the user's genesis value.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     */
    function executeForcedReset(
        bytes32 _ccy,
        address _user
    ) external override onlyLendingMarketController {
        int256 removedAmount = Storage.slot().balances[_ccy][_user];

        if (removedAmount != 0) {
            Storage.slot().balances[_ccy][_user] = 0;
            emit Transfer(_ccy, _user, address(0), removedAmount);
        }
    }

    /**
     * @notice Forces a reset of the user's genesis value.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _amountInFV The amount in the future value to reset
     */
    function executeForcedReset(
        bytes32 _ccy,
        uint256 _maturity,
        address _user,
        int256 _amountInFV
    )
        external
        override
        onlyLendingMarketController
        returns (int256 removedAmountInFV, int256 balance)
    {
        int256 _amount = calculateGVFromFV(_ccy, _maturity, _amountInFV);
        int256 removedAmount = Storage.slot().balances[_ccy][_user];

        if ((_amount > 0 && removedAmount < 0) || (_amount < 0 && removedAmount > 0)) {
            revert InvalidAmount();
        }

        if ((_amount > 0 && _amount < removedAmount) || (_amount < 0 && _amount > removedAmount)) {
            removedAmount = _amount;
        }

        if (removedAmount != 0) {
            Storage.slot().balances[_ccy][_user] -= removedAmount;
            emit Transfer(_ccy, _user, address(0), removedAmount);
        }

        removedAmountInFV = calculateFVFromGV(_ccy, _maturity, removedAmount);
        balance = Storage.slot().balances[_ccy][_user];
    }

    /**
     * @notice Gets the fluctuation amount of genesis value caused by auto-rolls.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _maturity The maturity
     */
    function getBalanceFluctuationByAutoRolls(
        bytes32 _ccy,
        address _user,
        uint256 _maturity
    ) external view override returns (int256 fluctuation) {
        uint256 maturity = _maturity == 0 ? getCurrentMaturity(_ccy) : _maturity;
        fluctuation = _getBalanceFluctuationByAutoRolls(_ccy, _user, maturity);
    }

    /**
     * @notice Calculates the fluctuation amount of genesis value caused by auto-rolls at a certain maturity
     * @param _ccy Currency name in bytes32
     * @param _balance User's balance
     * @param _fromMaturity The maturity at start
     * @param _toMaturity The maturity at end
     */
    function calculateBalanceFluctuationByAutoRolls(
        bytes32 _ccy,
        int256 _balance,
        uint256 _fromMaturity,
        uint256 _toMaturity
    ) external view override returns (int256 fluctuation) {
        uint256 toMaturity = _toMaturity == 0 ? getCurrentMaturity(_ccy) : _toMaturity;
        fluctuation = _calculateBalanceFluctuationByAutoRolls(
            _ccy,
            _balance,
            _fromMaturity,
            toMaturity
        );
    }

    function _updateBalance(
        bytes32 _ccy,
        address _user,
        uint256 _maturity,
        int256 _amount
    ) private {
        (int256 balance, int256 fluctuation) = _getActualBalance(_ccy, _user, _maturity);
        int256 totalAmount = _amount;

        // Note: `fluctuation` is always 0 or less because the genesis value fluctuates
        // only when it is negative.
        // Here, only the opposite amount of the fluctuation is added to the reserve fund as a fee.
        if (fluctuation < 0) {
            totalAmount += fluctuation;
            address reserveFundAddr = address(reserveFund());

            _updateTotalSupply(_ccy, -fluctuation, Storage.slot().balances[_ccy][reserveFundAddr]);

            Storage.slot().balances[_ccy][reserveFundAddr] += -fluctuation;

            emit Transfer(_ccy, _user, reserveFundAddr, -fluctuation);
        }

        _updateTotalSupply(_ccy, totalAmount, balance);

        Storage.slot().userMaturities[_ccy][_user] = _maturity;
        Storage.slot().balances[_ccy][_user] += totalAmount;
        Storage.slot().maturityBalances[_ccy][_maturity] += _amount;

        emit Transfer(_ccy, address(0), _user, _amount);
    }

    function _updateTotalSupply(bytes32 _ccy, int256 _amount, int256 _balance) private {
        if (_amount >= 0) {
            uint256 absAmount = _amount.toUint256();
            if (_balance >= 0) {
                Storage.slot().totalLendingSupplies[_ccy] += absAmount;
            } else {
                int256 diff = _amount + _balance;
                if (diff >= 0) {
                    Storage.slot().totalLendingSupplies[_ccy] += diff.toUint256();
                    Storage.slot().totalBorrowingSupplies[_ccy] -= (-_balance).toUint256();
                } else {
                    Storage.slot().totalBorrowingSupplies[_ccy] -= absAmount;
                }
            }
        } else {
            uint256 absAmount = (-_amount).toUint256();
            if (_balance <= 0) {
                Storage.slot().totalBorrowingSupplies[_ccy] += absAmount;
            } else {
                int256 diff = _amount + _balance;
                if (diff <= 0) {
                    Storage.slot().totalBorrowingSupplies[_ccy] += (-diff).toUint256();
                    Storage.slot().totalLendingSupplies[_ccy] -= _balance.toUint256();
                } else {
                    Storage.slot().totalLendingSupplies[_ccy] -= absAmount;
                }
            }
        }
    }

    function _getActualBalance(
        bytes32 _ccy,
        address _user,
        uint256 _maturity
    ) private view returns (int256 balance, int256 fluctuation) {
        fluctuation = _getBalanceFluctuationByAutoRolls(_ccy, _user, _maturity);
        balance = Storage.slot().balances[_ccy][_user];
    }

    /**
     * @notice Calculates the fluctuation amount of genesis value caused by auto-rolls.
     * @dev The genesis value means the present value of the lending position at the time
     * when the initial market is opened, so the genesis value amount will fluctuate
     * by the fee rate due to auto-rolls if it is negative (equals to the borrowing position).
     * @param _ccy Currency for pausing all lending markets
     * @param _user User's address
     * @return fluctuation The fluctuated genesis value amount
     */
    function _getBalanceFluctuationByAutoRolls(
        bytes32 _ccy,
        address _user,
        uint256 _maturity
    ) private view returns (int256 fluctuation) {
        int256 balance = Storage.slot().balances[_ccy][_user];
        uint256 userMaturity = Storage.slot().userMaturities[_ccy][_user];

        fluctuation = _calculateBalanceFluctuationByAutoRolls(
            _ccy,
            balance,
            userMaturity,
            _maturity
        );
    }

    function _calculateBalanceFluctuationByAutoRolls(
        bytes32 _ccy,
        int256 _balance,
        uint256 _fromMaturity,
        uint256 _toMaturity
    ) private view returns (int256 fluctuation) {
        if (_balance >= 0 || _toMaturity <= _fromMaturity || _fromMaturity == 0) {
            return 0;
        }

        AutoRollLog memory autoRollLog = Storage.slot().autoRollLogs[_ccy][_fromMaturity];

        uint256 destinationBorrowingCF;
        uint256 destinationLendingCF;
        uint256 currentMaturity = getCurrentMaturity(_ccy);

        if (_toMaturity > currentMaturity) {
            return 0;
        } else if (_toMaturity == currentMaturity) {
            destinationBorrowingCF = Storage.slot().borrowingCompoundFactors[_ccy];
            destinationLendingCF = Storage.slot().lendingCompoundFactors[_ccy];
        } else {
            AutoRollLog memory destinationAutoRollLog = Storage.slot().autoRollLogs[_ccy][
                _toMaturity
            ];
            destinationBorrowingCF = destinationAutoRollLog.borrowingCompoundFactor;
            destinationLendingCF = destinationAutoRollLog.lendingCompoundFactor;
        }

        // Note: The formula is:
        // fluctuation = currentBalance * ((currentBCF / userBCF) * (userLCF / currentLCF) - 1)
        fluctuation =
            -Math
                .mulDiv(
                    Math.mulDiv(
                        (-_balance).toUint256(),
                        destinationBorrowingCF,
                        autoRollLog.borrowingCompoundFactor
                    ),
                    autoRollLog.lendingCompoundFactor,
                    destinationLendingCF
                )
                .toInt256() -
            _balance;
    }

    function _updateCompoundFactor(
        bytes32 _ccy,
        uint256 _unitPrice,
        uint256 _orderFeeRate,
        uint256 _duration
    ) private {
        if (_orderFeeRate > Constants.PCT_DIGIT) revert InvalidOrderFeeRate();

        // Save actual compound factor here due to calculating the genesis value from future value.
        // NOTE: The formula is:
        // autoRollRate = 1 / unitPrice
        // rollFeeRate = orderFeeRate * (duration / SECONDS_IN_YEAR)
        // newLendingCompoundFactor = currentLendingCompoundFactor * (autoRollRate - rollFeeRate)
        // newBorrowingCompoundFactor = currentBorrowingCompoundFactor * (autoRollRate + rollFeeRate)
        uint256 denominator = (Constants.PCT_DIGIT * Constants.SECONDS_IN_YEAR * _unitPrice);

        Storage.slot().lendingCompoundFactors[_ccy] = (Storage.slot().lendingCompoundFactors[_ccy] *
            ((Constants.PRICE_DIGIT * Constants.PCT_DIGIT * Constants.SECONDS_IN_YEAR) -
                (_orderFeeRate * _duration * _unitPrice))).div(denominator);

        Storage.slot().borrowingCompoundFactors[_ccy] = (Storage.slot().borrowingCompoundFactors[
            _ccy
        ] *
            ((Constants.PRICE_DIGIT * Constants.PCT_DIGIT * Constants.SECONDS_IN_YEAR) +
                (_orderFeeRate * _duration * _unitPrice))).div(denominator);
    }
}
