// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import "./IHYFI_Whitelist.sol";
import "./IHYFI_Referrals.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./AggregatorV3Interface.sol";
import "./AccessControlUpgradeable.sol";

contract HYFI_PriceCalculator is Initializable, AccessControlUpgradeable {
    AggregatorV3Interface internal priceFeed;
    IHYFI_Whitelist whitelist;
    IHYFI_Referrals referrals;

    bytes32 public constant HYFI_SETTER_ROLE = keccak256("HYFI_SETTER_ROLE");
    bytes32 public constant CALCULATOR_SETTER = keccak256("CALCULATOR_SETTER");

    mapping(string => TokenData) tokenInfo;
    uint256 public unitPrice;
    uint256 public distrPercWithHYFI;
    uint256 public HYFIexchangeRate;

    struct TokenData {
        IERC20Upgradeable tokenAddress;
        uint256 totalAmountBought;
        uint256 decimals;
    }

    modifier limitedExchangeRate(uint256 rate) {
        require(
            rate > 0 && rate <= 10**18,
            "Exhange rate must be greater than 0 and less or equal to 10^18"
        );
        _;
    }

    function initialize(
        address _whitelistCotractAddress,
        address _referralsContractAddress,
        IERC20Upgradeable USDTtokenAddress,
        IERC20Upgradeable USDCtokenAddress,
        IERC20Upgradeable HYFItokenAddress,
        address _aggregatorAddress,
        uint256 _unitPrice,
        uint256 _HYFIexchangeRate
    ) public payable initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(HYFI_SETTER_ROLE, msg.sender);
        _setupRole(CALCULATOR_SETTER, msg.sender);
        whitelist = IHYFI_Whitelist(_whitelistCotractAddress);
        referrals = IHYFI_Referrals(_referralsContractAddress);
        priceFeed = AggregatorV3Interface(_aggregatorAddress);

        tokenInfo["USDT"].tokenAddress = USDTtokenAddress;
        tokenInfo["USDT"].decimals = tokenInfo["USDC"].decimals = 10**6;
        tokenInfo["USDC"].tokenAddress = USDCtokenAddress;
        tokenInfo["HYFI"].tokenAddress = HYFItokenAddress;
        tokenInfo["HYFI"].decimals = tokenInfo["ETH"].decimals = 10**18;

        unitPrice = _unitPrice;
        distrPercWithHYFI = 50;
        HYFIexchangeRate = _HYFIexchangeRate;
    }

    function discountAmountCalculator(uint256 discount, uint256 value)
        public
        pure
        returns (uint256 discountAmount)
    {
        discountAmount = (value * discount) / 10000;
        return discountAmount;
    }

    function discountPercentageCalculator(uint256 unitAmount, address buyer)
        public
        view
        virtual
        returns (uint256 discountPrecentage)
    {
        if (unitAmount <= 4) {
            discountPrecentage = 1000;
        } else if (unitAmount <= 50) {
            discountPrecentage = 1500;
        } else {
            discountPrecentage = 2000;
        }
        if (whitelist.isWhitelisted(buyer)) {
            discountPrecentage += 500;
        }
        return discountPrecentage;
    }

    function currencyPaymentCalculator(
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) public view virtual returns (uint256 paymentAmount) {
        uint256 priceTotal = ((unitAmount * unitPrice * 10**8) *
            tokenInfo["ETH"].decimals) / uint256(getLatestETHPrice());
        priceTotal -= discountAmountCalculator(discount, priceTotal);
        if (referrals.getReferralDiscountAmount(referralCode) != 0) {
            priceTotal -=
                ((unitAmount *
                    referrals.getReferralDiscountAmount(referralCode) *
                    10**8) * tokenInfo["ETH"].decimals) /
                uint256(getLatestETHPrice());
        }
        return priceTotal;
    }

    function simpleTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    ) public view virtual returns (uint256 paymentAmount) {
        uint256 priceTotal = (unitPrice * tokenInfo[token].decimals) *
            unitAmount;
        priceTotal -= discountAmountCalculator(discount, priceTotal);
        if (referrals.getReferralDiscountAmount(referralCode) != 0) {
            priceTotal -=
                referrals.getReferralDiscountAmount(referralCode) *
                tokenInfo[token].decimals;
        }
        return priceTotal;
    }

    function mixedTokenPaymentCalculator(
        string memory token,
        uint256 unitAmount,
        uint256 discount,
        uint256 referralCode
    )
        public
        view
        virtual
        returns (uint256 stableCoinPaymentAmount, uint256 HYFIPaymentAmount)
    {
        uint256 baseTokenPayment = ((unitPrice * tokenInfo[token].decimals) *
            unitAmount *
            distrPercWithHYFI) / 100;
        baseTokenPayment -= discountAmountCalculator(
            discount,
            baseTokenPayment
        );
        uint256 HYFItokenPayment = (((((unitPrice *
            tokenInfo["HYFI"].decimals) *
            unitAmount *
            distrPercWithHYFI) / 100) * 10**18) / HYFIexchangeRate);
        HYFItokenPayment -= discountAmountCalculator(
            discount,
            HYFItokenPayment
        );
        if (referrals.getReferralDiscountAmount(referralCode) != 0) {
            baseTokenPayment -=
                referrals.getReferralDiscountAmount(referralCode) *
                tokenInfo[token].decimals;
        }
        return (baseTokenPayment, HYFItokenPayment);
    }

    function setNewWhitelistImplementation(address newWhitelist)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        whitelist = IHYFI_Whitelist(newWhitelist);
    }

    function setNewReferralsImplementation(address newReferrals)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        referrals = IHYFI_Referrals(newReferrals);
    }

    function setAmountBoughtWithReferral(string memory token, uint256 amount)
        external
        onlyRole(CALCULATOR_SETTER)
    {
        tokenInfo[token].totalAmountBought += amount;
    }

    function setHYFIexchangeRate(uint256 newExchangeRate)
        external
        onlyRole(HYFI_SETTER_ROLE)
        limitedExchangeRate(newExchangeRate)
    {
        HYFIexchangeRate = newExchangeRate;
    }

    function setUnitPrice(uint256 newPrice)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        unitPrice = newPrice;
    }

    function getTokenData(string memory token)
        external
        view
        returns (TokenData memory)
    {
        return (tokenInfo[token]);
    }

    function getLatestETHPrice() public view virtual returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
