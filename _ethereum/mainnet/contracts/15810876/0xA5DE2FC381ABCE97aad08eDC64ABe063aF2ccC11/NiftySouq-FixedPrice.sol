// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";

import "./NiftySouq-IMarketplace.sol";
import "./NiftySouq-IMarketplaceManager.sol";
import "./NiftySouq-IERC721.sol";
import "./NiftySouq-IERC1155.sol";

struct PurchaseOffer {
    address offeredBy;
    uint256 quantity;
    uint256 price;
    uint256 offeredAt;
    bool canceled;
}

struct Sale {
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    uint256 soldQuantity;
    address[] buyer;
    uint256[] purchaseQuantity;
    uint256[] soldAt;
    bool isBargainable;
    PurchaseOffer[] offers;
}

struct SellData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    string currency;
}

struct LazyMintData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    address buyer;
    uint256 purchaseQuantity;
    address[] investors;
    uint256[] revenues;
    string currency;
}

struct BuyNFT {
    uint256 offerId;
    address buyer;
    uint256 quantity;
    uint256 payment;
}

struct AcceptOfferData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    address buyer;
    uint256 soldAt;
    string currency;
}

struct Payout {
    address currency;
    address seller;
    address buyer;
    uint256 tokenId;
    address tokenAddress;
    uint256 quantity;
    address[] refundAddresses;
    uint256[] refundAmount;
    bool soldout;
}

struct CalculatePayout1155 {
    uint256 price;
    uint256 totalSupply;
    uint256 quantity;
    uint256 serviceFeePercent;
    address admin;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 firstSaleQuantity;
}

