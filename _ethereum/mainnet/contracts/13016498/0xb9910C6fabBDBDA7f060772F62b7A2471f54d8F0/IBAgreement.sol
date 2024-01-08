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
    IConverter public converter;
    IPriceFeed public priceFeed;

    uint public constant collateralFactor = 0.5e18;
    uint public constant liquidationFactor = 0.75e18;

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
     * @dev Sets the values for {executor}, {borrower}, {governor}, {cy}, {collateral}, and {priceFeed}.
     *
     * {collateral} must be a vanilla ERC20 token and {cy} must be a valid IronBank market.
     *
     * All of these values are immutable: they can only be set once during construction.
     */
    constructor(address _executor, address _borrower, address _governor, address _cy, address _collateral, address _priceFeed) {
        executor = _executor;
        borrower = _borrower;
        governor = _governor;
        cy = ICToken(_cy);
        underlying = IERC20(ICToken(_cy).underlying());
        collateral = IERC20(_collateral);
        priceFeed = IPriceFeed(_priceFeed);

        require(_collateral == priceFeed.getToken(), "mismatch price feed");
    }

    /**
     * @notice Get the current debt of this contract
     * @return The borrow balance
     */
    function debt() external view returns (uint) {
        (,,uint borrowBalance,) = cy.getAccountSnapshot(address(this));
        return borrowBalance;
    }

    /**
     * @notice Get the current debt in USD value of this contract
     * @return The borrow balance in USD value
     */
    function debtUSD() external view returns (uint) {
        IPriceOracle oracle = IPriceOracle(IComptroller(cy.comptroller()).oracle());
        return this.debt() * oracle.getUnderlyingPrice(address(cy)) / 1e18;
    }

    /**
     * @notice Get the hypothetical debt in USD value of this contract after borrow
     * @param borrowAmount The hypothetical borrow amount
     * @return The hypothetical debt in USD value
     */
    function hypotheticalDebtUSD(uint borrowAmount) external view returns (uint) {
        IPriceOracle oracle = IPriceOracle(IComptroller(cy.comptroller()).oracle());
        return (this.debt() + borrowAmount) * oracle.getUnderlyingPrice(address(cy)) / 1e18;
    }

    /**
     * @notice Get the current collateral in USD value in this contract
     * @return The collateral in USD value
     */
    function collateralUSD() external view returns (uint) {
        uint normalizedAmount = collateral.balanceOf(address(this)) * 10**(18 - IERC20Metadata(address(collateral)).decimals());
        return normalizedAmount * priceFeed.getPrice() / 1e18 * collateralFactor / 1e18;
    }

    /**
     * @notice Get the hypothetical collateral in USD value in this contract after withdraw
     * @param withdrawAmount The hypothetical withdraw amount
     * @return The hypothetical collateral in USD value
     */
    function hypotheticalCollateralUSD(uint withdrawAmount) external view returns (uint) {
        uint normalizedAmount = (collateral.balanceOf(address(this)) - withdrawAmount) * 10**(18 - IERC20Metadata(address(collateral)).decimals());
        return normalizedAmount * priceFeed.getPrice() / 1e18 * collateralFactor / 1e18;
    }

    /**
     * @notice Get the lquidation threshold. It represents the max value of collateral that we recongized.
     * @dev If the debt is greater than the liquidation threshold, this agreement is liquidatable.
     * @return The lquidation threshold
     */
    function liquidationThreshold() external view returns (uint) {
        uint normalizedAmount = collateral.balanceOf(address(this)) * 10**(18 - IERC20Metadata(address(collateral)).decimals());
        return normalizedAmount * priceFeed.getPrice() / 1e18 * liquidationFactor / 1e18;
    }

    /**
     * @notice Borrow from cyToken if the collateral if sufficient
     * @param _amount The borrow amount
     */
    function borrow(uint _amount) external onlyBorrower {
        require(this.hypotheticalDebtUSD(_amount) <= this.collateralUSD(), "undercollateralized");
        require(cy.borrow(_amount) == 0, "borrow failed");
        underlying.safeTransfer(borrower, _amount);
    }

    /**
     * @notice Withdraw the collateral if sufficient
     * @param _amount The withdraw amount
     */
    function withdraw(uint _amount) external onlyBorrower {
        require(this.debtUSD() <= this.hypotheticalCollateralUSD(_amount), "undercollateralized");
        collateral.safeTransfer(borrower, _amount);
    }

    /**
     * @notice Repay the debts
     */
    function repay() external {
        uint _balance = underlying.balanceOf(address(this));
        underlying.safeApprove(address(cy), _balance);
        require(cy.repayBorrow(_balance) == 0, "repay failed");
    }

    /**
     * @notice Seize the accidentally deposited tokens
     * @param token The token
     * @param amount The amount
     */
    function seize(IERC20 token, uint amount) external onlyExecutor {
        require(token != collateral, "cannot seize collateral");
        token.safeTransfer(executor, amount);
    }

    /**
     * @notice Liquidate the collateral if it's under collateral
     * @param amount The liquidate amount
     */
    function liquidate(uint amount) external onlyExecutor {
        require(this.debtUSD() > this.liquidationThreshold(), "not liquidatable");
        require(address(converter) != address(0), "empty converter");
        require(converter.source() == address(collateral), "mismatch source token");
        require(converter.destination() == address(underlying), "mismatch destination token");

        // Convert the collateral to the underlying for repayment.
        collateral.safeTransfer(address(converter), amount);
        converter.convert(amount);

        // Repay the debts
        this.repay();
    }

    /**
     * @notice Set the converter for liquidation
     * @param _converter The new converter
     */
    function setConverter(address _converter) external onlyGovernor {
        require(_converter != address(0), "empty converter");
        converter = IConverter(_converter);
        require(converter.source() == address(collateral), "mismatch source token");
        require(converter.destination() == address(underlying), "mismatch destination token");
    }

    /**
     * @notice Set the price feed of the collateral
     * @param _priceFeed The new price feed
     */
    function setPriceFeed(address _priceFeed) external onlyGovernor {
        require(address(collateral) == IPriceFeed(_priceFeed).getToken(), "mismatch price feed");

        priceFeed = IPriceFeed(_priceFeed);
    }
}
