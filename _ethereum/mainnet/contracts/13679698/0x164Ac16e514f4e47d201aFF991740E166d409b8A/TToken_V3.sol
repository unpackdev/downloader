// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./data.sol";
import "./ITTokenStrategy.sol";
import "./ERC20.sol";

// Utils
import "./Address.sol";

// Interfaces
import "./ITToken_V3.sol";

// Libraries
import "./SafeERC20.sol";
import "./ERC165Checker.sol";
import "./RolesLib.sol";
import "./ReentryMods.sol";
import "./NumbersLib.sol";
import "./IWETH.sol";

// Storage
import "./token-storage.sol" as Storage;

/**
 * @notice This contract represents a lending pool for an asset within Teller protocol.
 * @author develop@teller.finance
 */
contract TToken_V3 is ITToken_V3, ReentryMods {
    /**
     * @notice To prevent the initialization of this TToken implementation contract, we call the initializer modifier.
     *  This prevents someone from:
     *      1. Becoming the ADMIN of the implementation contract
     *      2. Setting a strategy
     *      3. Calling a malicious function on the strategy that destroys the logic contract
     */
    constructor() initializer {}

    function() pure returns (Storage.Store storage) internal constant s =
        Storage.store;

    /* Public Functions */

    /**
     * @notice it returns the decimal places of the respective TToken
     * @return decimals of the token
     */
    function decimals() public view override returns (uint8) {
        return s().decimals;
    }

    /**
     * @notice The token that is the underlying asset for this Teller token.
     * @return ERC20 token that is the underlying asset
     */
    function underlying() public view override returns (ERC20) {
        return s().underlying;
    }

    /**
     * @notice The balance of an {account} denoted in underlying value.
     * @param account Address to calculate the underlying balance.
     * @return balance_ the balance of the account
     */
    function balanceOfUnderlying(address account)
        public
        override
        returns (uint256)
    {
        return _valueInUnderlying(balanceOf(account), exchangeRate());
    }

    /**
     * @notice It calculates the current scaled exchange rate for a whole Teller Token based of the underlying token balance.
     * @return rate_ The current exchange rate, scaled by the EXCHANGE_RATE_FACTOR.
     */
    function exchangeRate() public override returns (uint256 rate_) {
        if (totalSupply() == 0) {
            return EXCHANGE_RATE_FACTOR;
        }

        rate_ = (currentTVL() * EXCHANGE_RATE_FACTOR) / totalSupply();
    }

    /**
     * @notice It calculates the total supply of the underlying asset.
     * @return totalSupply_ the total supply denoted in the underlying asset.
     */
    function totalUnderlyingSupply() public override returns (uint256) {
        bytes memory data = _delegateStrategy(
            abi.encodeWithSelector(
                ITTokenStrategy.totalUnderlyingSupply.selector
            )
        );
        return abi.decode(data, (uint256));
    }

    /**
     * @notice It calculates the market state values across a given market.
     * @notice Returns values that represent the global state across the market.
     * @return totalSupplied Total amount of the underlying asset supplied.
     * @return totalBorrowed Total amount borrowed through loans.
     * @return totalRepaid The total amount repaid till the current timestamp.
     * @return totalInterestRepaid The total amount interest repaid till the current timestamp.
     * @return totalOnLoan Total amount currently deployed in loans.
     */
    function getMarketState()
        external
        override
        returns (
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 totalRepaid,
            uint256 totalInterestRepaid,
            uint256 totalOnLoan
        )
    {
        totalSupplied = totalUnderlyingSupply();
        totalBorrowed = s().totalBorrowed;
        totalRepaid = s().totalRepaid;
        totalInterestRepaid = s().totalInterestRepaid;
        totalOnLoan = totalBorrowed - totalRepaid;
    }

    /**
     * @notice Calculates the current Total Value Locked, denoted in the underlying asset, in the Teller Token pool.
     * @return tvl_ The value locked in the pool.
     *
     * Note: This value includes the amount that is on loan (including ones that were sent to EOAs).
     */
    function currentTVL() public override returns (uint256 tvl_) {
        tvl_ += totalUnderlyingSupply();
        tvl_ += s().totalBorrowed;
        tvl_ -= s().totalRepaid;
    }

    /**
     * @notice It validates whether supply to debt (StD) ratio is valid including the loan amount.
     * @param newLoanAmount the new loan amount to consider the StD ratio.
     * @return ratio_ The debt ratio for lending pool.
     */
    function debtRatioFor(uint256 newLoanAmount)
        external
        override
        returns (uint16 ratio_)
    {
        uint256 onLoan = s().totalBorrowed - s().totalRepaid;
        uint256 supplied = totalUnderlyingSupply() + onLoan;
        if (supplied > 0) {
            ratio_ = NumbersLib.ratioOf(onLoan + newLoanAmount, supplied);
        }
    }

    /**
     * @notice Called by the Teller Diamond contract when a loan has been taken out and requires funds.
     * @param recipient The account to send the funds to.
     * @param amount Funds requested to fulfil the loan.
     */
    function fundLoan(address recipient, uint256 amount)
        external
        override
        authorized(CONTROLLER, _msgSender())
    {
        // Call the strategy to ensure there is enough available funds to fund the loan
        _delegateStrategy(
            abi.encodeWithSelector(ITTokenStrategy.withdraw.selector, amount)
        );

        // Increase total borrowed amount
        s().totalBorrowed += amount;

        // Transfer tokens to recipient
        SafeERC20.safeTransfer(s().underlying, recipient, amount);
    }

    /**
     * @notice Called by the Teller Diamond contract when a loan has been repaid.
     * @param amount Funds deposited back into the pool to repay the principal amount of a loan.
     * @param interestAmount Interest value paid into the pool from a loan.
     */
    function repayLoan(uint256 amount, uint256 interestAmount)
        external
        override
        authorized(CONTROLLER, _msgSender())
    {
        s().totalRepaid += amount;
        s().totalInterestRepaid += interestAmount;
        emit LoanPaymentMade(_msgSender(), amount, interestAmount);
    }

    /**
     * @dev The tToken contract needs to have been granted sufficient allowance to transfer the amount being used to mint.
     * @notice Deposit underlying token amount into LP and mint tokens.
     * @param amount The amount of underlying tokens to use to mint.
     * @return Amount of TTokens minted.
     */
    function mint(uint256 amount)
        external
        payable
        override
        nonReentry(keccak256("MINT"))
        returns (uint256)
    {
        require(amount > 0, "Teller: cannot mint 0");

        // Get the exchange rate by static calling this contract.
        // It fails when ETH value is sent when delegate calling the `totalUnderlyingSupply` function on the strategy.
        uint256 exchangeRate = TToken_V3(address(this)).exchangeRate();
        // Calculate amount of tokens to mint
        uint256 mintAmount = _valueOfUnderlying(amount, exchangeRate);
        require(mintAmount > 0, "Teller: amount to be minted cannot be 0");

        if (msg.value > 0) {
            require(
                s().isWrappedNative,
                "Teller: value given for non native token"
            );
            require(msg.value == amount, "Teller: incorrect value");

            // Wrap the native token
            IWETH(address(s().underlying)).deposit{ value: msg.value }();
        } else {
            // Transfer tokens from lender
            SafeERC20.safeTransferFrom(
                s().underlying,
                _msgSender(),
                address(this),
                amount
            );
        }

        // Mint Teller token value of underlying
        _mint(_msgSender(), mintAmount);

        emit Mint(_msgSender(), mintAmount, amount);

        return mintAmount;
    }

    /**
     * @notice Redeem supplied Teller tokens for underlying value.
     * @param amount The amount of Teller tokens to redeem.
     */
    function redeem(uint256 amount)
        external
        override
        nonReentry(keccak256("REDEEM"))
    {
        require(amount > 0, "Teller: cannot withdraw 0");
        require(
            amount <= balanceOf(_msgSender()),
            "Teller: redeem amount exceeds balance"
        );

        // Accrue interest and calculate exchange rate
        uint256 underlyingAmount = _valueInUnderlying(amount, exchangeRate());
        require(
            underlyingAmount > 0,
            "Teller: underlying teller token value to be redeemed cannot be 0"
        );

        require(
            underlyingAmount <= totalUnderlyingSupply(),
            "Teller: redeem ttoken lp not enough supply"
        );

        // Burn Teller Tokens and transfer underlying
        _redeem(amount, underlyingAmount);
    }

    /**
     * @notice Redeem supplied underlying value.
     * @param amount The amount of underlying tokens to redeem.
     */
    function redeemUnderlying(uint256 amount)
        external
        override
        nonReentry(keccak256("REDEEM"))
    {
        require(amount > 0, "Teller: cannot withdraw 0");
        require(
            amount <= totalUnderlyingSupply(),
            "Teller: redeem ttoken lp not enough supply"
        );

        // Accrue interest and calculate exchange rate
        uint256 rate = exchangeRate();
        uint256 tokenValue = _valueOfUnderlying(amount, rate) + 1;

        // Make sure sender has adequate balance
        require(
            tokenValue <= balanceOf(_msgSender()),
            "Teller: redeem amount exceeds balance"
        );

        // Burn Teller Tokens and transfer underlying
        _redeem(tokenValue, amount);
    }

    /**
     * @dev Redeem an {amount} of Teller Tokens and transfers {underlyingAmount} to the caller.
     * @param amount Total amount of Teller Tokens to burn.
     * @param underlyingAmount Total amount of underlying asset tokens to transfer to caller.
     *
     * This function should only be called by {redeem} and {redeemUnderlying} after the exchange
     * rate and both token values have been calculated to use.
     */
    function _redeem(uint256 amount, uint256 underlyingAmount) internal {
        // Burn Teller tokens
        _burn(_msgSender(), amount);

        // Make sure enough funds are available to redeem
        _delegateStrategy(
            abi.encodeWithSelector(
                ITTokenStrategy.withdraw.selector,
                underlyingAmount
            )
        );

        // Transfer funds back to lender
        SafeERC20.safeTransfer(s().underlying, _msgSender(), underlyingAmount);

        emit Redeem(_msgSender(), amount, underlyingAmount);
    }

    /**
     * @notice Rebalances the funds controlled by Teller Token according to the current strategy.
     *
     * See {TTokenStrategy}.
     */
    function rebalance() public override {
        _delegateStrategy(
            abi.encodeWithSelector(ITTokenStrategy.rebalance.selector)
        );
    }

    /**
     * @notice Sets or updates a strategy to use for balancing funds.
     * @param strategy Address to the new strategy contract. Must implement the {ITTokenStrategy} interface.
     * @param initData Optional data to initialize the strategy.
     *
     * Requirements:
     *  - Sender must have ADMIN role
     */
    function setStrategy(address strategy, bytes calldata initData)
        external
        override
        authorized(ADMIN, _msgSender())
    {
        require(
            ERC165Checker.supportsInterface(
                strategy,
                type(ITTokenStrategy).interfaceId
            ),
            "Teller: strategy does not support ITTokenStrategy"
        );
        s().strategy = strategy;
        if (initData.length > 0) {
            _delegateStrategy(initData);
        }
        emit StrategySet(strategy, _msgSender());
    }

    /**
     * @notice Gets the strategy used for balancing funds.
     * @return address of the strategy contract
     */
    function getStrategy() external view override returns (address) {
        return s().strategy;
    }

    /**
     * @notice it initializes the Teller Token
     * @param admin address of the admin to the respective Teller Token
     * @param underlying address of the ERC20 token
     * @param isWrappedNative boolean indicating the underlying asset is the wrapped native token
     *
     * Requirements:
     *  - Underlying token must implement `name`, `symbol` and `decimals`
     */
    function initialize(
        address admin,
        address underlying,
        bool isWrappedNative
    ) external override initializer {
        require(
            Address.isContract(msg.sender),
            "Teller: controller not contract"
        );
        require(
            Address.isContract(underlying),
            "Teller: underlying token not contract"
        );

        RolesLib.grantRole(CONTROLLER, msg.sender);
        RolesLib.grantRole(ADMIN, admin);

        s().underlying = ERC20(underlying);
        __ERC20_init(
            string(abi.encodePacked("Teller ", s().underlying.name())),
            string(abi.encodePacked("t", s().underlying.symbol()))
        );
        s().decimals = s().underlying.decimals();
        s().isWrappedNative = isWrappedNative;
    }

    /**
     * @notice it retrieves the value of the underlying token
     * @param amount the amount of tokens to calculate the value of
     * @param rate the exchangeRate() to divide with the amount * exchange_rate_factor
     * @return value_ the underlying value of the token amount
     */
    function _valueOfUnderlying(uint256 amount, uint256 rate)
        internal
        pure
        returns (uint256 value_)
    {
        value_ = (amount * EXCHANGE_RATE_FACTOR) / rate;
    }

    /**
     * @notice it retrieves the value in the underlying tokens
     *
     */
    function _valueInUnderlying(uint256 amount, uint256 rate)
        internal
        pure
        returns (uint256 value_)
    {
        value_ = (amount * (rate)) / EXCHANGE_RATE_FACTOR;
    }

    /**
     * @notice Delegates data to call on the strategy contract.
     * @param callData Data to call the strategy contract with.
     *
     */
    function _delegateStrategy(bytes memory callData)
        internal
        returns (bytes memory)
    {
        return Address.functionDelegateCall(s().strategy, callData);
    }
}
