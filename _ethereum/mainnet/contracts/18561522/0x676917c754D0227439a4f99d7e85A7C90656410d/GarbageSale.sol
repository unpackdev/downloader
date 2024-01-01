// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "./Ownable.sol";
import "./Pausable.sol";
import "./IChainLinkPriceFeed.sol";

contract GarbageSale is Pausable, Ownable {
    struct User {
        uint256 ethSpent;
        uint256 tokensPurchased;
    }

    IChainLinkPriceFeed public immutable priceFeed;// Address of ChainLink ETH/USD price feed

    uint256 public saleLimit;// Total amount of tokens to be sold
    uint256 public tokenPrice;// Price for single token in USD
    uint256 public totalTokensSold;// Total amount of purchased tokens

    mapping(address => User) public users;// Stores the number of tokens purchased by each user and their claim status

    event TokensPurchased(
        address indexed user,
        uint256 indexed tokensAmount,
        uint256 indexed currentEthPrice
    );

    error ZeroPriceFeedAddress();
    error WrongOracleData();
    error TooLowValue();
    error PerWalletLimitExceeded(uint256 remainingLimit);
    error SaleLimitExceeded(uint256 remainingLimit);
    error NotEnoughEthOnContract();
    error EthSendingFailed();

    /*
        @notice Sets up contract while deploying
        @param _saleToken: Token address
        @param _oracle: ChainLink ETH/USD oracle address
        @param _usdPrice: USD price for single token
        @param _saleLimit: Total amount of tokens to be sold during sale
    **/
    constructor(
        address _priceFeed,
        uint256 _usdPrice,
        uint256 _saleLimit,
        address owner
    ) Ownable(owner) {
        if (_priceFeed == address(0)) revert ZeroPriceFeedAddress();

        priceFeed = IChainLinkPriceFeed(_priceFeed);
        saleLimit = _saleLimit * 1e18;

        tokenPrice = _usdPrice;
    }

    /// @notice Pausing sale
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpausing sale
    function unpause() external onlyOwner {
        _unpause();
    }

    /*
        @notice Function for receiving ether
        @dev amount of tokens will be calculated from received value
    **/
    receive() external payable {
        if (msg.value < 0.1 ether) revert TooLowValue();
        uint256 remainingLimit =  5 ether - users[msg.sender].ethSpent;
        if (remainingLimit < msg.value) revert PerWalletLimitExceeded(remainingLimit);

        (uint256 ethPrice, uint256 tokensAmount) = convertETHToTokensAmount(msg.value);

        if (tokensAmount + totalTokensSold > saleLimit) revert SaleLimitExceeded(saleLimit - totalTokensSold);

        totalTokensSold += tokensAmount;
        users[msg.sender].tokensPurchased += tokensAmount;
        users[msg.sender].ethSpent += msg.value;

        (bool success, ) = payable(owner()).call{ value: msg.value }("");
        if (!success) revert EthSendingFailed();

        emit TokensPurchased(msg.sender, ethPrice, tokensAmount);
    }

    /*
        @notice Function for converting eth amount to equal tokens amount
        @param _ethAmount: Amount of eth to calculate
        @return ethPrice: Current eth price in usdt
        @return tokensAmount: Amount of tokens
    **/
    function convertETHToTokensAmount(uint256 _ethAmount) public view returns (uint256 ethPrice, uint256 tokensAmount) {
        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        ethPrice = uint256(price) / 1e2;

        if (answeredInRound < roundID
            || updatedAt < block.timestamp - 3 hours
            || price < 0) revert WrongOracleData();
        tokensAmount = _ethAmount * uint256(price) / tokenPrice / 1e2;
    }
}
