// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "./Initializable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";

import "./NiftySouq-IMarketplaceManager.sol";
import "./NiftySouq-IERC721.sol";
import "./NiftySouq-IERC1155.sol";
import "./NiftySouq-IFixedPrice.sol";
import "./NiftySouq-IAuction.sol";

import "./BezelClub-IERC721.sol";

enum OfferState {
    OPEN,
    CANCELLED,
    ENDED
}

enum OfferType {
    SALE,
    AUCTION
}

struct MintData {
    address minter;
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
}

struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
}

struct MakeOffer {
    address tokenAddress;
    uint256 tokenId;
    bool isERC1155;
    address offeredBy;
    uint256 quantity;
    uint256 price;
    string currency;
    bool isCancelled;
}

struct MakeOfferData {
    address tokenAddress;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;
    string currency;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

contract NiftySouqMarketplaceV4 is Initializable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _admin;

    NiftySouqIMarketplaceManager private _niftySouqMarketplaceManager;
    NiftySouqIERC721V2 private _niftySouqErc721;
    NiftySouqIERC1155V2 private _niftySouqErc1155;
    NiftySouqIFixedPrice private _niftySouqFixedPrice;
    NiftySouqIAuction private _niftySouqAuction;

    Counters.Counter private _offerId;
    mapping(uint256 => Offer) private _offers;

    uint256 public constant PERCENT_UNIT = 1e4;
    address private _bezelNftContractAddress;

    Counters.Counter private _makeOfferId;
    mapping(uint256 => MakeOffer) private _makeOffers;
    mapping(address => mapping(uint256 => uint256[])) private _makeOffersList;

    event eMint(
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity
    );

    event eMakeOffer(
        uint256 makeOfferId,
        address tokenAddress,
        uint256 tokenId,
        address offeredBy,
        uint256 quantity,
        uint256 price,
        string currency
    );
    event eCancelOffer(uint256 makeOfferId);

    event eAcceptOffer(uint256 makeOfferId);

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    modifier isNiftyAdmin() {
        require(
            (_admin == msg.sender) ||
                (_niftySouqMarketplaceManager.isAdmin(msg.sender)),
            "NiftyMarketplace: unauthorized."
        );
        _;
    }

    //todo add restriction modifier

    function initialize() public initializer {
        _admin = msg.sender;
    }

    function setContractAddresses(
        address marketplaceManager_,
        address erc721_,
        address erc1155_,
        address fixedPrice_,
        address auction_
    ) public isNiftyAdmin {
        if (marketplaceManager_ != address(0))
            _niftySouqMarketplaceManager = NiftySouqIMarketplaceManager(
                marketplaceManager_
            );
        if (erc721_ != address(0))
            _niftySouqErc721 = NiftySouqIERC721V2(erc721_);
        if (erc1155_ != address(0))
            _niftySouqErc1155 = NiftySouqIERC1155V2(erc1155_);
        if (fixedPrice_ != address(0))
            //todo check usage
            _niftySouqFixedPrice = NiftySouqIFixedPrice(fixedPrice_);
        if (auction_ != address(0))
            _niftySouqAuction = NiftySouqIAuction(auction_);
    }

