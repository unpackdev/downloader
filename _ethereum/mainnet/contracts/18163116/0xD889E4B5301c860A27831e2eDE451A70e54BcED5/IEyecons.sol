// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./IERC20Metadata.sol";
import "./AggregatorV3Interface.sol";

interface IEyecons {
    error InvalidRoyaltyPercentage(uint256 invalidPercentage);
    error InvalidAmountToIncrease();
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

    /// @notice Updates default royalty config for all tokens.
    /// @param percentage_ New royalty percentage.
    function updateDefaultRoyalty(uint96 percentage_) external;

    /// @notice Updates the authorizer.
    /// @param authorizer_ New authorizer address.
    function updateAuthorizer(address authorizer_) external;

    /// @notice Updates the treasury.
    /// @param treasury_ New treasury address.
    function updateTreasury(address payable treasury_) external;

    /// @notice Updates the base URI.
    /// @param baseURI_ New base URI.
    function updateBaseURI(string calldata baseURI_) external;

    /// @notice Updates the token price or/and the subscription price.
    /// @param tokenPrice_ New minting price per token.
    /// @param subscriptionPrice_ New subscription price per token.
    function updatePrices(uint256 tokenPrice_, uint256 subscriptionPrice_) external;

    /// @notice Increases the available amount of tokens to mint.
    /// @param amount_ Amount to increase.
    function increaseAvailableAmountToMint(uint256 amount_) external;

    /// @notice Decreases the available amount of tokens to mint.
    /// @param amount_ Amount to decrease.
    function decreaseAvailableAmountToMint(uint256 amount_) external;

    /// @notice Mints `amount_` tokens to the caller.
    /// @param paymentCurrency_ Payment currency address
    /// (should be zero if the payment is supposed to be made in a native currency).
    /// @param amount_ Amount of tokens to mint.
    /// @param signature_ Signature hash.
    function mint(
        address paymentCurrency_, 
        uint256 amount_,
        bytes calldata signature_
    ) 
        external 
        payable;
    
    /// @notice Renews subscription for token ids.
    /// @param paymentCurrency_ Payment currency address 
    /// (should be zero if the payment is supposed to be made in a native currency).
    /// @param tokenIds_ Token ids for which the subscription is renewed.
    function renewSubscription(address paymentCurrency_, uint256[] calldata tokenIds_) external;

    /// @notice Retrieves the subscription status for token id.
    /// @param tokenId_ Token id.
    /// @return isSubscriptionActive_ Boolean value indicating whether the subscription is active.
    /// @return remainingSubscriptionTime_ Remaining subscription time value in seconds.
    function subscriptionStatus(
        uint256 tokenId_
    )
        external 
        view 
        returns (
            bool isSubscriptionActive_, 
            uint256 remainingSubscriptionTime_
        );

    /// @notice Retrieves the current _signatureId value.
    /// @return Current _signatureId value.
    function currentSignatureId() external view returns (uint256);
}