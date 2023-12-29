// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";

interface IEyecons {
    error InvalidRoyaltyPercentage(uint256 invalidPercentage);
    error InvalidAmountToIncreaseAvailableAmountToMint();
    error InvalidAmountToMint();
    error NotUniqueSignature(bytes notUniqueSignature);
    error InvalidSignature(bytes invalidSignature);
    error NonExistentToken(uint256 tokenId);
    error TooEarlyRenewal(uint256 tokenId, uint256 remainingSubscriptionTime);
    error ForbiddenToTransferTokens();
    error NonZeroMsgValue();
    error InsufficientPrice(uint256 difference);
    error InvalidPaymentCurrency();

    event PublicPeriodEnabled();
    event TradingEnabled();
    event DefaultRoyaltyUpdated(uint96 indexed newPercentage);
    event AuthorizerUpdated(address indexed oldAuthorizer, address indexed newAuthorizer);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event BaseURIUpdated(string indexed oldBaseURI, string indexed newBaseURI);
    event TokenPriceUpdated(uint256 indexed oldTokenPrice, uint256 indexed newTokenPrice);
    event SubscriptionPriceUpdated(uint256 indexed oldSubscriptionPrice, uint256 indexed newSubscriptionPrice);
    event AvailableAmountToMintIncreased(
        uint256 indexed oldAvailableAmountToMint, 
        uint256 indexed newAvailableAmountToMint,
        uint256 indexed difference
    );
    event AvailableAmountToMintDecreased(
        uint256 indexed oldAvailableAmountToMint, 
        uint256 indexed newAvailableAmountToMint,
        uint256 indexed difference
    );
    event SubscriptionsRenewed(address indexed renewedBy, uint256[] indexed tokenIds);

    /// @notice Enables the public period for minting.
    function enablePublicPeriod() external;

    /// @notice Enables tokens trading.
    function enableTrading() external;

    /// @notice Updated default royalty config for all tokens.
    /// @param percentage_ New royalty percentage.
    function updateDefaultRoyalty(uint96 percentage_) external;

    /// @notice Updates the authorizer.
    /// @param authorizer New authorizer address.
    function updateAuthorizer(address authorizer) external;

    /// @notice Updates the treasury.
    /// @param treasury New treasury address.
    function updateTreasury(address payable treasury) external;

    /// @notice Updates the base URI.
    /// @param baseURI New base URI.
    function updateBaseURI(string calldata baseURI) external;

    /// @notice Updates the token price or/and the subscription price.
    /// @param tokenPrice Minting price per token.
    /// @param subscriptionPrice Subscription price per token.
    function updatePrices(uint256 tokenPrice, uint256 subscriptionPrice) external;

    /// @notice Increases the available amount of tokens to mint.
    /// @param amount Amount to increase.
    function increaseAvailableAmountToMint(uint256 amount) external;

    /// @notice Decreases the available amount of tokens to mint.
    /// @param amount Amount to decrease.
    function decreaseAvailableAmountToMint(uint256 amount) external;

    /// @notice Mints `amount` tokens to msg.sender.
    /// @param paymentCurrency Payment currency address
    /// (should be zero if the payment is supposed to be made in native currency).
    /// @param amount Amount of tokens to mint.
    /// @param signature Signature hash.
    function mint(
        address paymentCurrency, 
        uint256 amount,
        bytes calldata signature
    ) 
        external 
        payable;
    
    /// @notice Renews subscription for token ids.
    /// @param paymentCurrency Payment currency address 
    /// (should be zero if the payment is supposed to be made in native currency).
    /// @param tokenIds Token ids for which the subscription is renewed.
    function renewSubscription(address paymentCurrency, uint256[] calldata tokenIds) external;

    /// @notice Retrieves the subscription status for token id.
    /// @param tokenId Token id.
    /// @return isSubscriptionActive Boolean value indicating whether the subscription is active.
    /// @return remainingSubscriptionTime Remaining subscription time value in seconds.
    function subscriptionStatus(
        uint256 tokenId
    )
        external 
        view 
        returns (
            bool isSubscriptionActive, 
            uint256 remainingSubscriptionTime
        );

    /// @notice Retrieves the current _signatureId value.
    /// @return Current _signatureId value.
    function currentSignatureId() external view returns (uint256);
}