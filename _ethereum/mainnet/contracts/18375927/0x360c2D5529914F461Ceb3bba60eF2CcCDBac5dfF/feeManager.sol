// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "./Ownable.sol";

contract FeeManager is Ownable {
    uint256 private _transactionFeeWeekday;
    uint256 private _transactionFeeWeekend;
    uint256 private _firstDeposit;
    uint256 private _minDeposit;
    uint256 private _maxDeposit;
    uint256 private _minWithdraw;
    uint256 private _maxWithdraw;
    uint256 private _managementFeeRate;
    uint256 private _maxWeekendDepositPct;
    uint256 private _maxWeekendAggregatedDepositPct;
    uint256 private _minTxsFee = 25 * 10 ** 6;

    event SetTransactionFeeWeekday(uint256 transactionFee);
    event SetTransactionFeeWeekend(uint256 transactionFee);
    event SetFirstDeposit(uint256 firstDeposit);
    event SetMinDeposit(uint256 minDeposit);
    event SetMaxDeposit(uint256 maxDeposit);
    event SetMinWithdraw(uint256 minWithdraw);
    event SetMaxWithdraw(uint256 maxWithdraw);
    event SetManagementFeeRate(uint256 feeRate);
    event SetMaxWeekendDeposit(uint256 percentage);
    event SetMaxWeekendAggregatedDeposit(uint256 percentage);
    event UpdateMinTxsFee(uint256 fee);

    /**
     * @notice Initializes the FeeManager contract with initial values.
     * @dev Constructor for the FeeManager contract.
     * @param transactionFeeWeekday Fee for transactions on weekdays.
     * @param transactionFeeWeekend Fee for transactions on weekends.
     * @param maxWeekendDepositPct Max deposit percentage for weekends.
     * @param maxWeekendAggregatedDepositPct Max aggregated deposit percentage for weekends.
     * @param firstDeposit Initial deposit amount.
     * @param minDeposit Minimum deposit value.
     * @param maxDeposit Maximum deposit value.
     * @param minWithdraw Minimum withdrawal value.
     * @param maxWithdraw Maximum withdrawal value.
     * @param managementFeeRate Rate of the management fee.
     */
    constructor(
        uint256 transactionFeeWeekday,
        uint256 transactionFeeWeekend,
        uint256 maxWeekendDepositPct,
        uint256 maxWeekendAggregatedDepositPct,
        uint256 firstDeposit,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 minWithdraw,
        uint256 maxWithdraw,
        uint256 managementFeeRate
    ) {
        _transactionFeeWeekday = transactionFeeWeekday;
        _transactionFeeWeekend = transactionFeeWeekend;
        _firstDeposit = firstDeposit;
        _managementFeeRate = managementFeeRate;
        _maxWeekendDepositPct = maxWeekendDepositPct;
        _maxWeekendAggregatedDepositPct = maxWeekendAggregatedDepositPct;

        setMaxDeposit(maxDeposit);
        setMinDeposit(minDeposit);
        setMaxWithdraw(maxWithdraw);
        setMinWithdraw(minWithdraw);
    }

    /**
     * @notice Sets the transaction fee for weekdays.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for weekdays.
     */
    function setTransactionFeeWeekday(uint256 txsFee) external onlyOwner {
        _transactionFeeWeekday = txsFee;
        emit SetTransactionFeeWeekday(txsFee);
    }

    /**
     * @notice Sets the transaction fee for weekends.
     * @dev Only callable by the contract owner.
     * @param txsFee The transaction fee for weekends.
     */
    function setTransactionFeeWeekend(uint256 txsFee) external onlyOwner {
        _transactionFeeWeekend = txsFee;
        emit SetTransactionFeeWeekend(txsFee);
    }

    /**
     * @notice Sets the initial deposit amount.
     * @dev Only callable by the contract owner.
     * @param firstDeposit The initial deposit amount.
     */
    function setFirstDeposit(uint256 firstDeposit) external onlyOwner {
        _firstDeposit = firstDeposit;
        emit SetFirstDeposit(firstDeposit);
    }

    /**
     * @notice Sets the management fee rate.
     * @dev Only callable by the contract owner.
     * @param feeRate The management fee rate.
     */
    function setManagementFeeRate(uint256 feeRate) external onlyOwner {
        _managementFeeRate = feeRate;
        emit SetManagementFeeRate(feeRate);
    }

    /**
     * @notice Sets the maximum aggregated deposit percentage for weekends.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum aggregated deposit percentage.
     */
    function setMaxWeekendAggregatedDepositPct(
        uint256 percentage
    ) external onlyOwner {
        _maxWeekendAggregatedDepositPct = percentage;
        emit SetMaxWeekendAggregatedDeposit(percentage);
    }

    /**
     * @notice Sets the maximum deposit percentage for weekends.
     * @dev Only callable by the contract owner.
     * @param percentage The maximum deposit percentage for weekends.
     */
    function setMaxWeekendDepositPct(uint256 percentage) external onlyOwner {
        _maxWeekendDepositPct = percentage;
        emit SetMaxWeekendDeposit(percentage);
    }

    /**
     * @notice Sets the minimum transaction fee.
     * @dev Only callable by the contract owner.
     * @param _fee The minimum transaction fee.
     */
    function setMinTxsFee(uint256 _fee) external onlyOwner {
        _minTxsFee = _fee;
        emit UpdateMinTxsFee(_fee);
    }

    /**
     * @notice Gets the transaction fee for weekdays.
     * @dev View function to get the weekday transaction fee.
     * @return The weekday transaction fee.
     */
    function getTxFeeWeekday() external view returns (uint256) {
        return _transactionFeeWeekday;
    }

    /**
     * @notice Gets the transaction fee for weekends.
     * @dev View function to get the weekend transaction fee.
     * @return The weekend transaction fee.
     */
    function getTxFeeWeekend() external view returns (uint256) {
        return _transactionFeeWeekend;
    }

    /**
     * @notice Gets the minimum and maximum deposit values.
     * @dev View function to get deposit limits.
     * @return minDeposit The minimum deposit limit.
     * @return maxDeposit The maximum deposit limit.
     */
    function getMinMaxDeposit()
        external
        view
        returns (uint256 minDeposit, uint256 maxDeposit)
    {
        minDeposit = _minDeposit;
        maxDeposit = _maxDeposit;
    }

    /**
     * @notice Gets the minimum and maximum withdrawal values.
     * @dev View function to get withdrawal limits.
     * @return minWithdraw The minimum withdrawal limit.
     * @return maxWithdraw The maximum withdrawal limit.
     */
    function getMinMaxWithdraw()
        external
        view
        returns (uint256 minWithdraw, uint256 maxWithdraw)
    {
        minWithdraw = _minWithdraw;
        maxWithdraw = _maxWithdraw;
    }

    /**
     * @notice Gets the management fee rate.
     * @dev View function to retrieve the management fee rate.
     * @return feeRate The current management fee rate.
     */
    function getManagementFeeRate() external view returns (uint256 feeRate) {
        feeRate = _managementFeeRate;
    }

    /**
     * @notice Gets the first deposit amount.
     * @dev View function to retrieve the first deposit value.
     * @return firstDeposit The value of the initial deposit.
     */
    function getFirstDeposit() external view returns (uint256 firstDeposit) {
        firstDeposit = _firstDeposit;
    }

    /**
     * @notice Gets the maximum deposit percentages for weekends.
     * @dev View function to retrieve weekend deposit limits.
     * @return maxDepositPct The maximum single deposit percentage for weekends.
     * @return maxDepositAggregatedPct The maximum aggregated deposit percentage for weekends.
     */
    function getMaxWeekendDepositPct()
        external
        view
        returns (uint256 maxDepositPct, uint256 maxDepositAggregatedPct)
    {
        maxDepositPct = _maxWeekendDepositPct;
        maxDepositAggregatedPct = _maxWeekendAggregatedDepositPct;
    }

    /**
     * @notice Gets the minimum transaction fee.
     * @dev View function to retrieve the minimum transaction fee.
     * @return The current minimum transaction fee.
     */
    function getMinTxsFee() external view returns (uint256) {
        return _minTxsFee;
    }

    /**
     * @notice Sets the minimum deposit amount.
     * @dev Only callable by the contract owner.
     * @param minDeposit The new minimum deposit value.
     */
    function setMinDeposit(uint256 minDeposit) public onlyOwner {
        require(minDeposit < _maxDeposit, "deposit min should lt max");
        _minDeposit = minDeposit;
        emit SetMinDeposit(minDeposit);
    }

    /**
     * @notice Sets the maximum deposit amount.
     * @dev Only callable by the contract owner.
     * @param maxDeposit The new maximum deposit value.
     */
    function setMaxDeposit(uint256 maxDeposit) public onlyOwner {
        require(_minDeposit < maxDeposit, "deposit max should gt min");
        _maxDeposit = maxDeposit;
        emit SetMaxDeposit(maxDeposit);
    }

    /**
     * @notice Sets the minimum withdrawal amount.
     * @dev Only callable by the contract owner.
     * @param minWithdraw The new minimum withdrawal value.
     */
    function setMinWithdraw(uint256 minWithdraw) public onlyOwner {
        require(minWithdraw < _maxWithdraw, "withdraw min should lt max");
        _minWithdraw = minWithdraw;
        emit SetMinWithdraw(minWithdraw);
    }

    /**
     * @notice Sets the maximum withdrawal amount.
     * @dev Only callable by the contract owner.
     * @param maxWithdraw The new maximum withdrawal value.
     */
    function setMaxWithdraw(uint256 maxWithdraw) public onlyOwner {
        require(_minWithdraw < maxWithdraw, "withdraw max should gt min");
        _maxWithdraw = maxWithdraw;
        emit SetMaxWithdraw(maxWithdraw);
    }
}
