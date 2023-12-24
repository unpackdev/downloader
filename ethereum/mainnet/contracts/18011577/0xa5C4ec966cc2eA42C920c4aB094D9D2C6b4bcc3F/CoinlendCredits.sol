//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./AggregatorV3Interface.sol";
import "./SafeERC20.sol";

contract CoinlendCredits is ERC20("Coinlend Credits", "COINC"), Ownable, ReentrancyGuard {
    /**
     * Throw this error when user wants to buy credits with an token for which there is no price feed
     */
    error CoinlendCredits_MissingPriceFeed(address currencyAddress);

    /**
     * Throw this error when user wants to buy credits with 0 value or no price feed is available
     */
    error CoinlendCredits_InvalidValue();

    /**
     * Throw this error when allowance of paytoken is inusfficient
     */
    error CoinlendCredits_InsufficientPayTokenAllowance();

    /**
     * Throw this error if balance not sufficient for withdrawal
     */
    error CoinlendCredits_InsufficientBalance();

    /**
     * Throw this error if validation of price feed data failed
     */
    error CoinlendCredits_PriceFeedValidationFailed();

    /**
     * Mapping of pricefeeds for all supported tokens to buy credits
     */
    mapping(address => AggregatorV3Interface) public priceFeeds;

    /**
     * Count of all transfers on the platform -> used as ID
     */
    uint256 public purchaseCount = 1;

    event CreditsPurchase(uint256 id, address token, address user, uint256 amount, uint256 credits);

    constructor() ReentrancyGuard() {
        _mint(address(this), 1000000 * 10 ** 18);
    }

    function mint(uint256 _amount) public onlyOwner {
        _mint(address(this), _amount);
    }

    function buyCredits(address _payTokenAddress, uint256 _amount) public nonReentrant {
        ERC20 payToken = ERC20(_payTokenAddress);
        // Calculate the amount of credits the user will receive based on the amount and price of the token he deposited
        uint256 creditsAmounts = (_amount * getLatestPrice(_payTokenAddress)) /
            (10 ** (payToken.decimals()));

        // If there is no pricefeed -> no price -> don't allow user to buy credits with that token
        if (creditsAmounts <= 0) {
            revert CoinlendCredits_InvalidValue();
        }

        // Allowance needs to be set on pay token
        uint256 allowance = payToken.allowance(msg.sender, address(this));

        if (allowance < _amount) {
            revert CoinlendCredits_InsufficientPayTokenAllowance();
        }

        // Transfer pay tokens to credits contract
        SafeERC20.safeTransferFrom(
            IERC20(_payTokenAddress), // token to transfer
            msg.sender, // Sender of the tokens
            address(this), // Recipient of the tokens
            _amount // Amount of tokens to transfer
        );

        // Mint the tokens for the buyer
        _mint(msg.sender, creditsAmounts);

        // Emit purchase event
        emit CreditsPurchase(purchaseCount, _payTokenAddress, msg.sender, _amount, creditsAmounts);

        purchaseCount++;
    }

    /**
     * Add price feed. Only tokens with price feeds can be used to buy credits
     */
    function addPriceFeed(address _currencyAddress, address _priceFeedAddress) public onlyOwner {
        priceFeeds[_currencyAddress] = AggregatorV3Interface(_priceFeedAddress);
    }

    /**
     * Returns the latest price.
     */
    function getLatestPrice(address _currencyAddress) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[_currencyAddress];

        // Check if there is a price feed available for the given currency
        if (address(priceFeed) == address(0)) {
            revert CoinlendCredits_MissingPriceFeed(_currencyAddress);
        }
        (uint80 roundID, int price, , uint256 timeStamp, uint80 answeredInRound) = priceFeed
            .latestRoundData();

        uint256 decimalsFeed = priceFeeds[_currencyAddress].decimals();

        // Validate price feed data
        if (price <= 0 || answeredInRound < roundID || timeStamp == 0) {
            revert CoinlendCredits_PriceFeedValidationFailed();
        }

        return uint256(price) * 10 ** (18 - decimalsFeed);
    }

    /**
     * Withdraws ERC20 tokens from the contract.
     */
    function withdraw(address _token, uint256 _amount) public onlyOwner {
        ERC20 erc20Token = ERC20(_token);

        if (erc20Token.balanceOf(address(this)) < _amount) {
            revert CoinlendCredits_InsufficientBalance();
        }

        erc20Token.transfer(owner(), _amount);
    }
}
