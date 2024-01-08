// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IComptroller.sol";
import "./IConverter.sol";
import "./ICToken.sol";
import "./IPriceFeed.sol";
import "./IPriceOracle.sol";

contract IBAgreement {
    using SafeERC20 for IERC20;

    address public immutable executor;
    address public immutable borrower;
    address public immutable governor;
    ICToken public immutable cy;
    IERC20 public immutable underlying;
    IERC20 public immutable collateral;
    uint256 public immutable collateralFactor;
    uint256 public immutable liquidationFactor;
    IConverter public converter;
    IPriceFeed public priceFeed;

    modifier onlyBorrower() {
        require(msg.sender == borrower, "caller is not the borrower");
        _;
    }

    modifier onlyExecutor() {
        require(msg.sender == executor, "caller is not the executor");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == governor, "caller is not the governor");
        _;
    }

    /**
     * @dev Sets the values for {executor}, {borrower}, {governor}, {cy}, {collateral}, {priceFeed}, {collateralFactor}, and {liquidationFactor}.
     *
     * {collateral} must be a vanilla ERC20 token and {cy} must be a valid IronBank market.
     *
     * All of these values are immutable: they can only be set once during construction.
     */
    constructor(
        address _executor,
        address _borrower,
        address _governor,
        address _cy,
        address _collateral,
        address _priceFeed,
        uint256 _collateralFactor,
        uint256 _liquidationFactor
    ) {
        executor = _executor;
        borrower = _borrower;
        governor = _governor;
        cy = ICToken(_cy);
        underlying = IERC20(ICToken(_cy).underlying());
        collateral = IERC20(_collateral);
        priceFeed = IPriceFeed(_priceFeed);
        collateralFactor = _collateralFactor;
        liquidationFactor = _liquidationFactor;

        require(_collateral == priceFeed.getToken(), "mismatch price feed");
        require(
            _collateralFactor > 0 && _collateralFactor <= 1e18,
            "invalid collateral factor"
        );
        require(
            _liquidationFactor >= _collateralFactor &&
                _liquidationFactor <= 1e18,
            "invalid liquidation factor"
        );
    }

    /**
     * @notice Get the current debt in USD value of this contract
     * @return The borrow balance in USD value
     */
    function debtUSD() external view returns (uint256) {
        return getHypotheticalDebtValue(0);
    }

    /**
     * @notice Get the hypothetical debt in USD value of this contract after borrow
     * @param borrowAmount The hypothetical borrow amount
     * @return The hypothetical debt in USD value
     */
    function hypotheticalDebtUSD(uint256 borrowAmount)
        external
        view
        returns (uint256)
    {
        return getHypotheticalDebtValue(borrowAmount);
    }

    /**
     * @notice Get the max value in USD to use for borrow in this contract
     * @return The USD value
     */
    function collateralUSD() external view returns (uint256) {
        uint256 value = getHypotheticalCollateralValue(0);
        return (value * collateralFactor) / 1e18;
    }

    /**
     * @notice Get the hypothetical max value in USD to use for borrow in this contract after withdraw
     * @param withdrawAmount The hypothetical withdraw amount
     * @return The hypothetical USD value
     */
    function hypotheticalCollateralUSD(uint256 withdrawAmount)
        external
        view
        returns (uint256)
    {
        uint256 value = getHypotheticalCollateralValue(withdrawAmount);
        return (value * collateralFactor) / 1e18;
    }

    /**
     * @notice Get the lquidation threshold. It represents the max value of collateral that we recongized.
     * @dev If the debt is greater than the liquidation threshold, this agreement is liquidatable.
     * @return The lquidation threshold
     */
    function liquidationThreshold() external view returns (uint256) {
        uint256 value = getHypotheticalCollateralValue(0);
        return (value * liquidationFactor) / 1e18;
    }

    /**
     * @notice Borrow from cyToken if the collateral is sufficient
     * @param _amount The borrow amount
     */
    function borrow(uint256 _amount) external onlyBorrower {
        borrowInternal(_amount);
    }

    /**
     * @notice Borrow max from cyToken with current price
     */
    function borrowMax() external onlyBorrower {
        (, , uint256 borrowBalance, ) = cy.getAccountSnapshot(address(this));

        IPriceOracle oracle = IPriceOracle(
            IComptroller(cy.comptroller()).oracle()
        );

        uint256 maxBorrowAmount = (this.collateralUSD() * 1e18) /
            oracle.getUnderlyingPrice(address(cy));
        require(maxBorrowAmount > borrowBalance, "undercollateralized");
        borrowInternal(maxBorrowAmount - borrowBalance);
    }

    /**
     * @notice Withdraw the collateral if sufficient
     * @param _amount The withdraw amount
     */
    function withdraw(uint256 _amount) external onlyBorrower {
        require(
            this.debtUSD() <= this.hypotheticalCollateralUSD(_amount),
            "undercollateralized"
        );
        collateral.safeTransfer(borrower, _amount);
    }

    /**
     * @notice Repay the debts
     * @param _amount The repay amount
     */
    function repay(uint256 _amount) external onlyBorrower {
        underlying.safeTransferFrom(msg.sender, address(this), _amount);
        repayInternal(_amount);
    }

    /**
     * @notice Seize the accidentally deposited tokens
     * @param token The token
     * @param amount The amount
     */
    function seize(IERC20 token, uint256 amount) external onlyExecutor {
        token.safeTransfer(executor, amount);
    }

    /**
     * @notice Liquidate the collateral if it's under collateral
     * @param amount The liquidate amount
     */
    function liquidate(uint256 amount) external onlyExecutor {
        require(
            this.debtUSD() > this.liquidationThreshold(),
            "not liquidatable"
        );
        require(address(converter) != address(0), "empty converter");
        require(
            converter.source() == address(collateral),
            "mismatch source token"
        );
        require(
            converter.destination() == address(underlying),
            "mismatch destination token"
        );

        // Convert the collateral to the underlying for repayment.
        collateral.safeTransfer(address(converter), amount);
        converter.convert(amount);

        // Repay the debts
        repayInternal(underlying.balanceOf(address(this)));
    }

    /**
     * @notice Set the converter for liquidation
     * @param _converter The new converter
     */
    function setConverter(address _converter) external onlyGovernor {
        require(_converter != address(0), "empty converter");
        converter = IConverter(_converter);
        require(
            converter.source() == address(collateral),
            "mismatch source token"
        );
        require(
            converter.destination() == address(underlying),
            "mismatch destination token"
        );
    }

    /**
     * @notice Set the price feed of the collateral
     * @param _priceFeed The new price feed
     */
    function setPriceFeed(address _priceFeed) external onlyGovernor {
        require(
            address(collateral) == IPriceFeed(_priceFeed).getToken(),
            "mismatch price feed"
        );

        priceFeed = IPriceFeed(_priceFeed);
    }

    /* Internal functions */

    /**
     * @notice Get the current debt of this contract
     * @param borrowAmount The hypothetical borrow amount
     * @return The borrow balance
     */
    function getHypotheticalDebtValue(uint256 borrowAmount)
        internal
        view
        returns (uint256)
    {
        (, , uint256 borrowBalance, ) = cy.getAccountSnapshot(address(this));
        uint256 amount = borrowBalance + borrowAmount;
        IPriceOracle oracle = IPriceOracle(
            IComptroller(cy.comptroller()).oracle()
        );
        return (amount * oracle.getUnderlyingPrice(address(cy))) / 1e18;
    }

    /**
     * @notice Get the hypothetical collateral in USD value in this contract after withdraw
     * @param withdrawAmount The hypothetical withdraw amount
     * @return The hypothetical collateral in USD value
     */
    function getHypotheticalCollateralValue(uint256 withdrawAmount)
        internal
        view
        returns (uint256)
    {
        uint256 amount = collateral.balanceOf(address(this)) - withdrawAmount;
        uint8 decimals = IERC20Metadata(address(collateral)).decimals();
        uint256 normalizedAmount = amount * 10**(18 - decimals);
        return (normalizedAmount * priceFeed.getPrice()) / 1e18;
    }

    /**
     * @notice Borrow from cyToken
     * @param _amount The borrow amount
     */
    function borrowInternal(uint256 _amount) internal {
        require(
            getHypotheticalDebtValue(_amount) <= this.collateralUSD(),
            "undercollateralized"
        );
        require(cy.borrow(_amount) == 0, "borrow failed");
        underlying.safeTransfer(borrower, _amount);
    }

    /**
     * @notice Repay the debts
     * @param _amount The repay amount
     */
    function repayInternal(uint256 _amount) internal {
        underlying.safeIncreaseAllowance(address(cy), _amount);
        require(cy.repayBorrow(_amount) == 0, "repay failed");
    }
}
