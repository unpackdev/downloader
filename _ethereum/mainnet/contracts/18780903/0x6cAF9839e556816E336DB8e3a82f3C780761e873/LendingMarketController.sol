// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// dependencies
import "./ReentrancyGuard.sol";
import "./EnumerableSet.sol";
import "./Multicall.sol";
// interfaces
import "./ILendingMarketController.sol";
import "./ILendingMarket.sol";
// libraries
import "./Contracts.sol";
import "./OrderBookLib.sol";
import "./FundManagementLogic.sol";
import "./LendingMarketOperationLogic.sol";
import "./LendingMarketUserLogic.sol";
import "./LiquidationLogic.sol";
// mixins
import "./MixinAccessControl.sol";
import "./MixinAddressResolver.sol";
import "./MixinLendingMarketConfiguration.sol";
// types
import "./ProtocolTypes.sol";
// utils
import "./Proxyable.sol";
import "./LockAndMsgSender.sol";
// storages
import "./LendingMarketControllerStorage.sol";

/**
 * @notice Implements the module to manage separated lending market contracts per currency.
 *
 * This contract also works as a factory contract that can deploy (start) a new lending market & order book
 * for selected currency and maturity and has the calculation logic for the following user's funds in addition.
 * - Present Value(PV)
 * - Future Value(FV)
 * - Genesis Value(GV)
 *
 * Once the order book is created, it will be rotated and reused once it reaches its maturity date. At the time of rotation,
 * a new maturity date is set and the compound factor is updated.
 *
 * The users mainly call this contract to execute orders to lend or borrow funds.
 */
