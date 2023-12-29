// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.23;

// This is developed with OpenZeppelin contracts v4.9.3.
import "./AccessControlUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IERC20MetadataUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

// This is developed with Chainlink contracts v0.7.1.
import "./AggregatorV3Interface.sol";

import "./Discounts.sol";
import "./IRDGXTokenVesting.sol";

/**
 * @title Radiologex (RDGX) token sale.
 */
contract RDGXTokenSale is AccessControlUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // _______________ Libraries _______________

    using Discounts for Discounts.DiscountList;

    using SafeERC20Upgradeable for IERC20Upgradeable;

    // _______________ Structs _______________

    struct SalePhase {
        uint256 start;
        uint256 end;
        uint256 totalSupply;
        uint256 initialSupply;
    }

    // _______________ Constants _______________

    /// @notice The role of a pauser, who is responsible for pausing and unpausing all token transfers.
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant ALLOWLISTER_ROLE = keccak256("ALLOWLISTER_ROLE");

    bytes32 public constant ALLOWLISTED_ROLE = keccak256("ALLOWLISTED_ROLE");

    bytes32 public constant PURCHASE_WITH_FIAT_CALLER_ROLE = keccak256("PURCHASE_WITH_FIAT_CALLER_ROLE");

    uint256 public constant RDGX_TOKEN_DECIMALS = 1E18;

    uint256 private constant PRIVATE_SALE_INITIAL_SUPPLY = 2_500000 * RDGX_TOKEN_DECIMALS;

    uint256 private constant PUBLIC_SALE_INITIAL_SUPPLY = 20_000000 * RDGX_TOKEN_DECIMALS;

    uint256 private constant INITIAL_PUBLIC_MAX_RDGX_PER_ACCOUNT = 300000 * RDGX_TOKEN_DECIMALS;

    uint256 public constant USD_PRICE_DECIMALS = 1E8;

    uint256 public constant DUST = 70000 wei;

    // _______________ Storage _______________

    SalePhase public privateSale;

    SalePhase public publicSale;

    // A token => Its price feed.
    mapping(address => address) public priceFeeds;

    mapping(address => uint256) public tokenDecimals;

    mapping(address => int256) public lowerPriceLimits;

    Discounts.DiscountList private privateDiscounts;

    Discounts.DiscountList private publicDiscounts;

    uint256 public publicMaxRDGXPerAccount;

    uint256 public minRDGXPurchase;

    // An account => The total amount of RDGX tokens publicly purchased by the account.
    mapping(address => uint256) public rdgxPurchasedPublicly;

    address payable public beneficiary;

    IRDGXTokenVesting public rdgxTokenVesting;

    // _______________ Errors _______________

    error AdminEqZeroAddr();

    error IncorrectPrivateOrPublicSaleTime();

    error IncorrectSupply();

    error BeneficiaryEqZeroAddr();

    error PublicMaxRDGXPerAccountEqZero();

    error TooMuchRDGXAmount(uint256 _rdgxAmount, uint256 _purchased, uint256 _publicMaxRDGXPerAccount);

    error InsufficientRDGXForSale(uint256 _rdgxAmount, uint256 _totalSupply);

    error RDGXAmountLTMinRDGXPurchase(uint256 _rdgxAmount, uint256 _minRDGXPurchase);

    error ReceivedETHWhenPurchaseForToken(uint256 _ethAmount);

    error TooSmallRDGXAmount(uint256 _rdgxAmount, address _token);

    error NotEnoughETH(uint256 _rdgxPrice, uint256 _ethAmount);

    error OnlyWhenPrivateOrPublicSale();

    error PriceFeedEqZeroAddr(address _priceFeed);

    error OnlyUSDPriceFeed(address _priceFeed);

    error TooManyOrZeroDecimals(address _token, uint256 _decimals);

    error LowerPriceLimitLTOne(int256 _lowerPriceLimit);

    error TooHighLowerPriceLimit(int256 _lowerPriceLimit, int256 _price);

    error UnknownToken(address _token);

    error TooLowPrice(int256 _price, int256 _lowerPriceLimit, address _priceFeed);

    error RDGXTokenVestingEqZeroAddr();

    error IncorrectSalePeriod(uint256 _current, uint256 _start, uint256 _end, uint256 _pubStartOrPrivEnd);

    error AccountAlreadyAllowed(address _account);

    error AccountNotAllowed(address _account);

    error OnlyAfterPublicSaleEnd(uint256 _current, uint256 _publicSaleEnd);

    // _______________ Events _______________

    // prettier-ignore
    event RDGXPurchased(
        address indexed _purchaser,
        uint256 _rdgxAmount,
        address indexed _token,
        uint256 _rdgxPrice
    );

    event RDGXPurchasedWithFiatAdded(address indexed _purchaser, uint256 _rdgxAmount);

    event BeneficiarySet(address indexed _beneficiary);

    event RDGXTokenVestingSet(address indexed _rdgxTokenVesting);

    event PrivateSalePeriodSet(uint256 _start, uint256 _end);

    event PublicSalePeriodSet(uint256 _start, uint256 _end);

    event SupplySet(uint256 _initialSupply, uint256 _totalSupply, bool _privatePhase);

    event MinRDGXPurchaseSet(uint256 _minRDGXPurchase);

    event PriceFeedSet(address indexed _token, address indexed _priceFeed, int256 _lowerPriceLimit);

    event DiscountsSet(bool _privatePhase);

    event LowerPriceLimitSet(address indexed _token, int256 _lowerPriceLimit);

    event PublicMaxRDGXPerAccountSet(uint256 _publicMaxRDGXPerAccount);

    event RemainingETHWithdrawn(address indexed beneficiary, uint256 _remainingETH);

    // _______________ Initializer _______________

    /**
     * @notice Warning. The address of the RDGX token vesting should be set using `setRDGXTokenVesting()` after
     * initialization.
     */
    // prettier-ignore
    function initialize(
        address _administrator,
        address payable _beneficiary,
        uint256 _privateSaleStart,
        uint256 _privateSaleEnd,
        uint256 _publicSaleStart,
        uint256 _publicSaleEnd,
        Discounts.Discount[] calldata _privateDiscounts,
        Discounts.Discount[] calldata _publicDiscounts
    ) external initializer {
        if (_administrator == address(0)) revert AdminEqZeroAddr();
        if (
            _privateSaleStart < block.timestamp || _privateSaleStart >= _privateSaleEnd ||
                _publicSaleStart <= _privateSaleEnd || _publicSaleStart >= _publicSaleEnd
        ) revert IncorrectPrivateOrPublicSaleTime();

        validateNSetBeneficiary(_beneficiary);
        validateNSetPublicMaxRDGXPerAccount(INITIAL_PUBLIC_MAX_RDGX_PER_ACCOUNT);

        privateDiscounts.setDiscounts(_privateDiscounts);
        publicDiscounts.setDiscounts(_publicDiscounts);

        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();

        _grantRole(DEFAULT_ADMIN_ROLE, _administrator);

        SalePhase storage refSalePhase = privateSale;
        refSalePhase.start = _privateSaleStart;
        refSalePhase.end = _privateSaleEnd;
        emit PrivateSalePeriodSet(_privateSaleStart, _privateSaleEnd);
        refSalePhase.totalSupply = PRIVATE_SALE_INITIAL_SUPPLY;
        refSalePhase.initialSupply = PRIVATE_SALE_INITIAL_SUPPLY;
        emit SupplySet(PRIVATE_SALE_INITIAL_SUPPLY, PUBLIC_SALE_INITIAL_SUPPLY, true);

        refSalePhase = publicSale;
        refSalePhase.start = _publicSaleStart;
        refSalePhase.end = _publicSaleEnd;
        emit PublicSalePeriodSet(_publicSaleStart, _publicSaleEnd);
        refSalePhase.totalSupply = PUBLIC_SALE_INITIAL_SUPPLY;
        refSalePhase.initialSupply = PUBLIC_SALE_INITIAL_SUPPLY;
        emit SupplySet(PUBLIC_SALE_INITIAL_SUPPLY, PUBLIC_SALE_INITIAL_SUPPLY, false);

        // minRDGXPurchase = 0;
        emit MinRDGXPurchaseSet(0);
    }

    // _______________ External functions _______________

    /**
     * @notice Purchases RDGX tokens in the amount of `_rdgxAmount` for `_token` tokens at the price calcualted with
     * usage of the Chainlink oracle.
     *
     * Transfers payment for RDGX tokens to the beneficiary (`beneficiary`).
     *
     * When RDGX tokens are purchased, they are not transferred to the caller immediately. This contract writes
     * the amount of RDGX tokens to the vesting contract (`rdgxTokenVesting`). The acquirer can claim the tokens
     * on the vesting contract at a later date during the vesting period which starts after the token sale.
     *
     * Emits an `RDGXPurchased` event.
     *
     * Requirements:
     * - This contract should not be paused.
     * - The private or public sale phase should be active.
     * - `_token` should be the supported token for which the Chainlink price feed is set (`priceFeeds`) or
     *   the zero address. If `_token` is the zero address, then it is considered an RDGX purchase with Ether,
     *   in which case `msg.value` should be greater than zero. Otherwise, `_rdgxAmount` should be greater than zero.
     * - There should still be enough RDGX tokens on sale.
     * - ...
     *
     * @param _rdgxAmount The amount of RDGX tokens which the caller would like to purchase.
     * @param _token The supported token for which the caller would like to purchase RDGX tokens. Or the zero address
     * if the caller would like to purchase RDGX tokens for Ether.
     *
     * @notice The sale of RDGX tokens is divided into two phases: first private, then public. Between the public and
     * private phases, there is the cliff period. `purchaseRDGX()` purchases RDGX tokens during the private and
     * public phases, and reverts at the cliff period or other times. The phases differ in their period, total supply
     * and discounts.
     */
    // prettier-ignore
    function purchaseRDGX(
        uint256 _rdgxAmount,
        address _token
    ) external payable whenNotPaused onlyRole(ALLOWLISTED_ROLE) nonReentrant {
        if (_rdgxAmount < minRDGXPurchase)
            revert RDGXAmountLTMinRDGXPurchase(_rdgxAmount, minRDGXPurchase);

        // Determining whether the private of public sale is now and subtract of `_rdgxAmount` from the total supply.
        bool privatePhase = determinePhaseNDecreaseTotalSupply(_rdgxAmount);

        address purchaser = _msgSender();
        // Limiting the maximum of RDGX tokens per account for the public sale.
        if (!privatePhase) {
            uint256 purchased = rdgxPurchasedPublicly[purchaser] + _rdgxAmount;
            if (purchased > publicMaxRDGXPerAccount)
                revert TooMuchRDGXAmount(_rdgxAmount, purchased - _rdgxAmount, publicMaxRDGXPerAccount);
            rdgxPurchasedPublicly[purchaser] = purchased;
        }

        // Calculating the RDGX price and transferring payment to `beneficiary`.
        uint256 rdgxPrice;
        if (_token != address(0)) { // A stablecoin or a token.
            if (msg.value > 0)
                revert ReceivedETHWhenPurchaseForToken(msg.value);

            rdgxPrice = calcDiscountedPrice(_rdgxAmount, calcPrice(_rdgxAmount, _token), privatePhase);
            if (rdgxPrice == 0)
                revert TooSmallRDGXAmount(_rdgxAmount, _token);

            IERC20Upgradeable(_token).safeTransferFrom(purchaser, beneficiary, rdgxPrice);
        } else { // Ether.
            rdgxPrice = calcDiscountedPrice(_rdgxAmount, calcPrice(_rdgxAmount, _token), privatePhase);
            if (rdgxPrice > msg.value)
                revert NotEnoughETH(rdgxPrice, msg.value);
            if (rdgxPrice == 0 wei)
                revert TooSmallRDGXAmount(_rdgxAmount, _token);

            AddressUpgradeable.sendValue(beneficiary, rdgxPrice);

            // Returning Ether if more than necessary.
            if (msg.value > rdgxPrice) {
                uint256 remainder = msg.value - rdgxPrice;
                if (remainder > DUST)
                    AddressUpgradeable.sendValue(payable(purchaser), remainder);
            }
        }

        // Writing the purchased amount to the vesting.
        if (privatePhase)
            rdgxTokenVesting.addPrivatePurchase(purchaser, _rdgxAmount);
        else
            rdgxTokenVesting.addPublicPurchase(purchaser, _rdgxAmount);
        emit RDGXPurchased(purchaser, _rdgxAmount, _token, rdgxPrice);
    }

    // ____ Administrative functionality ___

    /**
     * @notice Adds RDGX tokens in the amount of `_rdgxAmount` for `_purchaser`.
     *
     * It is used by the back end when a user purchases RDGX tokens with fiat money through a bank.
     *
     * When RDGX tokens are purchased, they are not transferred to the caller immediately. This contract writes
     * the amount of RDGX tokens to the vesting contract (`rdgxTokenVesting`). The acquirer can claim the tokens
     * on the vesting contract at a later date during the vesting period which starts after the token sale.
     *
     * Emits an `RDGXPurchasedWithFiatAdded` event.
     *
     * Requirements:
     * - The caller should have the role `PURCHASE_WITH_FIAT_CALLER_ROLE`.
     * - The private or public sale phase should be active.
     * - There should still be enough RDGX tokens on sale.
     *
     * @param _purchaser An address of the purchaser of RDGX tokens for fiat money.
     * @param _rdgxAmount The amount of RDGX tokens which `_purchaser` has purchased with fiat money.
     *
     * @notice The sale of RDGX tokens is divided into two phases: first private, then public. Between the public and
     * private phases, there is the cliff period. `purchaseRDGXWithFiat()` can be used during the private and public
     * phases, and reverts at the cliff period or other times.
     */
    // prettier-ignore
    function addRDGXPurchasedWithFiat(address _purchaser, uint256 _rdgxAmount)
        external
        onlyRole(PURCHASE_WITH_FIAT_CALLER_ROLE)
    {
        if (
            /*
             * Determining whether the private of public sale is now and subtract of `_rdgxAmount` from
             * the total supply.
             */
            determinePhaseNDecreaseTotalSupply(_rdgxAmount)
        ) // The private phase.
            rdgxTokenVesting.addPrivatePurchase(_purchaser, _rdgxAmount);
        else { // The public phase.
            // Used to limit the maximum of RDGX tokens per account for manual `purchaseRDGX()` when the public sale.
            rdgxPurchasedPublicly[_purchaser] += _rdgxAmount;

            rdgxTokenVesting.addPublicPurchase(_purchaser, _rdgxAmount);
        }
        emit RDGXPurchasedWithFiatAdded(_purchaser, _rdgxAmount);
    }

    // prettier-ignore
    function allow(address[] calldata _accounts) external onlyRole(ALLOWLISTER_ROLE) {
        uint256 len = _accounts.length;
        for (uint256 i = 0; i < len; ++i) {
            if (hasRole(ALLOWLISTED_ROLE, _accounts[i]))
                revert AccountAlreadyAllowed(_accounts[i]);

            _grantRole(ALLOWLISTED_ROLE, _accounts[i]);
        }
    }

    // prettier-ignore
    function disallow(address[] calldata _accounts) external onlyRole(ALLOWLISTER_ROLE) {
        uint256 len = _accounts.length;
        for (uint256 i = 0; i < len; ++i) {
            if (!hasRole(ALLOWLISTED_ROLE, _accounts[i]))
                revert AccountNotAllowed(_accounts[i]);

            _revokeRole(ALLOWLISTED_ROLE, _accounts[i]);
        }
    }

    // prettier-ignore
    function withdrawRemainingETH() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (block.timestamp < publicSale.end)
            revert OnlyAfterPublicSaleEnd(block.timestamp, publicSale.end);

        uint256 balance = address(this).balance;
        AddressUpgradeable.sendValue(beneficiary, balance);
        emit RemainingETHWithdrawn(beneficiary, balance);
    }

    /**
     * @notice Pauses all token transfers.
     *
     * Emits a `Paused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should not be paused.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses all token transfers.
     *
     * Emits an `Unpaused` event.
     *
     * Requirements:
     * - The caller should have the role `PAUSER_ROLE`.
     * - The contract should be paused.
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // prettier-ignore
    function setPriceFeed(
        address _token,
        address _priceFeed,
        int256 _lowerPriceLimit
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_priceFeed == address(0))
            revert PriceFeedEqZeroAddr(_priceFeed);
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        if (10 ** priceFeed.decimals() != USD_PRICE_DECIMALS)
            revert OnlyUSDPriceFeed(_priceFeed);

        if (_token != address(0)) {
            uint256 decimals = 10 ** uint256(IERC20MetadataUpgradeable(_token).decimals());
            if (decimals > RDGX_TOKEN_DECIMALS || decimals == 1)
                revert TooManyOrZeroDecimals(_token, decimals);

            tokenDecimals[_token] = decimals;
        }

        validateNSetLowerPriceLimit(_token, priceFeed, _lowerPriceLimit);

        priceFeeds[_token] = _priceFeed;
        emit PriceFeedSet(_token, _priceFeed, _lowerPriceLimit);
    }

    // prettier-ignore
    function setDiscounts(
        Discounts.Discount[] calldata _discounts,
        bool _privatePhase
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_privatePhase)
            privateDiscounts.setDiscounts(_discounts);
        else
            publicDiscounts.setDiscounts(_discounts);
        emit DiscountsSet(_privatePhase);
    }

    function setLowerPriceLimit(address _token, int256 _lowerPriceLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateNSetLowerPriceLimit(_token, AggregatorV3Interface(priceFeeds[_token]), _lowerPriceLimit);
    }

    function setPublicMaxRDGXPerAccount(uint256 _publicMaxRDGXPerAccount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateNSetPublicMaxRDGXPerAccount(_publicMaxRDGXPerAccount);
    }

    function setRDGXTokenVesting(address _rdgxTokenVesting) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_rdgxTokenVesting == address(0)) revert RDGXTokenVestingEqZeroAddr();
        rdgxTokenVesting = IRDGXTokenVesting(_rdgxTokenVesting);
        emit RDGXTokenVestingSet(_rdgxTokenVesting);
    }

    function setBeneficiary(address payable _beneficiary) external onlyRole(DEFAULT_ADMIN_ROLE) {
        validateNSetBeneficiary(_beneficiary);
    }

    // prettier-ignore
    function setPrivateSalePeriod(uint256 _start, uint256 _end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_start < block.timestamp || _start >= _end || _end >= publicSale.start)
            revert IncorrectSalePeriod(block.timestamp, _start, _end, publicSale.start);

        SalePhase storage refPrivateSale = privateSale;
        refPrivateSale.start = _start;
        refPrivateSale.end = _end;
        emit PrivateSalePeriodSet(_start, _end);
    }

    // prettier-ignore
    function setPublicSalePeriod(uint256 _start, uint256 _end) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_start < block.timestamp || _start >= _end || _start <= privateSale.end)
            revert IncorrectSalePeriod(block.timestamp, _start, _end, privateSale.end);

        SalePhase storage refPublicSale = publicSale;
        refPublicSale.start = _start;
        refPublicSale.end = _end;
        emit PublicSalePeriodSet(_start, _end);
    }

    // prettier-ignore
    function setSupply(
        uint256 _initialSupply,
        uint256 _totalSupply,
        bool _privatePhase
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_initialSupply == 0 || _totalSupply == 0 || _initialSupply < _totalSupply)
            revert IncorrectSupply();

        SalePhase storage refSalePhase = _privatePhase ? privateSale : publicSale;
        refSalePhase.initialSupply = _initialSupply;
        refSalePhase.totalSupply = _totalSupply;
        emit SupplySet(_initialSupply, _totalSupply, _privatePhase);
    }

    function setMinRDGXPurchase(uint256 _minRDGXPurchase) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minRDGXPurchase = _minRDGXPurchase;
        emit MinRDGXPurchaseSet(_minRDGXPurchase);
    }

    // ____ Getters ___

    function calcRDGXPrice(uint256 _rdgxAmount, address _token, bool _privatePhase) external view returns (uint256) {
        return calcDiscountedPrice(_rdgxAmount, calcPrice(_rdgxAmount, _token), _privatePhase);
    }

    function calcRDGXPriceWithoutDiscount(uint256 _rdgxAmount, address _token) external view returns (uint256) {
        return calcPrice(_rdgxAmount, _token);
    }

    // prettier-ignore
    function calcRDGXAmount(address _token, uint256 _amount) external view returns (uint256) {
        address priceFeed = priceFeeds[_token];
        if (priceFeed == address(0)) revert UnknownToken(_token);

        // Getting the price from the Chainlink oracle.
        ( , int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        if (price < lowerPriceLimits[_token])
            revert TooLowPrice(price, lowerPriceLimits[_token], priceFeed);

        if (_token != address(0)) // A stablecoin or a token.
            return MathUpgradeable.mulDiv(
                _amount * (RDGX_TOKEN_DECIMALS / tokenDecimals[_token]),
                uint256(price),
                USD_PRICE_DECIMALS
            );
        else // Ether.
            return MathUpgradeable.mulDiv(_amount, uint256(price), USD_PRICE_DECIMALS);
    }

    function getSalePeriod(bool _privatePhase) external view returns (uint256, uint256) {
        SalePhase storage refSalePhase = _privatePhase ? privateSale : publicSale;
        return (refSalePhase.start, refSalePhase.end);
    }

    function getDiscounts(bool _privatePhase) external view returns (Discounts.Discount[] memory) {
        return _privatePhase ? privateDiscounts.get() : publicDiscounts.get();
    }

    function getTotalSupply(bool _privatePhase) external view returns (uint256) {
        return _privatePhase ? privateSale.totalSupply : publicSale.totalSupply;
    }

    function calcRDGXPurchased(bool _privatePhase) external view returns (uint256) {
        SalePhase storage refSalePhase = _privatePhase ? privateSale : publicSale;
        return refSalePhase.initialSupply - refSalePhase.totalSupply;
    }

    function isAllowlisted(address _address) external view returns (bool) {
        return hasRole(ALLOWLISTED_ROLE, _address);
    }

    // _______________ Private functions _______________

    /*
     * Returns `true` if the private phase, `false` if the public, otherwise reverts.
     * Subtracts `_rdgxAmount` from the sale's total supply.
     */
    // prettier-ignore
    function determinePhaseNDecreaseTotalSupply(uint256 _rdgxAmount) private returns (bool) {
        SalePhase storage refPrivateSale = privateSale;
        // Check that the private phase.
        if (block.timestamp >= refPrivateSale.start && block.timestamp < refPrivateSale.end) {
            if (refPrivateSale.totalSupply < _rdgxAmount)
                revert InsufficientRDGXForSale(_rdgxAmount, refPrivateSale.totalSupply);
            refPrivateSale.totalSupply -= _rdgxAmount;

            return true;
        }

        SalePhase storage refPublicSale = publicSale;
        // Check that the public phase.
        if (block.timestamp >= refPublicSale.start && block.timestamp < refPublicSale.end) {
            if (refPublicSale.totalSupply < _rdgxAmount)
                revert InsufficientRDGXForSale(_rdgxAmount, refPublicSale.totalSupply);
            refPublicSale.totalSupply -= _rdgxAmount;

            return false;
        }

        // Otherwise:
        revert OnlyWhenPrivateOrPublicSale();
    }

    // prettier-ignore
    function validateNSetLowerPriceLimit(
        address _token,
        AggregatorV3Interface _priceFeed,
        int256 _lowerPriceLimit
    ) private {
        if (_lowerPriceLimit < 1)
            revert LowerPriceLimitLTOne(_lowerPriceLimit);
        ( , int256 price, , , ) = _priceFeed.latestRoundData();
        if (price < _lowerPriceLimit)
            revert TooHighLowerPriceLimit(_lowerPriceLimit, price);

        lowerPriceLimits[_token] = _lowerPriceLimit;
        emit LowerPriceLimitSet(_token, _lowerPriceLimit);
    }

    function validateNSetBeneficiary(address payable _beneficiary) private {
        if (_beneficiary == address(0)) revert BeneficiaryEqZeroAddr();
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }

    function validateNSetPublicMaxRDGXPerAccount(uint256 _publicMaxRDGXPerAccount) private {
        if (_publicMaxRDGXPerAccount == 0) revert PublicMaxRDGXPerAccountEqZero();
        publicMaxRDGXPerAccount = _publicMaxRDGXPerAccount;
        emit PublicMaxRDGXPerAccountSet(_publicMaxRDGXPerAccount);
    }

    // prettier-ignore
    function calcPrice(uint256 _rdgxAmount, address _token) private view returns (uint256) {
        address priceFeed = priceFeeds[_token];
        if (priceFeed == address(0)) revert UnknownToken(_token);

        // Getting the price from the Chainlink oracle.
        ( , int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        if (price < lowerPriceLimits[_token])
            revert TooLowPrice(price, lowerPriceLimits[_token], priceFeed);

        if (_token != address(0)) // A stablecoin or a token.
            return MathUpgradeable.mulDiv(
                _rdgxAmount,
                USD_PRICE_DECIMALS,
                uint256(price) * (RDGX_TOKEN_DECIMALS / tokenDecimals[_token]),
                MathUpgradeable.Rounding.Up
            );
        else // Ether.
            return MathUpgradeable.mulDiv(_rdgxAmount, USD_PRICE_DECIMALS, uint256(price), MathUpgradeable.Rounding.Up);
    }

    // prettier-ignore
    function calcDiscountedPrice(
        uint256 _rdgxAmount,
        uint256 _rdgxPrice,
        bool _privatePhase
    ) private view returns (uint256) {
        if (_privatePhase)
            return privateDiscounts.calculateDiscountedPrice(_rdgxAmount, _rdgxPrice);
        else
            return publicDiscounts.calculateDiscountedPrice(_rdgxAmount, _rdgxPrice);
    }
}
