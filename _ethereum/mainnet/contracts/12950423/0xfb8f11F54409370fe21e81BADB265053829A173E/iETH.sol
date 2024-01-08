// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./AddressUpgradeable.sol";
import "./Base.sol";

/**
 * @title dForce's Lending Protocol Contract.
 * @notice iToken which wraps Ether.
 * @author dForce Team.
 */
contract iETH is Base {
    using AddressUpgradeable for address payable;

    // Unbalanced transfering in cash or cash would be returned.
    uint256 internal openCash;

    // Track variability of cash balance when ETH transfering in.
    modifier tracksValue() {
        openCash = msg.value;

        _;

        openCash = 0;
    }

    /**
     * @notice Expects to call only once to initialize a new market.
     * @param _name Token name.
     * @param _symbol Token symbol.
     * @param _controller Core controller contract address.
     * @param _interestRateModel Token interest rate model contract address.
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        IControllerInterface _controller,
        IInterestRateModelInterface _interestRateModel
    ) external initializer {
        require(
            address(_controller) != address(0),
            "initialize: controller address should not be zero address!"
        );
        require(
            address(_interestRateModel) != address(0),
            "initialize: interest model address should not be zero address!"
        );
        _initialize(_name, _symbol, 18, _controller, _interestRateModel);
    }

    /**
     * @dev ETH has been transfered in by `msg.value`, so just return amount directly.
     */
    function _doTransferIn(address _sender, uint256 _amount)
        internal
        override
        returns (uint256)
    {
        _sender;
        openCash = openCash.sub(_amount);
        return _amount;
    }

    /**
     * @dev Similar to EIP20 transfer, transfer eth to `_recipient`.
     */
    function _doTransferOut(address payable _recipient, uint256 _amount)
        internal
        override
    {
        _recipient.transfer(_amount);
    }

    /**
     * @dev Gets balance of this contract in terms of the underlying
     */
    function _getCurrentCash() internal view override returns (uint256) {
        return address(this).balance.sub(openCash);
    }

    /**
     * @dev Caller deposits assets into the market and `_recipient` receives iToken in exchange.
     * @param _recipient The account that would receive the iToken.
     */
    function mint(address _recipient)
        external
        payable
        nonReentrant
        tracksValue
        settleInterest
    {
        _mintInternal(_recipient, msg.value);
    }

    /**
     * @dev Caller redeems specified iToken from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemiToken The number of iToken to redeem.
     */
    function redeem(address _from, uint256 _redeemiToken)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemiToken,
            _redeemiToken.rmul(_exchangeRateInternal())
        );
    }

    /**
     * @dev Caller redeems specified underlying from `_from` to get underlying token.
     * @param _from The account that would burn the iToken.
     * @param _redeemUnderlying The number of underlying to redeem.
     */
    function redeemUnderlying(address _from, uint256 _redeemUnderlying)
        external
        nonReentrant
        settleInterest
    {
        _redeemInternal(
            _from,
            _redeemUnderlying.rdivup(_exchangeRateInternal()),
            _redeemUnderlying
        );
    }

    /**
     * @dev Caller borrows tokens from the protocol to their own address.
     * @param _borrowAmount The amount of the underlying token to borrow.
     */
    function borrow(uint256 _borrowAmount)
        external
        nonReentrant
        settleInterest
    {
        _borrowInternal(msg.sender, _borrowAmount);
    }

    /**
     * @dev Caller repays their own borrow.
     */
    function repayBorrow()
        external
        payable
        nonReentrant
        tracksValue
        settleInterest
    {
        _repayInternal(msg.sender, msg.sender, msg.value);
        if (openCash > 0) msg.sender.transfer(openCash);
    }

    /**
     * @dev Caller repays a borrow belonging to borrower.
     * @param _borrower the account with the debt being payed off.
     */
    function repayBorrowBehalf(address _borrower)
        external
        payable
        nonReentrant
        tracksValue
        settleInterest
    {
        _repayInternal(msg.sender, _borrower, msg.value);
        if (openCash > 0) msg.sender.transfer(openCash);
    }

    /**
     * @dev The caller liquidates the borrowers collateral.
     * @param _borrower The account whose borrow should be liquidated.
     * @param _assetCollateral The market in which to seize collateral from the borrower.
     */
    function liquidateBorrow(address _borrower, address _assetCollateral)
        external
        payable
        nonReentrant
        tracksValue
        settleInterest
    {
        _liquidateBorrowInternal(_borrower, msg.value, _assetCollateral);
    }

    /**
     * @dev Transfers this tokens to the liquidator.
     * @param _liquidator The account receiving seized collateral.
     * @param _borrower The account having collateral seized.
     * @param _seizeTokens The number of iTokens to seize.
     */
    function seize(
        address _liquidator,
        address _borrower,
        uint256 _seizeTokens
    ) external override nonReentrant {
        _seizeInternal(msg.sender, _liquidator, _borrower, _seizeTokens);
    }

    /**
     * @notice receive ETH, used for flashloan repay.
     */
    receive() external payable {
        require(
            msg.sender.isContract(),
            "receive: Only can call from a contract!"
        );
    }

    /**
     * @notice Calculates interest and update total borrows and reserves.
     * @dev Updates total borrows and reserves with any accumulated interest.
     */
    function updateInterest() external override returns (bool) {
        _updateInterest();
        return true;
    }

    /**
     * @dev Gets the newest exchange rate by accruing interest.
     */
    function exchangeRateCurrent() external nonReentrant returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal();
    }

    /**
     * @dev Calculates the exchange rate without accruing interest.
     */
    function exchangeRateStored() external view override returns (uint256) {
        return _exchangeRateInternal();
    }

    /**
     * @dev Gets the underlying balance of the `_account`.
     * @param _account The address of the account to query.
     */
    function balanceOfUnderlying(address _account) external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return _exchangeRateInternal().rmul(balanceOf[_account]);
    }

    /**
     * @dev Gets the user's borrow balance with the latest `borrowIndex`.
     */
    function borrowBalanceCurrent(address _account)
        external
        nonReentrant
        returns (uint256)
    {
        // Accrues interest.
        _updateInterest();

        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets the borrow balance of user without accruing interest.
     */
    function borrowBalanceStored(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _borrowBalanceInternal(_account);
    }

    /**
     * @dev Gets user borrowing information.
     */
    function borrowSnapshot(address _account)
        external
        view
        returns (uint256, uint256)
    {
        return (
            accountBorrows[_account].principal,
            accountBorrows[_account].interestIndex
        );
    }

    /**
     * @dev Gets the current total borrows by accruing interest.
     */
    function totalBorrowsCurrent() external returns (uint256) {
        // Accrues interest.
        _updateInterest();

        return totalBorrows;
    }

    /**
     * @dev Returns the current per-block borrow interest rate.
     */
    function borrowRatePerBlock() public view returns (uint256) {
        return
            interestRateModel.getBorrowRate(
                _getCurrentCash(),
                totalBorrows,
                totalReserves
            );
    }

    /**
     * @dev Returns the current per-block supply interest rate.
     *  Calculates the supply rate:
     *  underlying = totalSupply × exchangeRate
     *  borrowsPer = totalBorrows ÷ underlying
     *  supplyRate = borrowRate × (1-reserveFactor) × borrowsPer
     */
    function supplyRatePerBlock() external view returns (uint256) {
        // `_underlyingScaled` is scaled by 1e36.
        uint256 _underlyingScaled = totalSupply.mul(_exchangeRateInternal());
        if (_underlyingScaled == 0) return 0;
        uint256 _totalBorrowsScaled = totalBorrows.mul(BASE);

        return
            borrowRatePerBlock().tmul(
                BASE.sub(reserveRatio),
                _totalBorrowsScaled.rdiv(_underlyingScaled)
            );
    }

    /**
     * @dev Get cash balance of this iToken in the underlying token.
     */
    function getCash() external view returns (uint256) {
        return _getCurrentCash();
    }
}