contract LendingMarketController is
    ILendingMarketController,
    MixinLendingMarketConfiguration,
    MixinAccessControl,
    MixinAddressResolver,
    ReentrancyGuard,
    Proxyable,
    LockAndMsgSender,
    Multicall
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * @notice Modifier to check if there is an order book in the maturity.
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the order book
     */
    modifier ifValidMaturity(bytes32 _ccy, uint256 _maturity) {
        if (Storage.slot().maturityOrderBookIds[_ccy][_maturity] == 0) revert InvalidMaturity();
        _;
    }

    /**
     * @notice Modifier to check if the protocol is active.
     */
    modifier ifActive() {
        if (isTerminated()) revert AlreadyTerminated();
        _;
    }

    /**
     * @notice Modifier to check if the protocol is inactive.
     */
    modifier ifInactive() {
        if (!isTerminated()) revert NotTerminated();
        _;
    }

    /**
     * @notice Initializes the contract.
     * @dev Function is invoked by the proxy contract when the contract is added to the ProxyController.
     * @param _owner The address of the contract owner
     * @param _resolver The address of the Address Resolver contract
     * @param _marketBasePeriod The base period for market maturity
     */
    function initialize(
        address _owner,
        address _resolver,
        uint256 _marketBasePeriod
    ) public initializer onlyProxy {
        Storage.slot().marketBasePeriod = _marketBasePeriod;
        MixinLendingMarketConfiguration._initialize(_owner);
        MixinAccessControl._setupInitialRoles(_owner);
        registerAddressResolver(_resolver);
    }

    // @inheritdoc MixinAddressResolver
    function requiredContracts() public pure override returns (bytes32[] memory contracts) {
        contracts = new bytes32[](5);
        contracts[0] = Contracts.BEACON_PROXY_CONTROLLER;
        contracts[1] = Contracts.CURRENCY_CONTROLLER;
        contracts[2] = Contracts.GENESIS_VALUE_VAULT;
        contracts[3] = Contracts.RESERVE_FUND;
        contracts[4] = Contracts.TOKEN_VAULT;
    }

    /**
     * @notice Gets if the protocol has not been terminated.
     * @return The boolean if the protocol has not been terminated
     */
    function isTerminated() public view override returns (bool) {
        return Storage.slot().terminationDate > 0;
    }

    /**
     * @notice Gets if the user needs to redeem the funds.
     * @return The boolean if the user needs to redeem the funds
     */
    function isRedemptionRequired(address _user) external view override returns (bool) {
        return isTerminated() && !Storage.slot().isRedeemed[_user];
    }

    /**
     * @notice Gets the base period for market maturity
     * @return The base period
     */
    function getMarketBasePeriod() external view override returns (uint256) {
        return Storage.slot().marketBasePeriod;
    }

    /**
     * @notice Gets the date at the emergency termination.
     * @return The termination date
     */
    function getTerminationDate() external view override returns (uint256) {
        return Storage.slot().terminationDate;
    }

    /**
     * @notice Gets the currency information cached at the emergency termination.
     * @param _ccy Currency name in bytes32
     * @return The price cached
     */
    function getTerminationCurrencyCache(
        bytes32 _ccy
    ) external view override returns (TerminationCurrencyCache memory) {
        return Storage.slot().terminationCurrencyCaches[_ccy];
    }

    /**
     * @notice Gets the collateral ratio of each token in TokenVault at the emergency termination.
     * @param _ccy Currency name in bytes32
     * @return The ratio
     */
    function getTerminationCollateralRatio(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().terminationCollateralRatios[_ccy];
    }

    /**
     * @notice Gets the min debt unit price for the selected currency.
     * This price is based on a one-year maturity.
     * @param _ccy Currency name in bytes32
     * @return The genesis date
     */
    function getMinDebtUnitPrice(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().minDebtUnitPrices[_ccy];
    }

    /**
     * @notice Gets the current min debt unit price.
     * This price fluctuates depending on the current maturity.
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the order book
     * @return The current min debt unit price
     */
    function getCurrentMinDebtUnitPrice(
        bytes32 _ccy,
        uint256 _maturity
    ) external view override returns (uint256) {
        return
            FundManagementLogic.getCurrentMinDebtUnitPrice(
                _maturity,
                Storage.slot().minDebtUnitPrices[_ccy]
            );
    }

    /**
     * @notice Gets the genesis date when the first market opens for the selected currency.
     * @param _ccy Currency name in bytes32
     * @return The genesis date
     */
    function getGenesisDate(bytes32 _ccy) external view override returns (uint256) {
        return Storage.slot().genesisDates[_ccy];
    }

    /**
     * @notice Gets the lending market contract address for the selected currency.
     * @param _ccy Currency name in bytes32
     * @return Array with the lending market address
     */
    function getLendingMarket(bytes32 _ccy) external view override returns (address) {
        return Storage.slot().lendingMarkets[_ccy];
    }

    /**
     * @notice Gets the order book id for the selected currency and maturity.
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the order book
     * @return The order book id
     */
    function getOrderBookId(
        bytes32 _ccy,
        uint256 _maturity
    ) external view override returns (uint8) {
        return Storage.slot().maturityOrderBookIds[_ccy][_maturity];
    }

    /**
     * @notice Gets the future value contract address for the selected currency and maturity.
     * @param _ccy Currency name in bytes32
     * @return The future value vault address
     */
    function getFutureValueVault(bytes32 _ccy) public view override returns (address) {
        return Storage.slot().futureValueVaults[_ccy];
    }

    /**
     * @notice Gets the total amount of pending orders that is not cleaned up yet.
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the order book
     * @return The total amount
     */
    function getPendingOrderAmount(
        bytes32 _ccy,
        uint256 _maturity
    ) external view override returns (uint256) {
        return Storage.slot().pendingOrderAmounts[_ccy][_maturity];
    }

    /**
     * @notice Gets the estimated order result by the calculation of the amount to be filled when executing an order in the order books.
     * @param _params The parameters to calculate the order estimation <br>
     * - ccy: Currency name in bytes32 of the selected market <br>
     * - maturity: The maturity of the market <br>
     * - side: Order position type, Borrow or Lend <br>
     * - amount: Amount of funds the maker wants to borrow/lend <br>
     * - unitPrice: Amount of unit price taker wish to borrow/lend <br>
     * - additionalDepositAmount: Additional amount to be deposited with the lending order <br>
     * - ignoreBorrowedAmount: The boolean if the borrowed amount is ignored and not used as collateral or not
     * @return lastUnitPrice The last unit price that is filled on the order book
     * @return filledAmount The amount that is filled on the order book
     * @return filledAmountInFV The amount in the future value that is filled on the order book
     * @return orderFeeInFV The order fee amount in the future value
     * @return placedAmount The amount that is placed to the order book
     * @return coverage The rate of collateral used
     * @return isInsufficientDepositAmount The boolean if the order amount for lending in the selected currency is insufficient
     * for the deposit amount or not
     */
    function getOrderEstimation(
        GetOrderEstimationParams calldata _params
    )
        external
        view
        override
        returns (
            uint256 lastUnitPrice,
            uint256 filledAmount,
            uint256 filledAmountInFV,
            uint256 orderFeeInFV,
            uint256 placedAmount,
            uint256 coverage,
            bool isInsufficientDepositAmount
        )
    {
        return LendingMarketUserLogic.getOrderEstimation(_params);
    }

    /**
     * @notice Gets maturities for the selected currency.
     * @param _ccy Currency name in bytes32
     * @return Array with the lending market maturity
     */
    function getMaturities(bytes32 _ccy) public view override returns (uint256[] memory) {
        return
            ILendingMarket(Storage.slot().lendingMarkets[_ccy]).getMaturities(
                Storage.slot().orderBookIdLists[_ccy]
            );
    }

    /**
     * @notice Gets the order book ids.
     * @param _ccy Currency name in bytes32
     * @return The array of order book id
     */
    function getOrderBookIds(bytes32 _ccy) external view override returns (uint8[] memory) {
        return Storage.slot().orderBookIdLists[_ccy];
    }

    /**
     * @notice Get all the currencies in which the user has lending positions or orders.
     * @param _user User's address
     * @return The array of the currency
     */
    function getUsedCurrencies(address _user) external view override returns (bytes32[] memory) {
        return Storage.slot().usedCurrencies[_user].values();
    }

    /**
     * @notice Gets the total present value of the account for selected currency.
     * @param _ccy Currency name in bytes32 for Lending Market
     * @param _user User's address
     * @return totalPresentValue The total present value
     */
    function getTotalPresentValue(
        bytes32 _ccy,
        address _user
    ) external view override returns (int256 totalPresentValue) {
        totalPresentValue = FundManagementLogic.getActualFunds(_ccy, 0, _user, 0).presentValue;
    }

    /**
     * @notice Gets the total present value of the account converted to base currency.
     * @param _user User's address
     * @return totalPresentValue The total present value in base currency
     */
    function getTotalPresentValueInBaseCurrency(
        address _user
    ) external view override returns (int256 totalPresentValue) {
        EnumerableSet.Bytes32Set storage currencySet = Storage.slot().usedCurrencies[_user];

        for (uint256 i; i < currencySet.length(); i++) {
            bytes32 ccy = currencySet.at(i);
            int256 amount = FundManagementLogic.getActualFunds(ccy, 0, _user, 0).presentValue;
            totalPresentValue += currencyController().convertToBaseCurrency(ccy, amount);
        }
    }

    /**
     * @notice Gets the genesis value of the account.
     * @param _ccy Currency name in bytes32 for Lending Market
     * @param _user User's address
     * @return genesisValue The genesis value
     */
    function getGenesisValue(
        bytes32 _ccy,
        address _user
    ) external view override returns (int256 genesisValue) {
        genesisValue = FundManagementLogic.getActualFunds(_ccy, 0, _user, 0).genesisValue;
    }

    /**
     * @notice Gets user's active position from the future value vault
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the selected order book
     * @param _user User's address
     * @return presentValue The present value of the position
     * @return futureValue The future value of the position
     */
    function getPosition(
        bytes32 _ccy,
        uint256 _maturity,
        address _user
    ) external view override returns (int256 presentValue, int256 futureValue) {
        (presentValue, futureValue) = FundManagementLogic.getPosition(_ccy, _maturity, _user);
    }

    /**
     * @notice Gets the funds that are calculated from the user's lending and borrowing order list
     * for the selected currency.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     * @param _liquidationThresholdRate The liquidation threshold rate
     * @return funds The funds calculated from the user's lending and borrowing order list
     */
    function calculateFunds(
        bytes32 _ccy,
        address _user,
        uint256 _liquidationThresholdRate
    ) external view override returns (CalculatedFunds memory funds) {
        if (Storage.slot().usedCurrencies[_user].contains(_ccy)) {
            AdditionalFunds memory emptyAdditionalFunds;

            return
                FundManagementLogic.calculateFunds(
                    _ccy,
                    _user,
                    emptyAdditionalFunds,
                    _liquidationThresholdRate
                );
        }
    }

    /**
     * @notice Gets the funds that are calculated from the user's lending and borrowing order list
     * for all currencies in base currency.
     * @param _user User's address
     * @param _additionalFunds The funds to be added for calculating the total funds
     * @param _liquidationThresholdRate The liquidation threshold rate
     * @return funds The total funds calculated from the user's lending and borrowing order list
     */
    function calculateTotalFundsInBaseCurrency(
        address _user,
        AdditionalFunds calldata _additionalFunds,
        uint256 _liquidationThresholdRate
    ) external view override returns (CalculatedTotalFunds memory funds) {
        return
            FundManagementLogic.calculateTotalFundsInBaseCurrency(
                _user,
                _additionalFunds,
                _liquidationThresholdRate
            );
    }

    /**
     * @notice Gets if the lending market is initialized.
     * @param _ccy Currency name in bytes32
     * @return The boolean if the lending market is initialized or not
     */
    function isInitializedLendingMarket(bytes32 _ccy) public view override returns (bool) {
        return Storage.slot().genesisDates[_ccy] != 0;
    }

    /**
     * @notice Initialize the lending market to set a genesis date and compound factor
     * @param _ccy Currency name in bytes32
     * @param _genesisDate The genesis date when the initial market is opened
     * @param _compoundFactor The initial compound factor when the initial market is opened
     * @param _orderFeeRate The order fee rate received by protocol
     * @param _circuitBreakerLimitRange The circuit breaker limit range
     */
    function initializeLendingMarket(
        bytes32 _ccy,
        uint256 _genesisDate,
        uint256 _compoundFactor,
        uint256 _orderFeeRate,
        uint256 _circuitBreakerLimitRange,
        uint256 _minDebtUnitPrice
    ) external override onlyOwner {
        if (isInitializedLendingMarket(_ccy)) revert AlreadyInitialized();

        LendingMarketOperationLogic.initializeLendingMarket(
            _ccy,
            _genesisDate,
            _compoundFactor,
            _orderFeeRate,
            _circuitBreakerLimitRange,
            _minDebtUnitPrice
        );
    }

    /**
     * @notice Creates new order book.
     * @param _ccy Main currency for new order book
     * @param _openingDate The timestamp when the order book opens
     * @param _preOpeningDate The timestamp when the order book pre-opens
     */
    function createOrderBook(
        bytes32 _ccy,
        uint256 _openingDate,
        uint256 _preOpeningDate
    ) external override ifActive onlyOwner {
        LendingMarketOperationLogic.createOrderBook(_ccy, _openingDate, _preOpeningDate);
    }

    /**
     * @notice Executes an order. Takes orders if the order is matched,
     * and places new order if not match it.
     *
     * In addition, converts the future value to the genesis value if there is future value in past maturity
     * before the execution of order creation.
     *
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     * @param _side Order position type, Borrow or Lend
     * @param _amount Amount of funds the maker wants to borrow/lend
     * @param _unitPrice Amount of unit price taker wish to borrow/lend
     * @return True if the execution of the operation succeeds
     */
    function executeOrder(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    ) external override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        LendingMarketUserLogic.executeOrder(
            _ccy,
            _maturity,
            msg.sender,
            _side,
            _amount,
            _unitPrice
        );
        return true;
    }

    /**
     * @notice Deposits funds and executes an order at the same time.
     *
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     * @param _side Order position type, Borrow or Lend
     * @param _amount Amount of funds the maker wants to borrow/lend
     * @param _unitPrice Amount of unit price taker wish to borrow/lend
     * @return True if the execution of the operation succeeds
     */
    function depositAndExecuteOrder(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    )
        external
        payable
        override
        nonReentrant
        ifValidMaturity(_ccy, _maturity)
        ifActive
        returns (bool)
    {
        tokenVault().depositFrom{value: msg.value}(msg.sender, _ccy, _amount);
        LendingMarketUserLogic.executeOrder(
            _ccy,
            _maturity,
            msg.sender,
            _side,
            _amount,
            _unitPrice
        );
        return true;
    }

    /**
     * @notice Executes a pre-order. A pre-order will only be accepted from 168 hours (7 days) to 1 hour
     * before the order book opens (Pre-order period). At the end of this period, Itayose will be executed.
     *
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     * @param _side Order position type, Borrow or Lend
     * @param _amount Amount of funds the maker wants to borrow/lend
     * @param _unitPrice Amount of unit price taker wish to borrow/lend
     * @return True if the execution of the operation succeeds
     */
    function executePreOrder(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    ) public override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        LendingMarketUserLogic.executePreOrder(
            _ccy,
            _maturity,
            msg.sender,
            _side,
            _amount,
            _unitPrice
        );

        return true;
    }

    /**
     * @notice Deposits funds and executes a pre-order at the same time.
     *
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     * @param _side Order position type, Borrow or Lend
     * @param _amount Amount of funds the maker wants to borrow/lend
     * @param _unitPrice Amount of unit price taker wish to borrow/lend
     * @return True if the execution of the operation succeeds
     */
    function depositAndExecutesPreOrder(
        bytes32 _ccy,
        uint256 _maturity,
        ProtocolTypes.Side _side,
        uint256 _amount,
        uint256 _unitPrice
    )
        external
        payable
        override
        nonReentrant
        ifValidMaturity(_ccy, _maturity)
        ifActive
        returns (bool)
    {
        tokenVault().depositFrom{value: msg.value}(msg.sender, _ccy, _amount);
        LendingMarketUserLogic.executePreOrder(
            _ccy,
            _maturity,
            msg.sender,
            _side,
            _amount,
            _unitPrice
        );

        return true;
    }

    /**
     * @notice Unwinds user's lending or borrowing positions by creating an opposite position order.
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     */
    function unwindPosition(
        bytes32 _ccy,
        uint256 _maturity
    ) external override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        LendingMarketUserLogic.unwindPosition(_ccy, _maturity, msg.sender);
        return true;
    }

    /**
     * @notice Redeem user's lending positions.
     * Redemption can only be executed once the order book has matured after the currency has been delisted.
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     */
    function executeRedemption(
        bytes32 _ccy,
        uint256 _maturity
    ) external override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        FundManagementLogic.executeRedemption(_ccy, _maturity, msg.sender);
        return true;
    }

    /**
     * @notice Repay user's borrowing positions.
     * Repayment can only be executed once the order book has matured after the currency has been delisted.
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     */
    function executeRepayment(
        bytes32 _ccy,
        uint256 _maturity
    ) external override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        FundManagementLogic.executeRepayment(_ccy, _maturity, msg.sender, 0);
        return true;
    }

    /**
     * @notice Force settlement of all lending and borrowing positions.
     * This function is executed under the present value as of the termination date.
     *
     * @return True if the execution of the operation succeeds
     */
    function executeEmergencySettlement() external override nonReentrant ifInactive returns (bool) {
        FundManagementLogic.executeEmergencySettlement(msg.sender);
        return true;
    }

    /**
     * @notice Executes the Itayose call per selected currency.
     * @param _ccy Currency name in bytes32
     * @param _maturity The maturity of the selected order book
     */
    function executeItayoseCall(
        bytes32 _ccy,
        uint256 _maturity
    ) external override nonReentrant ifActive returns (bool) {
        (
            PartiallyFilledOrder memory partiallyFilledLendingOrder,
            PartiallyFilledOrder memory partiallyFilledBorrowingOrder
        ) = LendingMarketOperationLogic.executeItayoseCall(_ccy, _maturity);

        LendingMarketUserLogic.updateFundsForMaker(
            _ccy,
            _maturity,
            ProtocolTypes.Side.LEND,
            partiallyFilledLendingOrder
        );
        LendingMarketUserLogic.updateFundsForMaker(
            _ccy,
            _maturity,
            ProtocolTypes.Side.BORROW,
            partiallyFilledBorrowingOrder
        );

        return true;
    }

    /**
     * @notice Cancels the own order.
     * @param _ccy Currency name in bytes32 of the selected order book
     * @param _maturity The maturity of the selected order book
     * @param _orderId Market order id
     */
    function cancelOrder(
        bytes32 _ccy,
        uint256 _maturity,
        uint48 _orderId
    ) external override nonReentrant ifValidMaturity(_ccy, _maturity) ifActive returns (bool) {
        ILendingMarket(Storage.slot().lendingMarkets[_ccy]).cancelOrder(
            Storage.slot().maturityOrderBookIds[_ccy][_maturity],
            msg.sender,
            _orderId
        );

        return true;
    }

    /**
     * @notice Liquidates a lending or borrowing position if the user's coverage is hight.
     * @param _collateralCcy Currency name to be used as collateral
     * @param _debtCcy Currency name to be used as debt
     * @param _debtMaturity The order book maturity of the debt
     * @param _user User's address
     * @return True if the execution of the operation succeeds
     */
    function executeLiquidationCall(
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _debtMaturity,
        address _user
    )
        external
        override
        isNotLocked
        ifValidMaturity(_debtCcy, _debtMaturity)
        ifActive
        returns (bool)
    {
        LiquidationLogic.executeLiquidation(
            msg.sender,
            _user,
            _collateralCcy,
            _debtCcy,
            _debtMaturity
        );

        return true;
    }

    /**
     * @notice Execute forced repayment for a borrowing position if repayment date is over.
     * @param _collateralCcy Currency name to be used as collateral
     * @param _debtCcy Currency name to be used as debt
     * @param _debtMaturity The order book maturity of the debt
     * @param _user User's address
     * @return True if the execution of the operation succeeds
     */
    function executeForcedRepayment(
        bytes32 _collateralCcy,
        bytes32 _debtCcy,
        uint256 _debtMaturity,
        address _user
    )
        external
        override
        isNotLocked
        ifValidMaturity(_debtCcy, _debtMaturity)
        ifActive
        returns (bool)
    {
        LiquidationLogic.executeForcedRepayment(
            msg.sender,
            _user,
            _collateralCcy,
            _debtCcy,
            _debtMaturity
        );

        return true;
    }

    /**
     * @notice Rotates the order books. In this rotation, the following actions are happened.
     * - Updates the maturity at the beginning of the order book array.
     * - Moves the beginning of the order book array to the end of it (Market rotation).
     * - Update the compound factor in this contract using the next order book unit price. (Auto-rolls)
     * - Clean up the reserve fund contract
     *
     * @param _ccy Currency name in bytes32 of the selected order book
     */
    function rotateOrderBooks(bytes32 _ccy) external override nonReentrant ifActive {
        LendingMarketOperationLogic.rotateOrderBooks(_ccy);
        FundManagementLogic.cleanUpFunds(_ccy, address(reserveFund()));
    }

    /**
     * @notice Executes an emergency termination to stop the protocol. Once this function is executed,
     * the protocol cannot be run again. Also, users will only be able to redeem and withdraw.
     */
    function executeEmergencyTermination() external override ifActive onlyOwner {
        LendingMarketOperationLogic.executeEmergencyTermination();
    }

    /**
     * @notice Pauses the lending market by currency
     * @param _ccy Currency for pausing all lending markets
     * @return True if the execution of the operation succeeds
     */
    function pauseLendingMarket(
        bytes32 _ccy
    ) external override ifActive onlyOperator returns (bool) {
        LendingMarketOperationLogic.pauseLendingMarket(_ccy);
        return true;
    }

    /**
     * @notice Unpauses the lending market by currency
     * @param _ccy Currency name in bytes32
     * @return True if the execution of the operation succeeds
     */
    function unpauseLendingMarket(
        bytes32 _ccy
    ) external override ifActive onlyOperator returns (bool) {
        LendingMarketOperationLogic.unpauseLendingMarket(_ccy);
        return true;
    }

    /**
     * @notice Clean up all funds of the user
     * @param _user User's address
     */
    function cleanUpAllFunds(address _user) external override nonReentrant returns (bool) {
        FundManagementLogic.cleanUpAllFunds(_user);
        return true;
    }

    /**
     * @notice Clean up user funds used for lazy evaluation by the following actions:
     * - Removes order IDs that is already filled on the order book.
     * - Convert Future values that have already been auto-rolled to Genesis values.
     * @param _ccy Currency name in bytes32
     * @param _user User's address
     */
    function cleanUpFunds(
        bytes32 _ccy,
        address _user
    ) external override nonReentrant returns (uint256 totalActiveOrderCount) {
        return FundManagementLogic.cleanUpFunds(_ccy, _user);
    }

    /**
     * @notice Updates the min debt unit price for the selected currency.
     * @param _ccy Currency name in bytes32
     * @param _minDebtUnitPrice The min debt unit price
     */
    function updateMinDebtUnitPrice(
        bytes32 _ccy,
        uint256 _minDebtUnitPrice
    ) external override ifActive onlyOwner {
        LendingMarketOperationLogic.updateMinDebtUnitPrice(_ccy, _minDebtUnitPrice);
    }
}