    //Mint
    function mintNft(MintData memory mintData_)
        public
        returns (
            uint256 tokenId_,
            bool erc1155_,
            address tokenAddress_
        )
    {
        require(mintData_.quantity > 0, "quantity should be grater than 0");

        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                mintData_.tokenAddress,
                mintData_.quantity
            );
        erc1155_ = isERC1155;
        tokenAddress_ = tokenAddress;
        address minter;
        if (
            msg.sender == address(_niftySouqFixedPrice) ||
            msg.sender == address(_niftySouqAuction)
        ) minter = mintData_.minter;
        else minter = msg.sender;
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.MintData
                memory mintData1155_ = NiftySouqIERC1155V2.MintData(
                    mintData_.uri,
                    minter,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    mintData_.quantity
                );
            tokenId_ = NiftySouqIERC1155V2(tokenAddress).mint(mintData1155_);
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
                .MintData(
                    mintData_.uri,
                    minter,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    true
                );
            tokenId_ = NiftySouqIERC721V2(tokenAddress).mint(mintData721_);
            erc1155_ = false;
        }
        emit eMint(
            tokenId_,
            tokenAddress,
            erc1155_,
            minter,
            mintData_.quantity
        );
    }

    function lazyMintSellNft(
        uint256 purchaseQuantity,
        LazyMintSellData calldata lazyMintSellData_
    ) external payable returns (uint256 offerId_, uint256 tokenId_) {
        require(
            lazyMintSellData_.seller != msg.sender,
            "Nifty1155: seller and buyer is same"
        );

        address signerV2 = _niftySouqMarketplaceManager
            .verifyFixedPriceLazyMintV2(lazyMintSellData_);
        if (lazyMintSellData_.seller != signerV2) {
            address signerV1 = _niftySouqMarketplaceManager
                .verifyFixedPriceLazyMintV1(lazyMintSellData_);
            require(
                lazyMintSellData_.seller == signerV1,
                "Nifty721: signature not verified"
            );
        }

        (offerId_, tokenId_) = _lazyMint(
            purchaseQuantity,
            msg.value,
            lazyMintSellData_
        );
    }

    function _lazyMint(
        uint256 purchaseQuantity,
        uint256 payment,
        LazyMintSellData calldata lazyMintSellData_
    ) private returns (uint256 offerId_, uint256 tokenId_) {
        (
            ContractType contractType,
            bool isERC1155,
            address tokenAddress
        ) = _niftySouqMarketplaceManager.getContractDetails(
                lazyMintSellData_.tokenAddress,
                lazyMintSellData_.quantity
            );
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            // NiftySouqIERC1155V2.LazyMintData
            //     memory lazyMintData_ =
            tokenId_ = _niftySouqErc1155.lazyMint(
                NiftySouqIERC1155V2.LazyMintData(
                    lazyMintSellData_.uri,
                    lazyMintSellData_.seller,
                    msg.sender,
                    lazyMintSellData_.creators,
                    lazyMintSellData_.royalties,
                    lazyMintSellData_.investors,
                    lazyMintSellData_.revenues,
                    lazyMintSellData_.quantity,
                    purchaseQuantity
                )
            );
            emit eMint(
                tokenId_,
                address(_niftySouqErc1155),
                isERC1155,
                lazyMintSellData_.seller,
                lazyMintSellData_.quantity.sub(purchaseQuantity)
            );
            emit eMint(
                tokenId_,
                address(_niftySouqErc1155),
                isERC1155,
                msg.sender,
                purchaseQuantity
            );
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            // MintData memory mintData = MintData(
            //     msg.sender,
            //     tokenAddress,
            //     lazyMintSellData_.uri,
            //     lazyMintSellData_.creators,
            //     lazyMintSellData_.royalties,
            //     lazyMintSellData_.investors,
            //     lazyMintSellData_.revenues,
            //     lazyMintSellData_.quantity
            // );

            (
                uint256 tokenId__,
                bool isERC1155__,
                address tokenAddress__
            ) = mintNft(
                    MintData(
                        msg.sender,
                        tokenAddress,
                        lazyMintSellData_.uri,
                        lazyMintSellData_.creators,
                        lazyMintSellData_.royalties,
                        lazyMintSellData_.investors,
                        lazyMintSellData_.revenues,
                        lazyMintSellData_.quantity
                    )
                );
            tokenId_ = tokenId__;
            isERC1155 = isERC1155__;
            tokenAddress = tokenAddress__;
        }
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            purchaseQuantity < lazyMintSellData_.quantity
                ? OfferState.OPEN
                : OfferState.ENDED,
            ContractType.NIFTY_V2
        );

        // LazyMintData memory lazyMintData = LazyMintData(
        //     offerId_,
        //     tokenId_,
        //     tokenAddress,
        //     isERC1155,
        //     lazyMintSellData_.quantity,
        //     lazyMintSellData_.minPrice,
        //     lazyMintSellData_.seller,
        //     purchaseQuantity,
        //     msg.sender,
        //     purchaseQuantity,
        //     lazyMintSellData_.investors,
        //     lazyMintSellData_.revenues,
        //     lazyMintSellData_.currency
        // );
        NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(
            LazyMintData(
                offerId_,
                tokenId_,
                tokenAddress,
                isERC1155,
                lazyMintSellData_.quantity,
                lazyMintSellData_.minPrice,
                lazyMintSellData_.seller,
                msg.sender,
                purchaseQuantity,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues,
                lazyMintSellData_.currency
            )
        );

        address[] memory recipientAddresses = new address[](
            lazyMintSellData_.investors.length.add(2)
        );
        uint256[] memory paymentAmount = new uint256[](
            lazyMintSellData_.revenues.length.add(2)
        );
        uint256 serviceFee = _percent(
            (lazyMintSellData_.minPrice).mul(purchaseQuantity),
            _niftySouqMarketplaceManager.serviceFeePercent()
        );
        {
            uint256 i;
            uint256 revenueSum = 0;
            for (i = 0; i < lazyMintSellData_.revenues.length; i++) {
                uint256 revenue = _percent(
                    lazyMintSellData_.minPrice.mul(purchaseQuantity),
                    lazyMintSellData_.revenues[i]
                );
                recipientAddresses[i] = lazyMintSellData_.investors[i];
                paymentAmount[i] = revenue;
                revenueSum = revenueSum.add(revenue);
            }

            recipientAddresses[i] = _niftySouqMarketplaceManager
                .serviceFeeWallet();
            paymentAmount[i] = serviceFee;
            i = i + 1;

            recipientAddresses[i] = lazyMintSellData_.seller;
            paymentAmount[i] = (
                lazyMintSellData_.minPrice.mul(purchaseQuantity)
            ).sub(revenueSum);
            i = i + 1;
        }
        // CryptoTokens memory tokenDetails;

        if (
            keccak256(abi.encodePacked(lazyMintSellData_.currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            require(
                payment >=
                    (
                        serviceFee.add(
                            (lazyMintSellData_.minPrice).mul(purchaseQuantity)
                        )
                    ),
                "not enough funds sent"
            );
            payout(Payout(address(0), recipientAddresses, paymentAmount));
        } else {
            uint256 totalPayment = serviceFee.add(
                (lazyMintSellData_.minPrice).mul(purchaseQuantity)
            );
            require(
                _niftySouqFixedPrice.isSalesupportedTokens(
                    lazyMintSellData_.currency
                ),
                "unsupported token"
            );
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .cryptoTokenList(lazyMintSellData_.currency);
            {
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(
                    allowance >= totalPayment,
                    "not enough token allowance"
                );
            }
            IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalPayment
            );
            payout(
                Payout(
                    tokenDetails.tokenAddress,
                    recipientAddresses,
                    paymentAmount
                )
            );
        }
    }

    function setBezelContractAddress(address bezelAddress_) external {
        _bezelNftContractAddress = bezelAddress_;
    }

    function sellBezelNft(BezelClubIERC721.LazyMintData memory lazyData_)
        public
        returns (uint256 tokenId_, uint256 offerId_)
    {
        // mint nft
        tokenId_ = BezelClubIERC721(_bezelNftContractAddress).lazyMint(
            lazyData_
        );
        emit eMint(
            tokenId_,
            _bezelNftContractAddress,
            false,
            lazyData_.seller,
            1
        );

        // create offer
        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(
            LazyMintData(
                offerId_,
                tokenId_,
                _bezelNftContractAddress,
                false,
                1,
                lazyData_.price,
                lazyData_.seller,
                lazyData_.buyer,
                1,
                new address[](0),
                new uint256[](0),
                lazyData_.currency
            )
        );
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.ENDED,
            ContractType.EXTERNAL
        );

        // payout calculation
        address[] memory recipientAddresses = new address[](2);
        uint256[] memory paymentAmount = new uint256[](2);
        uint256 serviceFee = _percent(
            lazyData_.price,
            _niftySouqMarketplaceManager.serviceFeePercent()
        );
        recipientAddresses[0] = _niftySouqMarketplaceManager.serviceFeeWallet();
        paymentAmount[0] = serviceFee;

        recipientAddresses[1] = lazyData_.seller;
        paymentAmount[1] = lazyData_.price;
        require(
            _niftySouqFixedPrice.isSalesupportedTokens(lazyData_.currency),
            "unsupported token"
        );
        CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
            .cryptoTokenList(lazyData_.currency);
        {
            uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                .allowance(msg.sender, address(this));
            require(
                allowance >= (lazyData_.price).add(serviceFee),
                "not enough token allowance"
            );
        }
        IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
            msg.sender,
            address(this),
            (lazyData_.price).add(serviceFee)
        );
        payout(
            Payout(tokenDetails.tokenAddress, recipientAddresses, paymentAmount)
        );
    }

    function createSale(
        uint256 tokenId_,
        ContractType contractType_,
        OfferType offerType_
    ) external returns (uint256 offerId_) {
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            offerType_,
            OfferState.OPEN,
            contractType_
        );
    }

    function endSale(uint256 offerId_, OfferState offerState_) external {
        _offers[offerId_].status = offerState_;
    }

    function getMakerOfferDetails(uint256 makeOfferId_)
        public
        view
        returns (MakeOffer memory makeOfferData_)
    {
        return _makeOffers[makeOfferId_];
    }

    //Make offer for sale
    function makeOffer(MakeOfferData calldata makeOfferData_) public payable {
        (
            ContractType contractType,
            bool isERC1155,
            ,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                makeOfferData_.tokenId,
                makeOfferData_.tokenAddress
            );
        require(contractType != ContractType.UNSUPPORTED, "not NFT contract");

        if (
            keccak256(abi.encodePacked(makeOfferData_.currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            require(
                msg.value == makeOfferData_.price.mul(makeOfferData_.quantity),
                "amount transfered and specified not equalent"
            );
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .cryptoTokenList(makeOfferData_.currency);
            uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                .allowance(msg.sender, address(this));
            require(
                allowance >= makeOfferData_.price,
                "not enough token allowance"
            );
            IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                makeOfferData_.price
            );
        }

        _makeOfferId.increment();
        _makeOffers[_makeOfferId.current()] = MakeOffer(
            makeOfferData_.tokenAddress,
            makeOfferData_.tokenId,
            isERC1155,
            msg.sender,
            makeOfferData_.quantity,
            makeOfferData_.price,
            makeOfferData_.currency,
            false
        );

        _makeOffersList[makeOfferData_.tokenAddress][makeOfferData_.tokenId]
            .push(_makeOfferId.current());

        emit eMakeOffer(
            _makeOfferId.current(),
            makeOfferData_.tokenAddress,
            makeOfferData_.tokenId,
            msg.sender,
            makeOfferData_.quantity,
            makeOfferData_.price,
            makeOfferData_.currency
        );
    }

    //cancel offer for sale
    function editOffer(uint256 makeOfferId_, uint256 price_) public payable {
        require(
            makeOfferId_ <= _makeOfferId.current(),
            "make offer id doesnt exist"
        );
        require(
            _makeOffers[makeOfferId_].offeredBy == msg.sender,
            "not offer owner"
        );
        require(
            _makeOffers[makeOfferId_].isCancelled == false,
            "offer already cancelled"
        );

        if (price_ > _makeOffers[makeOfferId_].price) {
            uint256 priceDiff = price_.sub(_makeOffers[makeOfferId_].price);
            if (
                keccak256(
                    abi.encodePacked(_makeOffers[makeOfferId_].currency)
                ) == keccak256(abi.encodePacked(""))
            ) {
                require(
                    msg.value == priceDiff,
                    "amount transfered and specified not equalent"
                );
            } else {
                CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                    .cryptoTokenList(_makeOffers[makeOfferId_].currency);
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                require(allowance >= priceDiff, "not enough token allowance");
                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    priceDiff
                );
            }
        } else if (price_ < _makeOffers[makeOfferId_].price) {
            uint256 priceDiff = _makeOffers[makeOfferId_].price.sub(price_);
            address[] memory refundAddresses;
            refundAddresses[0] = _makeOffers[makeOfferId_].offeredBy;
            uint256[] memory refundAmount;
            refundAmount[0] = priceDiff;
            if (
                keccak256(
                    abi.encodePacked(_makeOffers[makeOfferId_].currency)
                ) == keccak256(abi.encodePacked(""))
            ) {
                payout(Payout(address(0), refundAddresses, refundAmount));
            } else {
                CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                    .cryptoTokenList(_makeOffers[makeOfferId_].currency);
                payout(
                    Payout(
                        tokenDetails.tokenAddress,
                        refundAddresses,
                        refundAmount
                    )
                );
            }
        } else {
            revert("already same price");
        }

        _makeOffers[makeOfferId_].price = price_;
    }

    //cancel offer for sale
    function cancelOffer(uint256 makeOfferId_) public {
        require(
            makeOfferId_ <= _makeOfferId.current(),
            "make offer id doesnt exist"
        );
        require(
            _makeOffers[makeOfferId_].offeredBy == msg.sender,
            "not offer owner"
        );

        require(
            _makeOffers[makeOfferId_].isCancelled == false,
            "offer already cancelled"
        );

        _makeOffers[makeOfferId_].isCancelled = true;
        address[] memory refundAddresses = new address[](1);
        refundAddresses[0] = _makeOffers[makeOfferId_].offeredBy;
        uint256[] memory refundAmount = new uint256[](1);
        refundAmount[0] = _makeOffers[makeOfferId_].price;
        if (
            keccak256(abi.encodePacked(_makeOffers[makeOfferId_].currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            payout(Payout(address(0), refundAddresses, refundAmount));
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .cryptoTokenList(_makeOffers[makeOfferId_].currency);
            payout(
                Payout(tokenDetails.tokenAddress, refundAddresses, refundAmount)
            );
        }
    }

    // Accept Offer
    function acceptOffer(uint256 makeOfferId_)
        public
        payable
        returns (uint256 offerId_)
    {
        require(
            makeOfferId_ <= _makeOfferId.current(),
            "make offer id doesnt exist"
        );

        require(
            _makeOffers[makeOfferId_].isCancelled == false,
            "offer already cancelled"
        );

        (, bool isERC1155, ) = _niftySouqMarketplaceManager.getContractDetails(
            _makeOffers[makeOfferId_].tokenAddress,
            _makeOffers[makeOfferId_].quantity
        );

        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
            _niftySouqFixedPrice
        ).acceptOffer(
                AcceptOfferData(
                    offerId_,
                    _makeOffers[makeOfferId_].tokenId,
                    _makeOffers[makeOfferId_].tokenAddress,
                    isERC1155,
                    _makeOffers[makeOfferId_].quantity,
                    _makeOffers[makeOfferId_].price,
                    msg.sender,
                    block.timestamp,
                    _makeOffers[makeOfferId_].offeredBy,
                    block.timestamp,
                    _makeOffers[makeOfferId_].currency
                )
            );
        payoutData.refundAmount[
            payoutData.refundAmount.length.sub(1)
        ] = payoutData.refundAmount[payoutData.refundAmount.length.sub(1)].sub(
            payoutData.refundAmount[payoutData.refundAmount.length.sub(2)]
        );
        if (
            keccak256(abi.encodePacked(_makeOffers[makeOfferId_].currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            payout(
                Payout(
                    address(0),
                    payoutData.refundAddresses,
                    payoutData.refundAmount
                )
            );
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .cryptoTokenList(_makeOffers[makeOfferId_].currency);
            payout(
                Payout(
                    tokenDetails.tokenAddress,
                    payoutData.refundAddresses,
                    payoutData.refundAmount
                )
            );
        }
        _makeOffers[makeOfferId_].isCancelled == true;

        transferNFT(
            msg.sender,
            _makeOffers[makeOfferId_].offeredBy,
            _makeOffers[makeOfferId_].tokenId,
            _makeOffers[makeOfferId_].tokenAddress,
            _makeOffers[makeOfferId_].quantity
        );
        emit eAcceptOffer(makeOfferId_);

        for (
            uint256 i = 0;
            i <
            _makeOffersList[_makeOffers[makeOfferId_].tokenAddress][
                _makeOffers[makeOfferId_].tokenId
            ].length;
            i++
        ) {
            uint256 makeOfferId = _makeOffersList[
                _makeOffers[makeOfferId_].tokenAddress
            ][_makeOffers[makeOfferId_].tokenId][i];
            if (
                _makeOffers[makeOfferId].isCancelled == false &&
                makeOfferId_ != makeOfferId
            ) {
                if (
                    keccak256(
                        abi.encodePacked(_makeOffers[makeOfferId_].currency)
                    ) == keccak256(abi.encodePacked(""))
                ) {
                    payable(_makeOffers[makeOfferId].offeredBy).transfer(
                        _makeOffers[makeOfferId].price
                    );
                    emit ePayoutTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price,
                        address(0)
                    );
                } else {
                    CryptoTokens
                        memory tokenDetails = _niftySouqMarketplaceManager
                            .cryptoTokenList(
                                _makeOffers[makeOfferId_].currency
                            );
                    IERC20Upgradeable(tokenDetails.tokenAddress).safeTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price
                    );
                    emit ePayoutTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price,
                        tokenDetails.tokenAddress
                    );
                }
                _makeOffers[makeOfferId].isCancelled == true;
            }
        }
        uint256[] memory initArr = new uint256[](0);
        _makeOffersList[_makeOffers[makeOfferId_].tokenAddress][
            _makeOffers[makeOfferId_].tokenId
        ] = initArr;
    }

    //get offer details
    function getOfferStatus(uint256 offerId_)
        public
        view
        returns (Offer memory offerDetails_)
    {
        require(offerId_ <= _offerId.current(), "offer id doesnt exist");
        offerDetails_ = _offers[offerId_];
    }

    function payout(Payout memory payoutData_) public {
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

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) public {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                from_,
                tokenId_,
                tokenAddress_
            );
        require(isOwner, "seller not owner");
        require(quantity >= quantity_, "insufficient token balance");
        if (
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155
        ) {
            NiftySouqIERC721V2(tokenAddress_).transferNft(from_, to_, tokenId_);
        } else if (contractType == ContractType.NIFTY_V2 && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).transferNft(
                from_,
                to_,
                tokenId_,
                quantity_
            );
        } else if (!isERC1155) {
            NiftySouqIERC721V2(tokenAddress_).transferFrom(
                from_,
                to_,
                tokenId_
            );
        } else if (isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).safeTransferFrom(
                from_,
                to_,
                tokenId_,
                quantity_,
                ""
            );
        }
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
}
