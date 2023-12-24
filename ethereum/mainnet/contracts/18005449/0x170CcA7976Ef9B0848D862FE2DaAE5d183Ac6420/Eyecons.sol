// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./Address.sol";
import "./Counters.sol";

import "./IEyecons.sol";

contract Eyecons is IEyecons, ERC721Enumerable, ERC2981, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using ECDSA for bytes32;
    using SafeCast for int256;
    using Address for address payable;
    using Counters for Counters.Counter;

    uint256 public constant ONE_YEAR = 365 days;
    uint256 private constant DECIMALS = 18;
    uint96 public constant MAXIMUM_ROYALTY_PERCENTAGE = 1000;
    uint96 public constant MINIMUM_ROYALTY_PERCENTAGE = 100;

    uint256 public immutable maximumSupply;
    uint256 public tokenPrice;
    uint256 public subscriptionPrice;
    uint256 public availableAmountToMint;
    uint256 private _nextTokenId;
    address public authorizer;
    address payable public treasury;
    string public baseURI;
    bool public publicPeriodEnabled;
    bool public tradingEnabled;
    IERC20Metadata public immutable tether;
    AggregatorV3Interface public immutable priceOracle;
    Counters.Counter private _signatureId;

    mapping(uint256 => uint256) public subscriptionExpirationTimeByTokenId;
    mapping(bytes => bool) public notUniqueSignature;

    /// @param maximumSupply_ Maximum supply.
    /// @param tokenPrice_ Minting price per token.
    /// @param subscriptionPrice_ Subscription price per token.
    /// @param authorizer_ Authorizer address.
    /// @param treasury_ Treasury address.
    /// @param baseURI_ Base URI.
    /// @param tether_ Tether USD contract address.
    /// @param priceOracle_ ETH/USD price oracle contract address.
    constructor(
        uint256 maximumSupply_,
        uint256 tokenPrice_,
        uint256 subscriptionPrice_,
        address authorizer_,
        address payable treasury_,
        string memory baseURI_,
        IERC20Metadata tether_,
        AggregatorV3Interface priceOracle_
    )
        ERC721("EYECONS Lifetime Membership Collection", "EYEC")
    {
        maximumSupply = maximumSupply_;
        tokenPrice = tokenPrice_;
        subscriptionPrice = subscriptionPrice_;
        _nextTokenId = 1;
        authorizer = authorizer_;
        treasury = treasury_;
        baseURI = baseURI_;
        tether = tether_;
        priceOracle = priceOracle_;
        _setDefaultRoyalty(treasury_, MAXIMUM_ROYALTY_PERCENTAGE);
    }

    /// @inheritdoc IEyecons
    function enablePublicPeriod() external onlyOwner {
        emit PublicPeriodEnabled();
        publicPeriodEnabled = true;
    }

    /// @inheritdoc IEyecons
    function enableTrading() external onlyOwner {
        emit TradingEnabled();
        tradingEnabled = true;
    }

    /// @inheritdoc IEyecons
    function updateDefaultRoyalty(uint96 percentage_) external onlyOwner {
        if (percentage_ < MINIMUM_ROYALTY_PERCENTAGE || percentage_ > MAXIMUM_ROYALTY_PERCENTAGE) {
            revert InvalidRoyaltyPercentage(percentage_);
        }
        _deleteDefaultRoyalty();
        _setDefaultRoyalty(treasury, percentage_);
        emit DefaultRoyaltyUpdated(percentage_);
    }

    /// @inheritdoc IEyecons
    function updateAuthorizer(address authorizer_) external onlyOwner {
        emit AuthorizerUpdated(authorizer, authorizer_);
        authorizer = authorizer_;
    }

    /// @inheritdoc IEyecons
    function updateTreasury(address payable treasury_) external onlyOwner {
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /// @inheritdoc IEyecons
    function updateBaseURI(string calldata baseURI_) external onlyOwner {
        emit BaseURIUpdated(baseURI, baseURI_);
        baseURI = baseURI_;
    }

    /// @inheritdoc IEyecons
    function updatePrices(uint256 tokenPrice_, uint256 subscriptionPrice_) external onlyOwner {
        emit TokenPriceUpdated(tokenPrice, tokenPrice_);
        tokenPrice = tokenPrice_;
        emit SubscriptionPriceUpdated(subscriptionPrice, subscriptionPrice_);
        subscriptionPrice = subscriptionPrice_;
    }

    /// @inheritdoc IEyecons
    function increaseAvailableAmountToMint(uint256 amount_) external onlyOwner {
        uint256 m_availableAmountToMint = availableAmountToMint;
        if (
            totalSupply() + amount_ > maximumSupply || 
            m_availableAmountToMint + amount_ > maximumSupply
        ) {
            revert InvalidAmountToIncreaseAvailableAmountToMint();
        }
        unchecked {
            availableAmountToMint += amount_;
            emit AvailableAmountToMintIncreased(
                m_availableAmountToMint, 
                m_availableAmountToMint + amount_, 
                amount_
            );
        }
    }

    /// @inheritdoc IEyecons
    function decreaseAvailableAmountToMint(uint256 amount_) external onlyOwner {
        uint256 m_availableAmountToMint = availableAmountToMint;
        availableAmountToMint -= amount_;
        unchecked {
            emit AvailableAmountToMintDecreased(
                m_availableAmountToMint,
                m_availableAmountToMint - amount_, 
                amount_
            );
        }
    }

    /// @inheritdoc IEyecons
    function mint(
        address paymentCurrency_, 
        uint256 amount_,
        bytes calldata signature_
    ) 
        external 
        payable 
        nonReentrant 
    {
        if (amount_ > availableAmountToMint || amount_ == 0) {
            revert InvalidAmountToMint();
        }
        if (!publicPeriodEnabled) {
            if (notUniqueSignature[signature_]) {
                revert NotUniqueSignature(signature_);
            }
            bytes32 hash = keccak256(abi.encode(msg.sender, amount_, _signatureId.current()));
            if (hash.toEthSignedMessageHash().recover(signature_) != authorizer) {
                revert InvalidSignature(signature_);
            }
            _signatureId.increment();
            notUniqueSignature[signature_] = true;
        }
        _processPayment(paymentCurrency_, amount_, false);
        uint256 m_nextTokenId = _nextTokenId;
        for (uint256 i = 0; i < amount_; ) {
            _safeMint(msg.sender, m_nextTokenId);
            unchecked {
                subscriptionExpirationTimeByTokenId[m_nextTokenId] = block.timestamp + ONE_YEAR;
                m_nextTokenId++;
                i++;
            }
        }
        _nextTokenId = m_nextTokenId;
        unchecked {
            availableAmountToMint -= amount_;
        }
    }

    /// @inheritdoc IEyecons
    function renewSubscription(
        address paymentCurrency_, 
        uint256[] calldata tokenIds_
    ) 
        external 
        nonReentrant
    {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (!_exists(tokenIds_[i])) {
                revert NonExistentToken(tokenIds_[i]);
            }
            uint256 subscriptionExpirationTime = subscriptionExpirationTimeByTokenId[tokenIds_[i]];
            unchecked {
                if (block.timestamp < subscriptionExpirationTime) {
                    revert TooEarlyRenewal(tokenIds_[i], subscriptionExpirationTime - block.timestamp);
                }
                subscriptionExpirationTimeByTokenId[tokenIds_[i]] = block.timestamp + ONE_YEAR;
            }
        }
        _processPayment(paymentCurrency_, tokenIds_.length, true);
        emit SubscriptionsRenewed(msg.sender, tokenIds_);
    }

    /// @inheritdoc IEyecons
    function subscriptionStatus(
        uint256 tokenId_
    )
        external 
        view 
        returns (
            bool isSubscriptionActive_, 
            uint256 remainingSubscriptionTime_
        ) 
    {
        if (!_exists(tokenId_)) {
            revert NonExistentToken(tokenId_);
        }
        uint256 subscriptionExpirationTime = subscriptionExpirationTimeByTokenId[tokenId_];
        if (block.timestamp < subscriptionExpirationTime) {
            unchecked {
                return (true, subscriptionExpirationTime - block.timestamp);
            }
        } else {
            return (false, 0);
        }
    }

    /// @inheritdoc IEyecons
    function currentSignatureId() external view returns (uint256) {
        return _signatureId.current();
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId_
    )
        public
        view
        override(ERC721Enumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId_);
    }

    /// @inheritdoc ERC721
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) 
        internal 
        override 
    {
        if (!tradingEnabled && from_ != address(0)) {
            revert ForbiddenToTransferTokens();
        }
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
    }

    /// @inheritdoc ERC721
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice Processes the payment for minting and/or subscription renewal.
    /// @param paymentCurrency_ Payment currency address 
    /// (should be zero if the payment is supposed to be made in native currency).
    /// @param amount_ Amount of tokens.
    /// @param isSubscriptionRenewal_ Boolean value indicating whether the operation corresponds to minting or subscription renewal.
    function _processPayment(address paymentCurrency_, uint256 amount_, bool isSubscriptionRenewal_) private {
        unchecked {
            uint256 price;
            if (isSubscriptionRenewal_) {
                price = subscriptionPrice * amount_;
            } else {
                price = (tokenPrice + subscriptionPrice) * amount_;
            }
            IERC20Metadata m_tether = tether;
            if (paymentCurrency_ == address(m_tether)) {
                if (msg.value > 0) {
                    revert NonZeroMsgValue();
                }
                m_tether.safeTransferFrom(msg.sender, treasury, price / 10 ** (DECIMALS - m_tether.decimals()));
            } else if (paymentCurrency_ == address(0)) {
                AggregatorV3Interface m_priceOracle = priceOracle;
                (, int256 answer, , ,) = m_priceOracle.latestRoundData();
                uint256 castedAnswer = answer.toUint256();
                uint256 adjustmentFactor = 10 ** (DECIMALS - m_priceOracle.decimals());
                uint256 actualPrice = msg.value * castedAnswer * adjustmentFactor / 1 ether;
                if (actualPrice < price) {
                    revert InsufficientPrice(price - actualPrice);
                } else {
                    uint256 nativeCurrencyPrice = price * 1 ether / (castedAnswer * adjustmentFactor);
                    treasury.sendValue(nativeCurrencyPrice);
                    if (msg.value > nativeCurrencyPrice) {
                        payable(msg.sender).sendValue(msg.value - nativeCurrencyPrice);
                    }
                }
            } else {
                revert InvalidPaymentCurrency();
            }
        }
    }
}