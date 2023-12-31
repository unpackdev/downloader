// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./SafeERC20Upgradeable.sol";
import "./Artfi-ICollection.sol";
import "./Artfi-IPassVoucher.sol";
import "./Artfi-IFixedPrice.sol";
import "./Artfi-IManager.sol";
import "./Artfi-IPassVoucher.sol";
import "./console.sol";

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
    address seller;
    address buyer;
    address tokenAddress;
    string uri;
    uint256 fractionId;
    address[] creators;
    uint256[] royalties;
    uint256 quantity;
}

struct PassVoucherData {
    address seller;
    address buyer;
    address tokenAddress;
    string uri;
    bool unclaimed;
}

struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

/**
 *@title Marketplace contract.
 *@dev Marketplace is an implementation contract of initializable contract.
 */
contract ArtfiMarketplaceV2 is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address payable;

    //*********************** Declarations ***********************//
    address private _admin;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    ArtfiIManager private _artfiManager;
    ArtfiIFixedPrice private _artfiFixedPrice;

    Counters.Counter private _offerId;
    mapping(uint256 => Offer) private _offers;

    uint256 public constant PERCENT_UNIT = 1e4;

    Counters.Counter private _makeOfferId;

    // mapping digest to keep track of claimed vouchers
    mapping(bytes32 => bool) isVoucherClaimed;

    //*********************** Events ***********************//
    event eMint(
        uint256 tokenId,
        address contractAddress,
        address owner,
        uint256 quantity
    );

    event eMintPassVoucher(
        uint256 tokenId,
        address contractAddress,
        address owner,
        bool unclaimed
    );

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    event eMintClaim(
        uint256 tokenId,
        uint256 offerId,
        address buyer,
        address tokenAddress,
        string uri
    );

    //*********************** Modifiers ***********************//
    modifier isArtfiAdmin() {
        if ((_admin != msg.sender) && (!_artfiManager.isAdmin(msg.sender)))
            revert GeneralError("AF:102");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     *@notice Initializes the contract.
     *@dev used instead of constructor.
     */
    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        _setRoleAdmin(PAUSER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(UPGRADER_ROLE, ADMIN_ROLE);

        _admin = msg.sender;
    }

    /**
     *@notice sets addresses of contracts.
     *@param Manager_ address of Manager contract.
     *@param fixedPrice_ address of fixed price contract.
     */
    function setContractAddresses(
        address Manager_,
        address fixedPrice_
    ) external isArtfiAdmin {
        if(Manager_ == address(0) || fixedPrice_ == address(0)) revert GeneralError("AF:205");
        if (Manager_ != address(0)) _artfiManager = ArtfiIManager(Manager_);
        // if (collection_ != address(0))
        //     _artfiCollection = ArtfiICollectionV2(collection_);
        if (fixedPrice_ != address(0))
            _artfiFixedPrice = ArtfiIFixedPrice(fixedPrice_);
    }

    //*********************** Getter Functions ***********************//

    function getConfiguration()
        external
        view
        returns (address Manager_, address fixedPrice_)
    {
        Manager_ = address(_artfiManager);
        // collection_ = address(_artfiCollection);
        fixedPrice_ = address(_artfiFixedPrice);
    }

    /**
     *@notice get offer details of NFT.
     *@param offerId_ offerId of NFT.
     *@return offerDetails_ offer details of NFT.
     */
    function getOfferStatus(
        uint256 offerId_
    ) external view returns (Offer memory offerDetails_) {
        if (offerId_ > _offerId.current()) revert GeneralError("AF:125");
        if(offerId_ <= 0) revert GeneralError("AF:202");
        offerDetails_ = _offers[offerId_];
    }

    //*********************** Setter Functions ***********************//

    /**
     *@notice for creating sale.
     *@param tokenId_ Id of token.
     *@param offerType_ Type of offer such as sale or auction.
     *@return offerId_ OfferId of NFT.
     */
    function createSale(
        uint256 tokenId_,
        ContractType contractType_,
        OfferType offerType_
    ) external returns (uint256 offerId_) {
        if (msg.sender != address(_artfiFixedPrice))
            revert GeneralError("AF:109");
        if (_artfiManager.isBlocked(msg.sender)) revert GeneralError("AF:126");
        if (_artfiManager.isPaused()) revert GeneralError("AF:128");
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            offerType_,
            OfferState.OPEN,
            contractType_
        );
    }

    /**
     *@notice ends sale.
     *@param offerId_ offerId of NFT
     *@param offerState_ state of offer such as open ,cancelled, ended.
     */
    function endSale(uint256 offerId_, OfferState offerState_) external {
        if (msg.sender != address(_artfiFixedPrice))
            revert GeneralError("AF:109");

        _offers[offerId_].status = offerState_;
    }

    /**
     * @notice Function to air drop NFT after sell all passes
     * @param tokenIds array of tokenIds to airdrop
     * @param _mintData data of the NFTs
     */
    function AirDropNftBatch(
        uint256[] calldata tokenIds,
        MintData[] calldata _mintData
    ) external isArtfiAdmin {
        if(tokenIds.length != _mintData.length) revert GeneralError("AF:201");
        if(tokenIds.length <=0) revert GeneralError("AF:202");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            ArtfiICollectionV2.MintData
                memory mintDataCollection_ = ArtfiICollectionV2.MintData(
                    _mintData[i].uri,
                    _mintData[i].fractionId,
                    _mintData[i].seller,
                    _mintData[i].buyer,
                    _mintData[i].creators,
                    _mintData[i].royalties,
                    true
                );
            ArtfiICollectionV2(_mintData[i].tokenAddress).setNftData(
                tokenIds[i],
                mintDataCollection_
            );
            ArtfiICollectionV2(_mintData[i].tokenAddress).transferNft(
                msg.sender,
                _mintData[i].buyer,
                tokenIds[i]
            );
        }
    }

    /**
     * @notice Function to mint batch of NFTs
     * @param _mintData NFT data tuple
     */
    function batchMint(MintData[] memory _mintData) public isArtfiAdmin {
        if(_mintData.length <= 0) revert GeneralError("AF:201");
        for (uint256 i = 0; i < _mintData.length; i++) {
            _mintNft(_mintData[i]);
        }
    }

    /**
     * @notice Function to mint a batch of Psses
     * @param buyer_  buyer address
     * @param mintData_ data to mint the pass token
     * @param totalPrice total price of the batch pass token
     * @param currency currency to buy the pass
     * @param quantity number of passes to buy
     */

    function mintPassBatch(
        address buyer_,
        PassVoucherData memory mintData_,
        uint256 totalPrice,
        string memory currency,
        uint256 quantity
    ) public payable nonReentrant {
        if (
            !ArtfiIPassVoucherV2(mintData_.tokenAddress).isQuantityAllowed(
                quantity
            )
        ) revert GeneralError("AF:309");
        if (bytes(currency).length == 0) {
            if (msg.value != totalPrice) {
                revert GeneralError("AF:304");
            }
        }

        if (bytes(currency).length != 0) {
            CryptoTokens memory tokenDetails = _artfiManager.getTokenDetail(
                currency
            );
            {
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                if (allowance != totalPrice) revert GeneralError("AF:124");
            }
        }

        uint256 price = totalPrice / quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _mintPassVoucher(buyer_, mintData_, price, currency);
        }
    }

    // function claimVoucherService(
    //     address tokenAddress,
    //     uint256 tokenId
    // ) public returns (string memory uri) {}

    // /**
    //  *@notice mints the NFT while purchasing .
    //  *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
    //  *@param buyer address of the buyer.
    //  *@param lazyMintSellData_  contain token address, uri,seller address,buyer address, uid, creater addresses, royalties percentage,miPrice, purchase quantity, signature, currency.
    //  *@return offerId_ offerId of nft.
    //  *@return tokenId_ Id of token.
    //  */
    // function lazyMintSellNft(
    //     address buyer,
    //     LazyMintSellData memory lazyMintSellData_
    // ) public payable nonReentrant returns (uint256 offerId_, uint256 tokenId_) {

    //     if (lazyMintSellData_.seller == msg.sender)
    //         revert GeneralError("AF:305");
    //     if (_artfiManager.isBlocked(msg.sender)) revert GeneralError("AF:126");

    //     if (_artfiManager.isPaused()) revert GeneralError("AF:128");

    //     address signerV2;
    //     bytes32 digest;
    //     (signerV2, digest) = _artfiManager.verifyFixedPriceLazyMintV2(
    //         lazyMintSellData_
    //     );

    //     if (lazyMintSellData_.seller != signerV2) {
    //         revert GeneralError("AF:306");
    //     }

    //     if (isVoucherClaimed[digest]) {
    //         revert GeneralError("AF:307");
    //     }

    //     (offerId_, tokenId_) = _lazyMint(buyer, msg.value, lazyMintSellData_);

    //     isVoucherClaimed[digest] = true;
    // }

    // /**
    //  *@notice claim batch.
    //  *@param buyer is the address of the user
    //  *@param purchaseQuantity quantity of nfts during purchase.
    //  *@param passAddress the pass contract address.
    //  *@param passTokenId an array of the token Ids of the NFT the user purchased from pass contract.
    //  *@param passUri an array of the token uri hashs
    //  *@param lazyMintBatchData_ is array of signed vouchers object.

    //  */
    // function claimNftWithPassBatch(
    //     address buyer,
    //     uint256 purchaseQuantity,
    //     address passAddress,
    //     uint256[] memory passTokenId,
    //     string[] memory passUri,
    //     LazyMintSellData[] memory lazyMintBatchData_
    // ) public isArtfiAdmin {
    //     if (
    //         !ArtfiICollectionV2(passAddress)
    //             .isQuantityAllowed(purchaseQuantity)
    //     ) revert GeneralError("AF:309");
    //     for (uint256 i = 0; i < purchaseQuantity; i++) {
    //         bool unClaimed_ = ArtfiIPassVoucherV2(passAddress)
    //             .getUnclaimedTokens(passTokenId[i]);
    //         if (unClaimed_ == false) revert GeneralError("AF:307");
    //         (uint256 offerId_, uint256 tokenId_) = _claimNftWithPass(
    //             buyer,
    //             lazyMintBatchData_[i]
    //         );

    //         emit eMintClaim(
    //             tokenId_,
    //             offerId_,
    //             buyer,
    //             lazyMintBatchData_[i].tokenAddress,
    //             lazyMintBatchData_[i].uri
    //         );

    //         ArtfiIPassVoucherV2(passAddress).updateUnclaimedAttributes(
    //             passTokenId[i],
    //             false
    //         );
    //         ArtfiIPassVoucherV2(passAddress).updateTokenURI(
    //             passTokenId[i],
    //             passUri[i]
    //         );
    //     }
    // }

    // /**
    //  *@notice mint batch.
    //  *@param lazyMintBatchData_ is array of signed vouchers object.
    //  */
    // function lazyMintSellBatch(
    //     address tokenAddress,
    //     LazyMintSellData[] memory lazyMintBatchData_
    // ) public payable {
    //     if (
    //         !ArtfiICollectionV2(tokenAddress)
    //             .isQuantityAllowed(lazyMintBatchData_.length)
    //     ) revert GeneralError("AF:309");
    //     uint256 _totalMinPrice;
    //     for (uint256 i = 0; i < lazyMintBatchData_.length; i++) {
    //         if (bytes(lazyMintBatchData_[i].currency).length == 0) {
    //           _totalMinPrice += lazyMintBatchData_[i].minPrice;
    //         }
    //     }
    //     if (msg.value != _totalMinPrice) {
    //         revert GeneralError("AF:304");
    //     }
    //     for (uint256 i = 0; i < lazyMintBatchData_.length; i++) {
    //         lazyMintSellNft(lazyMintBatchData_[i].buyer, lazyMintBatchData_[i]);
    //     }
    // }

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_
    ) external {
        if (msg.sender != address(_artfiFixedPrice))
            revert GeneralError("AF:109");
        _transferNFT(from_, to_, tokenId_, tokenAddress_);
    }

    //*********************** Internal Functions ***********************//

    /**
     *@notice mints NFT .
     *@param mintData_ contains uri, creater addresses, royalties percentage,minter address.
     *@return tokenId_ Id of NFT.
     */
    function _mintNft(
        MintData memory mintData_
    ) private returns (uint256 tokenId_) {
        if (mintData_.quantity <= 0) revert GeneralError("AF:303");
        if (_artfiManager.isBlocked(msg.sender)) revert GeneralError("AF:126");
        if (_artfiManager.isPaused()) revert GeneralError("AF:128");

        ArtfiICollectionV2.MintData
            memory mintDataCollection_ = ArtfiICollectionV2.MintData(
                mintData_.uri,
                mintData_.fractionId,
                mintData_.seller,
                mintData_.buyer,
                mintData_.creators,
                mintData_.royalties,
                true
            );
        tokenId_ = ArtfiICollectionV2(mintData_.tokenAddress).mint(
            mintDataCollection_
        );

        emit eMint(
            tokenId_,
            mintData_.tokenAddress,
            mintData_.buyer,
            mintData_.quantity
        );
    }

    /**
     *
     * @param buyer_  buyer address
     * @param mintData_ data to mint the pass token
     * @param price price of the pass token
     * @param currency currency to buy the pass
     * @return tokenId_
     * @return offerId_
     */

    function _mintPassVoucher(
        address buyer_,
        PassVoucherData memory mintData_,
        uint256 price,
        string memory currency
    ) internal returns (uint256 tokenId_, uint256 offerId_) {
        if (price <= 0) revert GeneralError("AF:302");
        if (_artfiManager.isBlocked(msg.sender)) revert GeneralError("AF:126");
        if (_artfiManager.isPaused()) revert GeneralError("AF:128");
         if (mintData_.unclaimed == false) revert GeneralError("AF:303");

        ArtfiIPassVoucherV2.MintData
            memory mintDataPassVoucher_ = ArtfiIPassVoucherV2.MintData(
                mintData_.uri,
                mintData_.unclaimed,
                mintData_.tokenAddress,
                mintData_.seller,
                buyer_
            );
        tokenId_ = ArtfiIPassVoucherV2(mintData_.tokenAddress).mint(
            mintDataPassVoucher_
        );
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.ENDED,
            ContractType.ARTFI_V2
        );

        address[] memory recipientAddresses = new address[](
            [mintData_.seller].length
        );
        uint256[] memory paymentAmount = new uint256[]([price].length);

        uint256 i = 0;
        recipientAddresses[i] = mintData_.seller;
        paymentAmount[i] = price;

        // CryptoTokens memory tokenDetails;

        if (bytes(currency).length == 0) {
            // if (msg.value != price) revert GeneralError("AF:304");
            _payout(Payout(address(0), recipientAddresses, paymentAmount));
        } else {
            // uint256 totalPayment = (price);
            bool isSupported = _artfiFixedPrice.isSaleSupportedTokens(currency);
            if (!isSupported) revert GeneralError("AF:118");
            CryptoTokens memory tokenDetails = _artfiManager.getTokenDetail(
                currency
            );
            
            bool successTransfer = IERC20Upgradeable(tokenDetails.tokenAddress)
                .transferFrom(msg.sender, address(this), price);

            if (!successTransfer) revert GeneralError("AF:130");
            _payout(
                Payout(
                    tokenDetails.tokenAddress,
                    recipientAddresses,
                    paymentAmount
                )
            );
        }

        emit eMintPassVoucher(
            tokenId_,
            mintData_.tokenAddress,
            buyer_,
            mintData_.unclaimed
        );
    }

    // /**
    //  *@notice mints the NFT while purchasing .
    //  *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
    //  *@param lazyMintSellData_  contain token address, uri,seller address,buyer address, uid, creater addresses, royalties percentage,miPrice, purchase quantity, signature, currency.
    //  *@return offerId_ offerId of nft.
    //  *@return tokenId_ Id of token.
    //  */
    // function _claimNftWithPass(
    //     address buyer,
    //     LazyMintSellData memory lazyMintSellData_
    // ) internal returns (uint256 offerId_, uint256 tokenId_) {
    //     address collectionOwner = ArtfiICollectionV2(
    //         lazyMintSellData_.tokenAddress
    //     ).getOwner();
    //     if (lazyMintSellData_.seller == collectionOwner)
    //         revert GeneralError("AF:305");
    //     if (_artfiManager.isBlocked(msg.sender)) revert GeneralError("AF:126");

    //     if (_artfiManager.isPaused()) revert GeneralError("AF:128");

    //     address signerV2;
    //     bytes32 digest;
    //     (signerV2, digest) = _artfiManager.verifyFixedPriceLazyMintV2(
    //         lazyMintSellData_
    //     );

    //     if (lazyMintSellData_.seller != signerV2) {
    //         revert GeneralError("AF:306");
    //     }

    //     if (isVoucherClaimed[digest]) {
    //         revert GeneralError("AF:307");
    //     }

    //     (offerId_, tokenId_) = _lazyMintPass(buyer, lazyMintSellData_);

    //     isVoucherClaimed[digest] = true;
    // }

    // /**
    //  *@notice mints the NFT while purchasing.
    //  *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
    //  *@param lazyMintSellData_  contains uri,seller address,creater addresses, royalties percentage,purchase quantity.
    //  *@return offerId_ offerId of nft.
    //  *@return tokenId_ Id of token.
    //  */
    // function _lazyMintPass(
    //     address buyer,
    //     LazyMintSellData memory lazyMintSellData_
    // ) private returns (uint256 offerId_, uint256 tokenId_) {
    //     uint256 tokenId__ = _mintNft(
    //         MintData(
    //             lazyMintSellData_.seller,
    //             buyer,
    //             lazyMintSellData_.tokenAddress,
    //             lazyMintSellData_.uri,
    //             lazyMintSellData_.fractionId,
    //             lazyMintSellData_.creators,
    //             lazyMintSellData_.royalties,
    //             1
    //         )
    //     );
    //     tokenId_ = tokenId__;

    //     _offerId.increment();
    //     offerId_ = _offerId.current();

    //     _offers[offerId_] = Offer(
    //         tokenId_,
    //         OfferType.SALE,
    //         OfferState.ENDED,
    //         ContractType.ARTFI_V2
    //     );

    //     ArtfiIFixedPrice(_artfiFixedPrice).lazyMint(
    //         LazyMintData(
    //             offerId_,
    //             tokenId_,
    //             lazyMintSellData_.tokenAddress,
    //             1,
    //             lazyMintSellData_.minPrice,
    //             lazyMintSellData_.seller,
    //             buyer,
    //             lazyMintSellData_.currency
    //         )
    //     );
    // }

    // /**
    //  *@notice mints the NFT while purchasing.
    //  *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
    //  *@param payment payment of purchase.
    //  *@param lazyMintSellData_  contains uri,seller address,creater addresses, royalties percentage,purchase quantity.
    //  *@return offerId_ offerId of nft.
    //  *@return tokenId_ Id of token.
    //  */
    // function _lazyMint(
    //     address buyer,
    //     uint256 payment,
    //     LazyMintSellData memory lazyMintSellData_
    // ) private returns (uint256 offerId_, uint256 tokenId_) {
    //     uint256 tokenId__ = _mintNft(
    //         MintData(
    //             lazyMintSellData_.seller,
    //             buyer,
    //             lazyMintSellData_.tokenAddress,
    //             lazyMintSellData_.uri,
    //             lazyMintSellData_.fractionId,
    //             lazyMintSellData_.creators,
    //             lazyMintSellData_.royalties,
    //             1
    //         )
    //     );
    //     tokenId_ = tokenId__;

    //     _offerId.increment();
    //     offerId_ = _offerId.current();

    //     _offers[offerId_] = Offer(
    //         tokenId_,
    //         OfferType.SALE,
    //         OfferState.ENDED,
    //         ContractType.ARTFI_V2
    //     );

    //     ArtfiIFixedPrice(_artfiFixedPrice).lazyMint(
    //         LazyMintData(
    //             offerId_,
    //             tokenId_,
    //             lazyMintSellData_.tokenAddress,
    //             1,
    //             lazyMintSellData_.minPrice,
    //             lazyMintSellData_.seller,
    //             buyer,
    //             lazyMintSellData_.currency
    //         )
    //     );

    //     address[] memory recipientAddresses = new address[](
    //         [lazyMintSellData_.seller].length
    //     );
    //     uint256[] memory paymentAmount = new uint256[](
    //         [lazyMintSellData_.minPrice].length
    //     );

    //     uint256 i = 0;
    //     recipientAddresses[i] = lazyMintSellData_.seller;
    //     paymentAmount[i] = lazyMintSellData_.minPrice;

    //     // CryptoTokens memory tokenDetails;

    //     if (bytes(lazyMintSellData_.currency).length == 0) {
    //         if (payment != ((lazyMintSellData_.minPrice)))
    //             revert GeneralError("AF:304");
    //         _payout(Payout(address(0), recipientAddresses, paymentAmount));
    //     } else {
    //         uint256 totalPayment = (lazyMintSellData_.minPrice);
    //         bool isSupported = _artfiFixedPrice.isSaleSupportedTokens(
    //             lazyMintSellData_.currency
    //         );
    //         if (!isSupported) revert GeneralError("AF:118");
    //         CryptoTokens memory tokenDetails = _artfiManager.getTokenDetail(
    //             lazyMintSellData_.currency
    //         );
    //         {
    //             uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
    //                 .allowance(msg.sender, address(this));
    //             if (allowance != totalPayment) revert GeneralError("AF:124");
    //         }
    //         bool successTransfer = IERC20Upgradeable(tokenDetails.tokenAddress)
    //             .transferFrom(msg.sender, address(this), totalPayment);

    //         if (!successTransfer) revert GeneralError("AF:130");
    //         _payout(
    //             Payout(
    //                 tokenDetails.tokenAddress,
    //                 recipientAddresses,
    //                 paymentAmount
    //             )
    //         );
    //     }
    // }

    /**
     *@notice calulates the amount during NFT purchase.
     *@param payoutData_ contains currency,refundAddresses,refundAmounts.
     */
    function _payout(Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i])
                        .sendValue(payoutData_.refundAmounts[i]);
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

    /**
     *@notice Transfers 'tokenId' token from 'from' to 'to'.
     *@param from_ address of seller.
     *@param to_ address of buyer.
     *@param tokenId_ tokenId of NfT.
     *@param tokenAddress_ address of token.
     */
    function _transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_
    ) internal {
        (ContractType contractType, bool isOwner) = _artfiManager.isOwnerOfNFT(
            from_,
            tokenId_,
            tokenAddress_
        );
        if (!isOwner) revert GeneralError("AF:103");
        if (contractType == ContractType.UNSUPPORTED)
            revert GeneralError("AF:118");
        if (contractType == ContractType.ARTFI_V2) {
            ArtfiICollectionV2(tokenAddress_).transferNft(from_, to_, tokenId_);
        }
    }

    function _percent(
        uint256 value_,
        uint256 percentage_
    ) internal pure virtual returns (uint256) {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }
}
