// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./IERC2981.sol";
import "./SafeERC20.sol";
import "./Pausable.sol";

import "./Protected.sol";
import "./IMintable.sol";
import "./IRoyalties.sol";
import "./IVault.sol";
import "./ICounter.sol";
import "./IWallet.sol";
import "./IEtherspotWalletFactory.sol";

error TransferFailed();

error IncorrectEditions();
error IdTooBig(uint256 id, uint256 totalSupply);

error NotEnoughNativeTokens();
error NotEnoughTokensApproved();
error UnsupportedToken();
error NotOwnerOrPlatform();

error TooEarly(uint256 startTime, uint256 currentTime);
error TooLate(uint256 endTime, uint256 currentTime);

error NotABidder();
error NotASeller();
error NotAPlatform();

error NotEnoughEditionsRemained();
error TokenIsNotUnique();

error InvalidToken(address token);

error NotAWalletOwner();

contract Marketplace is Protected, Pausable {
    using SafeERC20 for IERC20;

    uint96 public constant FEE_DENOMINATOR = 10000;
    address public walletFactory;

    address private _trustedForwarder;
    address public vault;
    address public royalties;
    address public counter;

    event InitialPurchase(
        address indexed seller,
        uint256 listingId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 totalSupply,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee
    );

    event SecondaryPurchase(
        address indexed seller,
        uint256 listingId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee,
        uint256 royalty
    );

    event InitialOfferPurchase(
        address indexed seller,
        uint256 offerId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 totalSupply,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee
    );

    event SecondaryOfferPurchase(
        address indexed seller,
        uint256 offerId,
        address indexed receiver,
        address indexed tokenAddress,
        uint256 tokenId,
        uint256 soldEditions,
        uint256 remainingEditions,
        address currency,
        uint256 price,
        uint256 fee,
        uint256 royalty
    );

    event AuctionCancelled(
        address seller,
        uint256 listingId,
        address tokenAddress,
        uint256 tokenId
    );

    modifier onlySeller(address seller) {
        if (_msgSender() != seller) revert NotASeller();
        _;
    }

    modifier onlyPlatform() {
        if (_msgSender() != platform) revert NotASeller();
        _;
    }

    modifier onlyOwnerOrPlatform() {
        if (_msgSender() != owner() && _msgSender() != platform)
            revert NotOwnerOrPlatform();
        _;
    }

    constructor(
        address _platform,
        address _vault,
        address _royalties,
        address _counter
    ) {
        platform = _platform;
        vault = _vault;
        royalties = _royalties;
        counter = _counter;
        walletFactory = 0x7f6d8F107fE8551160BD5351d5F1514A6aD5d40E;
    }

    function pause() external onlyOwnerOrPlatform {
        _pause();
    }

    function unpause() external onlyOwnerOrPlatform {
        _unpause();
    }

    /// @notice Check if the forwarder trusted
    /// @param forwarder Address of the forwarder
    /// @return True if the forwarder trusted
    function isTrustedForwarder(
        address forwarder
    ) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /// @notice Buy token (Direct Sale)
    /// @param saleData Params of mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function buy(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external payable whenNotPaused {
        _checkActive(
            saleData.startTime,
            saleData.endTime,
            platformData.expirationTime
        );
        _checkOwnedWallet(saleData.order.signer, saleData.seller);

        uint256 payment = saleData.order.price * platformData.editionsToBuy;
        _checkMoney(_msgSender(), saleData.order.currency, payment);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkSaleSignature(saleData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (
            _getRemainingEditionsInListing(saleData.listingId) == 0 &&
            !ICounter(counter).isListingFilled(saleData.listingId)
        ) {
            ICounter(counter).initListing(
                saleData.listingId,
                saleData.order.totalTrading
            );
        }

        if (
            platformData.editionsToBuy >
            _getRemainingEditionsInListing(saleData.listingId)
        ) revert NotEnoughEditionsRemained();

        uint256 fee = (payment * saleData.order.feeRate) / FEE_DENOMINATOR;
        address royaltyReceiver;
        uint256 royalty;

        if (saleData.order.isInitial) {
            if (
                !_isTokenMinted(
                    saleData.order.tokenAddress,
                    saleData.order.tokenId
                )
            ) {
                _mintDirect(saleData);
            }
        } else {
            // calculate royalties
            if (
                IERC165(saleData.order.tokenAddress).supportsInterface(
                    type(IERC2981).interfaceId
                )
            ) {
                (royaltyReceiver, royalty) = IERC2981(
                    saleData.order.tokenAddress
                ).royaltyInfo(saleData.order.tokenId, payment);
            } else {
                (royaltyReceiver, royalty) = IRoyalties(royalties).royaltyInfo(
                    saleData.order.tokenAddress,
                    payment
                );
            }
        }

        _transfer(
            saleData.order.tokenAddress,
            saleData.seller,
            platformData.receiver,
            saleData.order.tokenId,
            platformData.editionsToBuy
        );

        ICounter(counter).decreaseListing(
            saleData.listingId,
            platformData.editionsToBuy
        );

        _payDirect(
            saleData.seller,
            saleData.order.currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );

        if (saleData.order.isInitial) {
            emitInitialPurchase(
                saleData,
                platformData,
                _getRemainingEditionsInListing(saleData.listingId),
                saleData.order.price,
                fee
            );
        } else {
            emitSecondaryPurchase(
                saleData,
                platformData,
                _getRemainingEditionsInListing(saleData.listingId),
                saleData.order.price,
                fee,
                royalty
            );
        }
    }

    function emitInitialPurchase(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        uint256 remainingEditions,
        uint256 price,
        uint256 fee
    ) internal {
        emit InitialPurchase(
            saleData.seller,
            saleData.listingId,
            platformData.receiver,
            saleData.order.tokenAddress,
            saleData.order.tokenId,
            saleData.mint.totalSupply,
            platformData.editionsToBuy,
            remainingEditions,
            saleData.order.currency,
            price,
            fee
        );
    }

    function emitSecondaryPurchase(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        uint256 remainingEditions,
        uint256 price,
        uint256 fee,
        uint256 royalty
    ) internal {
        emit SecondaryPurchase(
            saleData.seller,
            saleData.listingId,
            platformData.receiver,
            saleData.order.tokenAddress,
            saleData.order.tokenId,
            platformData.editionsToBuy,
            remainingEditions,
            saleData.order.currency,
            price,
            fee,
            royalty
        );
    }

    /// @notice Mint new token (Offer)
    /// @param offerData Params of mint
    /// @param platformData Seller's address & buyer signature
    /// @param platformSignature Platform's signature
    function sell(
        OfferParams calldata offerData,
        PlatformOfferParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(platformData.seller) whenNotPaused {
        if (block.timestamp > offerData.endTime)
            revert TooLate(offerData.endTime, block.timestamp);
        if (
            platformData.expirationTime != 0 &&
            block.timestamp > platformData.expirationTime
        ) revert PlatformSignatureExpired();
        _checkOwnedWallet(offerData.order.signer, offerData.buyer);

        uint256 payment = offerData.order.price * platformData.editionsToSell;
        _checkMoney(offerData.buyer, offerData.order.currency, payment);

        if (!_checkPlatformOfferSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkOfferSignature(offerData, platformData.buyerSignature))
            revert WrongBuyerSignature();

        if (
            _getRemainingEditionsInOffer(offerData.offerId) == 0 &&
            !ICounter(counter).isOfferFilled(offerData.offerId)
        ) {
            ICounter(counter).initOffer(
                offerData.offerId,
                offerData.order.totalTrading
            );
        }

        if (
            platformData.editionsToSell >
            _getRemainingEditionsInOffer(offerData.offerId)
        ) revert NotEnoughEditionsRemained();

        uint256 fee = (payment * offerData.order.feeRate) / FEE_DENOMINATOR;
        address royaltyReceiver;
        uint256 royalty;

        if (offerData.order.isInitial) {
            if (
                !_isTokenMinted(
                    offerData.order.tokenAddress,
                    offerData.order.tokenId
                )
            ) {
                _mintOffer(offerData, platformData.seller);
            }
        } else {
            if (
                IERC165(offerData.order.tokenAddress).supportsInterface(
                    type(IERC2981).interfaceId
                )
            ) {
                (royaltyReceiver, royalty) = IERC2981(
                    offerData.order.tokenAddress
                ).royaltyInfo(offerData.order.tokenId, payment);
            } else {
                (royaltyReceiver, royalty) = IRoyalties(royalties).royaltyInfo(
                    offerData.order.tokenAddress,
                    payment
                );
            }
        }

        _transfer(
            offerData.order.tokenAddress,
            platformData.seller,
            offerData.buyer,
            offerData.order.tokenId,
            platformData.editionsToSell
        );

        ICounter(counter).decreaseOffer(
            offerData.offerId,
            platformData.editionsToSell
        );

        _payOffer(
            offerData.buyer,
            offerData.order.currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );

        if (offerData.order.isInitial) {
            emitInitialOfferPurchase(
                offerData,
                platformData,
                _getRemainingEditionsInOffer(offerData.offerId),
                fee
            );
        } else {
            emitSecondaryOfferPurchase(
                offerData,
                platformData,
                _getRemainingEditionsInOffer(offerData.offerId),
                fee,
                royalty
            );
        }
    }

    function emitInitialOfferPurchase(
        OfferParams calldata offerData,
        PlatformOfferParams calldata platformData,
        uint256 remainingEditions,
        uint256 fee
    ) internal {
        emit InitialOfferPurchase(
            platformData.seller,
            offerData.offerId,
            offerData.buyer,
            offerData.order.tokenAddress,
            offerData.order.tokenId,
            offerData.mint.totalSupply,
            platformData.editionsToSell,
            remainingEditions,
            offerData.order.currency,
            offerData.order.price,
            fee
        );
    }

    function emitSecondaryOfferPurchase(
        OfferParams calldata offerData,
        PlatformOfferParams calldata platformData,
        uint256 remainingEditions,
        uint256 fee,
        uint256 royalty
    ) internal {
        emit SecondaryOfferPurchase(
            platformData.seller,
            offerData.offerId,
            offerData.buyer,
            offerData.order.tokenAddress,
            offerData.order.tokenId,
            platformData.editionsToSell,
            remainingEditions,
            offerData.order.currency,
            offerData.order.price,
            fee,
            royalty
        );
    }

    /// @notice Bid in auction
    /// @param bidData Listing id, currency to bid, price to bid
    /// @param bidSignature Platform's signature
    function bid(
        PlatformBidParams calldata bidData,
        bytes calldata bidSignature
    ) external payable whenNotPaused {
        _checkPlatformBidSignature(bidData, bidSignature);
        if (
            bidData.expirationTime != 0 &&
            block.timestamp > bidData.expirationTime
        ) revert PlatformSignatureExpired();

        if (bidData.currency != address(0))
            IERC20(bidData.currency).safeTransferFrom(
                _msgSender(),
                vault,
                bidData.price
            );
        else {
            if (msg.value < bidData.price) revert NotEnoughNativeTokens();
            _transfer(vault, msg.value);
        }

        IVault(vault).updateBid(
            bidData.listingId,
            _msgSender(),
            bidData.currency,
            bidData.price
        );
    }

    /// @notice Cancel active auction (only seller, token to mint)
    /// @param saleData Params of the token to mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    function cancelAuction(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(saleData.seller) whenNotPaused {
        _checkActive(
            saleData.startTime,
            saleData.endTime,
            platformData.expirationTime
        );
        _cancelAuction(saleData, platformData, platformSignature);
    }

    /// @notice Make a deal (only seller)
    function acceptBid(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) external onlySeller(saleData.seller) whenNotPaused {
        _checkActive(
            saleData.startTime,
            saleData.endTime,
            platformData.expirationTime
        );
        _acceptBid(saleData, platformData, platformSignature);
    }

    /// @notice Finish the auction platform-side
    /// @param saleData Params of mint
    /// @param platformData Receiver's address & seller signature
    /// @param platformSignature Platform's signature
    /// @param toCancel If true don't make a deal, cancel auction instead
    function executeAuction(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature,
        bool toCancel
    ) external onlyOwnerOrPlatform whenNotPaused {
        if (
            platformData.expirationTime != 0 &&
            block.timestamp > platformData.expirationTime
        ) revert PlatformSignatureExpired();

        // Platform can cancel at any time
        if (toCancel)
            _cancelAuction(saleData, platformData, platformSignature);
            // If the auction is over
        else if (block.timestamp > saleData.endTime) {
            if (IVault(vault).isBidExist(saleData.listingId))
                // And bid exist, platform will accept the bid
                _acceptBid(saleData, platformData, platformSignature);
                // Or if bid doesn't exist, it will cancel
            else _cancelAuction(saleData, platformData, platformSignature);
        }
        // If auction isn't over and shouldn't be canceled, the function fails
        else revert TooEarly(saleData.endTime, block.timestamp);
    }

    /// @notice Check if permit active
    /// @param startTime Time when permit starts to be active
    /// @param endTime Time when permit ends to be active
    function _checkActive(
        uint256 startTime,
        uint256 endTime,
        uint256 expirationTime
    ) internal view {
        if (block.timestamp < startTime)
            revert TooEarly(startTime, block.timestamp);
        if (block.timestamp > endTime) revert TooLate(endTime, block.timestamp);

        if (expirationTime != 0 && block.timestamp > expirationTime)
            revert PlatformSignatureExpired();
    }

    function _cancelAuction(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        _checkOwnedWallet(saleData.order.signer, saleData.seller);

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkSaleSignature(saleData, platformData.sellerSignature))
            revert WrongSellerSignature();

        if (IVault(vault).isBidExist(saleData.listingId))
            IVault(vault).refundBid(
                saleData.listingId,
                saleData.order.currency
            );

        emit AuctionCancelled(
            saleData.seller,
            saleData.listingId,
            saleData.order.tokenAddress,
            saleData.order.tokenId
        );
    }

    function _acceptBid(
        SaleParams calldata saleData,
        PlatformParams calldata platformData,
        bytes calldata platformSignature
    ) internal {
        _checkOwnedWallet(saleData.order.signer, saleData.seller);

        if (saleData.order.totalTrading != 1) revert TokenIsNotUnique();
        if (block.timestamp < saleData.startTime)
            revert TooEarly(saleData.startTime, block.timestamp);
        if (
            platformData.receiver == address(0) ||
            !IVault(vault).isBidder(platformData.receiver, saleData.listingId)
        ) revert NotABidder();

        if (!_checkPlatformSignature(platformData, platformSignature))
            revert WrongPlatformSignature();
        if (!_checkSaleSignature(saleData, platformData.sellerSignature))
            revert WrongSellerSignature();

        uint256 bidPrice = IVault(vault).getBidPrice(saleData.listingId);
        uint256 bidFee = (bidPrice * saleData.order.feeRate) / FEE_DENOMINATOR;
        address royaltyReceiver;
        uint256 royalty;

        if (saleData.order.isInitial) {
            if (
                !_isTokenMinted(
                    saleData.order.tokenAddress,
                    saleData.order.tokenId
                )
            ) {
                _mintDirect(saleData);
            }
        } else {
            if (
                IERC165(saleData.order.tokenAddress).supportsInterface(
                    type(IERC2981).interfaceId
                )
            ) {
                (royaltyReceiver, royalty) = IERC2981(
                    saleData.order.tokenAddress
                ).royaltyInfo(saleData.order.tokenId, bidPrice);
            } else {
                (royaltyReceiver, royalty) = IRoyalties(royalties).royaltyInfo(
                    saleData.order.tokenAddress,
                    saleData.order.price
                );
            }
        }

        _transfer(
            saleData.order.tokenAddress,
            saleData.seller,
            platformData.receiver,
            saleData.order.tokenId,
            1
        );

        IVault(vault).acceptBid(
            saleData.listingId,
            saleData.seller,
            saleData.order.currency,
            bidFee,
            royaltyReceiver,
            royalty
        );

        if (saleData.order.isInitial) {
            emitInitialPurchase(saleData, platformData, 0, bidPrice, bidFee);
        } else {
            emitSecondaryPurchase(
                saleData,
                platformData,
                0,
                bidPrice,
                bidFee,
                royalty
            );
        }
    }

    /// @notice Check payment
    /// @param payer Address of buyer
    /// @param currency Address of token to pay (zero if native)
    /// @param payment Price per token to purchase
    function _checkMoney(
        address payer,
        address currency,
        uint256 payment
    ) internal view {
        if (currency == address(0)) {
            if (msg.value < payment) revert NotEnoughNativeTokens();
        } else if (IERC20(currency).allowance(payer, address(this)) < payment)
            revert NotEnoughTokensApproved();
    }

    function _checkOwnedWallet(address signer, address wallet) internal view {
        if (signer != wallet) {
            if (wallet.code.length == 0) {
                if (walletFactory.code.length == 0) revert NotAWalletOwner();
                try
                    IEtherspotWalletFactory(walletFactory).getAddress(signer, 0)
                returns (address futureAddress) {
                    if (wallet != futureAddress) revert NotAWalletOwner();
                } catch {
                    revert NotAWalletOwner();
                }
            } else {
                try IWallet(wallet).isOwner(signer) returns (bool result) {
                    if (!result) revert NotAWalletOwner();
                } catch {
                    revert NotAWalletOwner();
                }
            }
        }
    }

    function _isTokenMinted(
        address token,
        uint256 id
    ) internal view returns (bool) {
        try IMintable(token).exists(id) returns (bool result) {
            return result;
        } catch {
            // If token do not support exists function, we assume token minted
            return true;
        }
    }

    function mintFree(
        address token,
        address receiver,
        uint256 id,
        MintInfo calldata mint
    ) external onlyOwner {
        _mint(receiver, token, id, mint);
    }

    function _mintDirect(SaleParams calldata saleData) internal {
        _mint(
            saleData.seller,
            saleData.order.tokenAddress,
            saleData.order.tokenId,
            saleData.mint
        );
    }

    function _mintOffer(
        OfferParams calldata offerData,
        address seller
    ) internal {
        _mint(
            seller,
            offerData.order.tokenAddress,
            offerData.order.tokenId,
            offerData.mint
        );
    }

    /// @notice Mint new internal ERC1155
    /// @param receiver Address of future owner of tokens
    /// @param id ID of tokens to mint
    function _mint(
        address receiver,
        address token,
        uint256 id,
        MintInfo calldata mint
    ) internal {
        IMintable(token).mint(
            receiver,
            id,
            mint.totalSupply,
            mint.meta,
            mint.royaltyReceiver,
            mint.royalty
        );
    }

    function _transfer(
        address tokenAddress,
        address seller,
        address receiver,
        uint256 tokenId,
        uint256 editions
    ) internal {
        if (
            IERC165(tokenAddress).supportsInterface(type(IERC1155).interfaceId)
        ) {
            IERC1155(tokenAddress).safeTransferFrom(
                seller,
                receiver,
                tokenId,
                editions,
                ""
            );
        } else if (
            IERC165(tokenAddress).supportsInterface(type(IERC721).interfaceId)
        ) {
            IERC721(tokenAddress).safeTransferFrom(seller, receiver, tokenId);
        } else {
            revert UnsupportedToken();
        }
    }

    function _payDirect(
        address receiver,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        _pay(
            _msgSender(),
            receiver,
            currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );
    }

    function _payOffer(
        address payer,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        _pay(
            payer,
            _msgSender(),
            currency,
            payment,
            fee,
            royaltyReceiver,
            royalty
        );
    }

    /// @notice Pay for tokens
    /// @param payer Payer
    /// @param receiver Receiver of payment
    /// @param currency Address of token to pay (zero if native)
    /// @param payment Price to pay
    function _pay(
        address payer,
        address receiver,
        address currency,
        uint256 payment,
        uint256 fee,
        address royaltyReceiver,
        uint256 royalty
    ) internal {
        if (currency == address(0)) {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver) {
                _transfer(receiver, payment - fee);
            } else {
                _transfer(receiver, payment - fee - royalty);
                _transfer(royaltyReceiver, royalty);
            }
        } else {
            if (royaltyReceiver == address(0) || royaltyReceiver == receiver)
                IERC20(currency).safeTransferFrom(
                    payer,
                    receiver,
                    payment - fee
                );
            else {
                IERC20(currency).safeTransferFrom(
                    payer,
                    receiver,
                    payment - fee - royalty
                );
                IERC20(currency).safeTransferFrom(
                    payer,
                    royaltyReceiver,
                    royalty
                );
            }
            IERC20(currency).safeTransferFrom(payer, vault, fee);
            IVault(vault).updateFeeAccumulator(currency, fee);
        }
    }

    function _msgSender() internal view override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _getRemainingEditionsInListing(
        uint256 listingId
    ) internal view returns (uint256) {
        return ICounter(counter).remainingInListing(listingId);
    }

    function _getRemainingEditionsInOffer(
        uint256 offerId
    ) internal view returns (uint256) {
        return ICounter(counter).remainingInOffer(offerId);
    }

    function _transfer(address receiver, uint256 value) internal {
        (bool status, ) = payable(receiver).call{value: value, gas: 10000}("");
        if (!status) revert TransferFailed();
    }

    function setTrustedForwarder(address forwarder) external onlyOwner {
        _trustedForwarder = forwarder;
    }

    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setWalletFactory(address _walletFactory) external onlyOwner {
        walletFactory = _walletFactory;
    }

    function withdrawNative(address receiver) external onlyOwner {
        _transfer(receiver, address(this).balance);
    }
}
