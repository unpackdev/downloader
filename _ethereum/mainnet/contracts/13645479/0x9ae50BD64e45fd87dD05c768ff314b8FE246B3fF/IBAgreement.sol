// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IComptroller.sol";
import "./IConverter.sol";
import "./ICToken.sol";
import "./IPriceFeed.sol";
import "./IPriceOracle.sol";

contract IBAgreementV2 is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable executor;
    address public immutable borrower;
    address public immutable governor;
    IComptroller public immutable comptroller;
    IERC20 public immutable collateral;
    uint256 public immutable collateralFactor;
    uint256 public immutable liquidationFactor;
    IPriceFeed public priceFeed;
    mapping(address => bool) public allowedMarkets;

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

    modifier marketAllowed(address cy) {
        require(allowedMarkets[cy], "market not allowed");
        _;
    }

    event AllowedMarketsUpdated(address, bool);

    /**
     * @dev Sets the values for {executor}, {borrower}, {governor}, {comptroller}, {collateral}, {priceFeed}, {collateralFactor}, and {liquidationFactor}.
     *
     * {collateral} must be a vanilla ERC20 token.
     *
     * All of these values are immutable: they can only be set once during construction.
     */
    constructor(
        address _executor,
        address _borrower,
        address _governor,
        address _comptroller,
        address _collateral,
        address _priceFeed,
        uint256 _collateralFactor,
        uint256 _liquidationFactor
    ) {
        executor = _executor;
        borrower = _borrower;
        governor = _governor;
        comptroller = IComptroller(_comptroller);
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
        return getHypotheticalDebtValue(address(0), 0);
    }

    /**
     * @notice Get the hypothetical debt in USD value of this contract after borrow
     * @param cy The cyToken
     * @param borrowAmount The hypothetical borrow amount
     * @return The hypothetical debt in USD value
     */
    function hypotheticalDebtUSD(ICToken cy, uint256 borrowAmount)
        external
        view
        returns (uint256)
    {
        return getHypotheticalDebtValue(address(cy), borrowAmount);
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
     * @param cy The cyToken
     * @param amount The borrow amount
     */
    function borrow(ICToken cy, uint256 amount) external nonReentrant onlyBorrower marketAllowed(address(cy)) {
        borrowInternal(cy, amount);
    }

    /**
     * @notice Borrow max from cyToken with current price
     * @param cy The cyToken
     */
    function borrowMax(ICToken cy) external nonReentrant onlyBorrower marketAllowed(address(cy)) {
        (, , uint256 borrowBalance, ) = cy.getAccountSnapshot(address(this));

        IPriceOracle oracle = IPriceOracle(comptroller.oracle());

        uint256 maxBorrowAmount = (this.collateralUSD() * 1e18) /
            oracle.getUnderlyingPrice(address(cy));
        require(maxBorrowAmount > borrowBalance, "undercollateralized");
        borrowInternal(cy, maxBorrowAmount - borrowBalance);
    }

    /**
     * @notice Withdraw the collateral if sufficient
     * @param amount The withdraw amount
     */
    function withdraw(uint256 amount) external onlyBorrower {
        require(
            this.debtUSD() <= this.hypotheticalCollateralUSD(amount),
            "undercollateralized"
        );
        collateral.safeTransfer(borrower, amount);
    }

    /**
     * @notice Repay the debts
     * @param cy The cyToken
     * @param amount The repay amount
     */
    function repay(ICToken cy, uint256 amount) external nonReentrant onlyBorrower marketAllowed(address(cy)) {
        IERC20 underlying = IERC20(cy.underlying());
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        repayInternal(cy, amount);
    }

    /**
     * @notice Seize the tokens
     * @param token The token
     * @param amount The amount
     */
    function seize(IERC20 token, uint256 amount) external onlyExecutor {
        if (address(token) == address(collateral)) {
            require(
                this.debtUSD() > this.liquidationThreshold(),
                "not liquidatable"
            );
        }
        token.safeTransfer(executor, amount);
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

    /**
     * @notice Set the allowed markets mapping
     * @param markets The address of cyTokens
     * @param states The states of allowance
     */
     function setAllowedMarkets(address[] calldata markets, bool[] calldata states) external onlyExecutor {
         require(markets.length == states.length, "length mismatch");
         for (uint256 i = 0; i < markets.length; i++) {
            if (states[i]) {
                require(comptroller.isMarketListed(markets[i]), "market not listed");
            }
            allowedMarkets[markets[i]] = states[i];
            emit AllowedMarketsUpdated(markets[i], states[i]);
         }
     }

    /* Internal functions */

    /**
     * @notice Get the current debt of this contract
     * @param borrowCy The hypothetical borrow cyToken
     * @param borrowAmount The hypothetical borrow amount
     * @return The borrow balance
     */
    function getHypotheticalDebtValue(address borrowCy, uint256 borrowAmount)
        internal
        view
        returns (uint256)
    {
        uint256 debt;
        address[] memory borrowedAssets = comptroller.getAssetsIn(address(this));
        IPriceOracle oracle = IPriceOracle(comptroller.oracle());
        for (uint256 i = 0; i < borrowedAssets.length; i++) {
            ICToken cy = ICToken(borrowedAssets[i]);
            uint256 amount;
            (, , uint256 borrowBalance, ) = cy.getAccountSnapshot(address(this));
            if (address(cy) == borrowCy) {
                amount = borrowBalance + borrowAmount;
            } else {
                amount = borrowBalance;
            }
            debt += (amount * oracle.getUnderlyingPrice(address(cy))) / 1e18;
        }
        return debt;
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
     * @param cy The cyToken
     * @param _amount The borrow amount
     */
    function borrowInternal(ICToken cy, uint256 _amount) internal {
        require(
            getHypotheticalDebtValue(address(cy), _amount) <= this.collateralUSD(),
            "undercollateralized"
        );
        require(cy.borrow(_amount) == 0, "borrow failed");
        IERC20(cy.underlying()).safeTransfer(borrower, _amount);
    }

    /**
     * @notice Repay the debts
     * @param _amount The repay amount
     */
    function repayInternal(ICToken cy, uint256 _amount) internal {
        IERC20(cy.underlying()).safeIncreaseAllowance(address(cy), _amount);
        require(cy.repayBorrow(_amount) == 0, "repay failed");
    }
}