contract NiftySouqFixedPriceV4 is Initializable {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant PERCENT_UNIT = 1e4;

    address private _marketplace;
    NiftySouqIMarketplaceManager private _marketplaceManager;

    mapping(uint256 => Sale) private _sale;
    mapping(uint256 => string) private _saleCurrency;

    mapping(string => bool) public isSalesupportedTokens;

    event eFixedPriceSale(
        uint256 offerId,
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity,
        uint256 price
    );
    event eUpdateSalePrice(uint256 offerId, uint256 price);
    event eCancelSale(uint256 offerId);
    event ePurchase(
        uint256 offerId,
        address buyer,
        address currency,
        uint256 quantity,
        bool isSaleCompleted
    );

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    modifier isNiftyMarketplace() {
        require(
            msg.sender == _marketplace,
            "Nifty721: unauthorized. not niftysouq marketplace"
        );
        _;
    }

    function initialize(address marketplace_, address marketplaceManager_)
        public
        initializer
    {
        _marketplace = marketplace_;
        _marketplaceManager = NiftySouqIMarketplaceManager(marketplaceManager_);
    }

    function enableDisableSaleToken(string memory tokenName_, bool enable_)
        public
    {
        isSalesupportedTokens[tokenName_] = enable_;
    }

    function getSaleDetails(uint256 offerId_)
        external
        view
        returns (Sale memory sale_)
    {
        sale_ = _sale[offerId_];
    }

    //Sell
    function sellNft(
        uint256 tokenId_,
        address tokenAddress_,
        uint256 price_,
        uint256 quantity_,
        string memory currency_
    ) public returns (uint256 offerId_) {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _marketplaceManager.isOwnerOfNFT(
                msg.sender,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        offerId_ = NiftySouqIMarketplace(_marketplace).createSale(
            tokenId_,
            NiftySouqIMarketplace.ContractType(uint256(contractType)),
            NiftySouqIMarketplace.OfferType.SALE
        );

        SellData memory sellData = SellData(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            isERC1155 ? quantity_ : 1,
            price_,
            msg.sender,
            currency_
        );
        _sell(sellData);
        emit eFixedPriceSale(
            offerId_,
            tokenId_,
            tokenAddress_,
            isERC1155,
            msg.sender,
            isERC1155 ? quantity_ : 1,
            price_
        );
    }

    //Mint & Sell
    function mintSellNft(
        NiftySouqIMarketplace.MintData memory mintData_,
        uint256 price_,
        string memory currency_
    ) public returns (uint256 tokenId_, uint256 offerId_) {
        (uint256 tokenId, , address tokenAddress) = NiftySouqIMarketplace(
            _marketplace
        ).mintNft(mintData_);
        tokenId_ = tokenId;

        offerId_ = sellNft(
            tokenId,
            tokenAddress,
            price_,
            mintData_.quantity,
            currency_
        );
    }

    //Update Price
    function updateSalePrice(
        uint256 offerId_,
        uint256 updatedPrice_,
        string memory currency_
    ) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        _updateSalePrice(offerId_, currency_, updatedPrice_, msg.sender);
        emit eUpdateSalePrice(offerId_, updatedPrice_);
    }

    //Cancel Sale
    function cancelSale(uint256 offerId_) public {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        NiftySouqIMarketplace(_marketplace).endSale(
            offerId_,
            NiftySouqIMarketplace.OfferState.CANCELLED
        );

        emit eCancelSale(offerId_);
    }

    //Purchase
    function buyNft(uint256 offerId_, uint256 quantity_) public payable {
        NiftySouqIMarketplace.Offer memory offer = NiftySouqIMarketplace(
            _marketplace
        ).getOfferStatus(offerId_);
        require(
            offer.offerType == NiftySouqIMarketplace.OfferType.SALE,
            "offer id is not sale"
        );
        require(
            offer.status == NiftySouqIMarketplace.OfferState.OPEN,
            "offer is not active"
        );
        Payout memory payoutData = _buyNft(
            BuyNFT(offerId_, msg.sender, quantity_, msg.value)
        );

        _payout(
            NiftySouqIMarketplace.Payout(
                payoutData.currency,
                payoutData.refundAddresses,
                payoutData.refundAmount
            )
        );

        NiftySouqIMarketplace(_marketplace).transferNFT(
            payoutData.seller,
            payoutData.buyer,
            payoutData.tokenId,
            payoutData.tokenAddress,
            payoutData.quantity
        );

        if (payoutData.soldout) {
            NiftySouqIMarketplace(_marketplace).endSale(
                offerId_,
                NiftySouqIMarketplace.OfferState.ENDED
            );
            emit ePurchase(offerId_, msg.sender, address(0), quantity_, true);
        } else {
            emit ePurchase(offerId_, msg.sender, address(0), quantity_, false);
        }
    }

    //accept offer
    function acceptOffer(AcceptOfferData calldata acceptOfferData_)
        external
        isNiftyMarketplace
        returns (Payout memory payout_)
    {
        _sale[acceptOfferData_.offerId].tokenId = acceptOfferData_.tokenId;
        _sale[acceptOfferData_.offerId].tokenContract = acceptOfferData_
            .tokenContract;
        _sale[acceptOfferData_.offerId].isERC1155 = acceptOfferData_.isERC1155;
        _sale[acceptOfferData_.offerId].quantity = acceptOfferData_.quantity;
        _sale[acceptOfferData_.offerId].price = acceptOfferData_.price;
        _sale[acceptOfferData_.offerId].seller = acceptOfferData_.seller;
        _sale[acceptOfferData_.offerId].createdAt = block.timestamp;
        _sale[acceptOfferData_.offerId].soldQuantity = acceptOfferData_
            .quantity;
        _sale[acceptOfferData_.offerId].buyer.push(acceptOfferData_.buyer);
        _sale[acceptOfferData_.offerId].purchaseQuantity.push(
            acceptOfferData_.quantity
        );
        _sale[acceptOfferData_.offerId].soldAt.push(block.timestamp);
        _saleCurrency[acceptOfferData_.offerId] = acceptOfferData_.currency;

        (
            address[] memory recipientAddresses,
            uint256[] memory paymentAmount,
            ,

        ) = _marketplaceManager.calculatePayout(
                CalculatePayout(
                    acceptOfferData_.tokenId,
                    acceptOfferData_.tokenContract,
                    acceptOfferData_.seller,
                    acceptOfferData_.price,
                    acceptOfferData_.quantity
                )
            );
        payout_ = Payout(
            address(0),
            acceptOfferData_.seller,
            acceptOfferData_.buyer,
            acceptOfferData_.tokenId,
            acceptOfferData_.tokenContract,
            acceptOfferData_.quantity,
            recipientAddresses,
            paymentAmount,
            true
        );
    }

    function _sell(SellData memory sell_) internal {
        _sale[sell_.offerId].tokenId = sell_.tokenId;
        _sale[sell_.offerId].tokenContract = sell_.tokenContract;
        _sale[sell_.offerId].isERC1155 = sell_.isERC1155;
        _sale[sell_.offerId].quantity = sell_.quantity;
        _sale[sell_.offerId].price = sell_.price;
        _sale[sell_.offerId].seller = sell_.seller;
        _sale[sell_.offerId].isBargainable = false;
        _sale[sell_.offerId].createdAt = block.timestamp;
        _saleCurrency[sell_.offerId] = sell_.currency;
    }

    function lazyMint(LazyMintData calldata lazyMintData_) external {
        _sale[lazyMintData_.offerId].tokenId = lazyMintData_.tokenId;
        _sale[lazyMintData_.offerId].tokenContract = lazyMintData_
            .tokenContract;
        _sale[lazyMintData_.offerId].isERC1155 = lazyMintData_.isERC1155;
        _sale[lazyMintData_.offerId].quantity = lazyMintData_.quantity;
        _sale[lazyMintData_.offerId].price = lazyMintData_.price;
        _sale[lazyMintData_.offerId].seller = lazyMintData_.seller;
        _sale[lazyMintData_.offerId].createdAt = block.timestamp;
        _sale[lazyMintData_.offerId].soldQuantity = lazyMintData_
            .purchaseQuantity;
        _sale[lazyMintData_.offerId].buyer.push(lazyMintData_.buyer);
        _sale[lazyMintData_.offerId].purchaseQuantity.push(
            lazyMintData_.purchaseQuantity
        );
        _sale[lazyMintData_.offerId].soldAt.push(block.timestamp);
        _saleCurrency[lazyMintData_.offerId] = lazyMintData_.currency;

        emit eFixedPriceSale(
            lazyMintData_.offerId,
            lazyMintData_.tokenId,
            lazyMintData_.tokenContract,
            lazyMintData_.isERC1155,
            lazyMintData_.seller,
            lazyMintData_.quantity,
            lazyMintData_.price
        );

        emit ePurchase(
            lazyMintData_.offerId,
            lazyMintData_.buyer,
            address(0),
            lazyMintData_.quantity,
            lazyMintData_.purchaseQuantity == lazyMintData_.quantity
                ? true
                : false
        );
    }

    //Update Price
    function _updateSalePrice(
        uint256 offerId_,
        string memory currency_,
        uint256 updatedPrice_,
        address seller_
    ) internal {
        require(seller_ == _sale[offerId_].seller, "user not seller");
        _sale[offerId_].price = updatedPrice_;
        _saleCurrency[offerId_] = currency_;
    }

    //Purchase
    function _buyNft(BuyNFT memory buyNft_)
        internal
        returns (Payout memory payout_)
    {
        Sale memory sale = _sale[buyNft_.offerId];
        CryptoTokens memory tokenDetails;
        if (sale.isERC1155) {
            uint256 serviceFee = _percent(
                (sale.price).mul(buyNft_.quantity),
                _marketplaceManager.serviceFeePercent()
            );
            if (
                keccak256(abi.encodePacked(_saleCurrency[buyNft_.offerId])) ==
                keccak256(abi.encodePacked(""))
            ) {
                require(
                    buyNft_.payment >=
                        serviceFee.add((sale.price).mul(buyNft_.quantity)),
                    "not enough funds sent"
                );
            } else {
                require(
                    isSalesupportedTokens[_saleCurrency[buyNft_.offerId]],
                    "unsupported token"
                );
                tokenDetails = _marketplaceManager.cryptoTokenList(
                    _saleCurrency[buyNft_.offerId]
                );
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(
                    allowance >=
                        serviceFee.add((sale.price).mul(buyNft_.quantity)),
                    "not enough token allowance"
                );
                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    serviceFee.add((sale.price).mul(buyNft_.quantity))
                );
            }

            (
                address[] memory recipientAddresses,
                uint256[] memory paymentAmount,
                ,

            ) = _marketplaceManager.calculatePayout(
                    CalculatePayout(
                        sale.tokenId,
                        sale.tokenContract,
                        sale.seller,
                        sale.price,
                        buyNft_.quantity
                    )
                );

            payout_ = Payout(
                tokenDetails.tokenAddress,
                sale.seller,
                buyNft_.buyer,
                sale.tokenId,
                sale.tokenContract,
                buyNft_.quantity,
                recipientAddresses,
                paymentAmount,
                sale.quantity == sale.soldQuantity.add(buyNft_.quantity)
                    ? true
                    : false
            );
        } else {
            uint256 offerId = buyNft_.offerId;
            uint256 serviceFee = _percent(
                sale.price,
                _marketplaceManager.serviceFeePercent()
            );
            if (
                keccak256(abi.encodePacked(_saleCurrency[buyNft_.offerId])) ==
                keccak256(abi.encodePacked(""))
            ) {
                require(
                    buyNft_.payment >= (serviceFee.add(_sale[offerId].price)),
                    "not enough funds sent"
                );
            } else {
                require(
                    isSalesupportedTokens[_saleCurrency[buyNft_.offerId]],
                    "unsupported token"
                );
                tokenDetails = _marketplaceManager.cryptoTokenList(
                    _saleCurrency[buyNft_.offerId]
                );
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(
                    allowance >= (serviceFee.add(_sale[offerId].price)),
                    "not enough token allowance"
                );

                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    serviceFee.add(_sale[offerId].price)
                );
            }
            (
                address[] memory recipientAddresses,
                uint256[] memory paymentAmount,
                ,

            ) = _marketplaceManager.calculatePayout(
                    CalculatePayout(
                        sale.tokenId,
                        sale.tokenContract,
                        sale.seller,
                        _sale[offerId].price,
                        buyNft_.quantity
                    )
                );
            payout_ = Payout(
                tokenDetails.tokenAddress,
                sale.seller,
                buyNft_.buyer,
                sale.tokenId,
                sale.tokenContract,
                1,
                recipientAddresses,
                paymentAmount,
                true
            );
        }
        _sale[buyNft_.offerId].soldQuantity = _sale[buyNft_.offerId]
            .soldQuantity
            .add(buyNft_.quantity);
        _sale[buyNft_.offerId].buyer.push(buyNft_.buyer);
        _sale[buyNft_.offerId].purchaseQuantity.push(buyNft_.quantity);
        _sale[buyNft_.offerId].soldAt.push(block.timestamp);
    }

    function _percent(uint256 value_, uint256 percentage_)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }

    function _payout(NiftySouqIMarketplace.Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }
}
