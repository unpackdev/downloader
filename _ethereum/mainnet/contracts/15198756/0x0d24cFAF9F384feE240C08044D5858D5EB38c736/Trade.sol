// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

import "./AccessControl.sol";
import "./IRoyaltyInfo.sol";
import "./ITransferProxy.sol";

contract Trade is AccessControl {

    //@notice BuyingAssetType is an enumeration.
    //@param ERC1155 - value is 0.
    //@param ERC721 - value is 1.
    //@param LazyERC1155 - value is 2.
    //@param LazyERC721 - value is 3.

    enum BuyingAssetType {
        ERC1155,
        ERC721, 
        LazyERC1155,
        LazyERC721
    }

    //@notice OwnershipTransferred the event is emited at the time of transferownership function invoke. 
    //@param previousOwner address of the previous contract owner.
    //@param newOwner address of the new contract owner.

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    //@notice SignerAddressTransferred the event is emited at the time of transferSignerAddress function invoke. 
    //@param previousSigner address of the previous contract signer.
    //@param newSigner address of the new contract signer.

    event SignerAddressTransferred(
        address indexed previousSigner,
        address indexed newSigner
    );

    //@notice SellerFee the event is emited at the time of {setSellerFee} function invoke.
    //@param sellerFee sellerFee permile 
    event SellerFee(uint8 sellerFee);

    //@notice BuyerFee the event is emited at the time of {setBuyerFee} function invoke. 
    //@param buyerFee buyerFee permile 

    event BuyerFee(uint8 buyerFee);

    //@notice BuyAsset the event is emitted at the time of {buyAsset, mintAndBuyAsset} functions invoke.
    // the function invoked by asset buyer.
    //@param assetOwner - nft seller wallet address.
    //@param tokenId - unique tokenId.
    //@param quantity - no.of copies to be transfer.
    //@param buyer - nft buyer wallet address.

    event BuyAsset( 
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    
    //@notice ExecuteBid the event is emitted at the time of {executeBid, mintAndExecuteBid} functions invoke.
    // the function invoked by asset owner.
    //@param assetOwner - nft seller wallet address.
    //@param tokenId - unique tokenId.
    //@param quantity - no.of copies to be transfer.
    //@param buyer - nft buyer wallet address.

    event ExecuteBid(
        address nftAddress,
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer
    );
    // buyer platformFee
    uint8 private buyerFeePermille;
    //seller platformFee
    uint8 private sellerFeePermille;
    // Transferproxy contract address assciated with ITransfer Proxy interface.
    ITransferProxy public transferProxy;
    //contract owner
    address public owner;
    //contract signer
    address public signer;

    //@notice usedNonce is an array value used for duplicate sign restriction.

    mapping(uint256 => bool) private usedNonce;


    /** Fee Struct
        @param platformFee  uint256 (buyerFee + sellerFee) value which is transferred to current contract owner.
        @param assetFee  uint256  assetvalue which is transferred to current seller of the NFT.
        @param royaltyFee  uint256 value, transferred to Minter of the NFT.
        @param price  uint256 value, the combination of buyerFee and assetValue.
        @param tokenCreator address value, it's store the creator of NFT.
     */
    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint96[] royaltyFee;
        uint256 price;
        address[] tokenCreator;
    }

    //@notice Sign struct stores the sign bytes
    //@param v it holds(129-130) from sign value length always 27/28.
    //@param r it holds(0-66) from sign value length.
    //@param s it holds(67-128) from sign value length.
    //@param nonce unique value.

    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }
    /** Order Params
        @param seller address of user,who's selling the NFT.
        @param buyer address of user, who's buying the NFT.
        @param erc20Address address of the token, which is used as payment token(WETH/WBNB/WMATIC...)
        @param nftAddress address of NFT contract where the NFT token is created/Minted.
        @param nftType an enum value, if the type is ERC721/ERC1155 the enum value is 0/1.
        @param uintprice the Price Each NFT it's not including the buyerFee.
        @param amout the price of NFT(assetFee + buyerFee).
        @param tokenId 
        @param qty number of quantity to be transfer.
     */
    struct Order {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        BuyingAssetType nftType;
        uint256 unitPrice;
        bool skipRoyalty;
        uint256 amount;
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        uint96[] royaltyFee;
        address[] receivers;
        uint256 qty;
    }


    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        ITransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        transferProxy = _transferProxy;
        owner = msg.sender;
        signer = msg.sender;
        _setupRole("ADMIN_ROLE", msg.sender);
        _setupRole("SIGNER_ROLE", msg.sender);
    }

    /**
        @notice buyerServiceFee returns the platform's buyerservice Fee
        returns the buyerservice Fee in multiply of 1000.
     */

    function buyerServiceFee() external view virtual returns (uint8) {
        return buyerFeePermille;
    }

    /**
        @notice sellerServiceFee returns the platform's sellerServiceFee Fee
        returns the sellerServiceFee Fee in multiply of 1000.
     */

    function sellerServiceFee() external view virtual returns (uint8) {
        return sellerFeePermille;
    }

    //@notice setBuyerServiceFee sets platform's buyerservice Fee.
    //@param _buyerFee  buyerserviceFee in multiply of 1000.
    /**
        restriction only the admin has role to set Fees.
     */

    function setBuyerServiceFee(uint8 _buyerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    //@notice setSellerServiceFee sets platform's ServiceFee Fee.
    //@param _buyerFee  ServiceFee in multiply of 1000.
    /**
        restriction only the admin has role to set Fees.
     */

    function setSellerServiceFee(uint8 _sellerFee)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    //@notice transferOwnership for transferring contract ownership to new owner address.
    //@param newOwner address of new owner.
    //@return bool value always true. 
    /** restriction: the ADMIN_ROLE address only has the permission to 
    transfer the contract ownership to new wallet address.*/
    //@dev see{Accesscontrol}.
    // emits {OwnershipTransferred} event.

    function transferOwnership(address newOwner)
        external
        onlyRole("ADMIN_ROLE")
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _revokeRole("ADMIN_ROLE", owner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _setupRole("ADMIN_ROLE", newOwner);
        return true;
    }

        //@notice transferSignerAddress for transferring contract oldSigner to new signer address.
        //@param newSigner address of new signer.
        //@return bool value always true. 
        /** restriction: the SIGNER_ROLE address only has the permission to 
        transfer the contract oldSigner to new wallet address.*/
        //@dev see{Accesscontrol}.
        // emits {SignerAddressTransferred} event.

    function transferSignerAddress(address newSigner)
        external
        onlyRole("SIGNER_ROLE")
        returns (bool)
    {
        require(
            newSigner != address(0),
            "Ownable: new signer is the zero address"
        );
        _revokeRole("SIGNER_ROLE", signer);
        emit SignerAddressTransferred(signer, newSigner);
        signer = newSigner;
        _setupRole("SIGNER_ROLE", newSigner);
        return true;
    }

        //@notice excuting the NFT buyAsset order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - seller sign should be valid
         */
        // returns the bool value always true.

    function buyAsset(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }

        //@notice excuting the NFT executeBid order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - buyer sign should be valid
         */
        // returns the bool value always true.

    function executeBid(Order calldata order, Sign calldata sign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

        //@notice excuting the NFT mintAndBuyAsset order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        //@param ownerSign {Sign}
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - seller sign should be valid
                - owner sign should be valid
         */
        // returns the bool value always true.

    function mintAndBuyAsset(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        require(
            (fee.price >= order.unitPrice * order.qty),
            "Paid invalid amount"
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            sign
        );
        address buyer = msg.sender;
        tradeAsset(order, fee, buyer, order.seller);
        emit BuyAsset(order.nftAddress, order.seller, order.tokenId, order.qty, msg.sender);
        return true;
    }
        //@notice excuting the NFT mintAndExecuteBid order.
        //@param order see {Order}.
        //@param sign see {Sign}.
        //@param ownerSign {Sign}
        /**
            restriction: 
                - Nonce should be unique.
                - Paid invalid amount.
                - buyer sign should be valid
                - owner sign should be valid
         */
        // returns the bool value always true.

    function mintAndExecuteBid(Order calldata order, Sign calldata sign, Sign calldata ownerSign)
        external
        returns (bool)
    {
        require(!usedNonce[sign.nonce], "Nonce : Invalid Nonce");
        usedNonce[sign.nonce] = true;
        Fee memory fee = getFees(
            order
        );
        verifyOwnerSign(
            order.seller,
            order.tokenURI,
            order.nftAddress,
            ownerSign
        );
        verifyBuyerSign(
            order.buyer,
            order.tokenId,
            order.amount,
            order.erc20Address,
            order.nftAddress,
            order.qty,
            sign
        );
        address seller = msg.sender;
        tradeAsset(order, fee, order.buyer, seller);
        emit ExecuteBid(order.nftAddress, msg.sender, order.tokenId, order.qty, order.buyer);
        return true;
    }

    //@notice function returns the signer address from signed hash.
    //@param hash generated from sign parameters.
    //@returns the signer of given signature.
    //@dev see {Sign}.


    function getSigner(bytes32 hash, Sign memory sign)
        internal
        pure
        returns (address)
    {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
                ),
                sign.v,
                sign.r,
                sign.s
            );
    }

    //@notice function verifies the singer address from the signed hash.
    //@param buyer address of the asset buyer.
    //@param tokenId unique id of NFT
    //@param amount sale price of asset
    //@param paymentAssetAddress address of payment token(WETH, WBNB, WMATIC,...)
    //@param assetAddress NFT contract address(ERC721, ERC1155)
    //@param qty no.of units to be tranfer.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- buyer sign verification failed when signture was mismatched.
     */

    function verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                sign.nonce
            )
        );
        require(
            seller == getSigner(hash, sign),
            "seller sign verification failed"
        );
    }
    //@notice function verifies the singer address from the signed hash.
    //@param _tokenURI IPFS metatdata URI.
    //@param caller address of the caller.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- owner sign verification failed when signture was mismatched.
     */
    function verifyOwnerSign(
        address seller,
        string memory tokenURI,
        address assetAddress,
        Sign memory sign
    ) internal view {
        bytes32 hash = keccak256(
            abi.encodePacked(
                this,
                assetAddress,
                seller,
                tokenURI,
                sign.nonce
            )
        );
        require(
            signer == getSigner(hash, sign),
            "owner sign verification failed"
        );
    }

    //@notice function verifies the singer address from the signed hash.
    //@param buyer address of the asset buyer.
    //@param tokenId unique id of NFT
    //@param amount sale price of asset
    //@param paymentAssetAddress address of payment token(WETH, WBNB, WMATIC,...)
    //@param assetAddress NFT contract address(ERC721, ERC1155)
    //@param qty no.of units to be tranfer.
    //@param sign @dev see{Sign}.
    /**
        * Requirements- buyer sign verification failed when signture was mismatched.
     */

    function verifyBuyerSign(
        address buyer,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 qty,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                qty,
                sign.nonce
            )
        );
        require(
            buyer == getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    //@notice the function calculates platform Fee, assetFee, royaltyFee from the NFT token SalePrice.
    //@param see order {Order}
    //retuns platformFee, assetFee, royaltyFee, price and tokencreator.

    function getFees(
        Order calldata order
    ) internal view returns (Fee memory) {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royalty;
        uint96[] memory _royaltyFee;
        address[] memory _tokenCreator;
        uint256 price = (order.amount * 1000) / (1000 + buyerFeePermille);
        uint256 buyerFee = order.amount - price;
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        platformFee = buyerFee + sellerFee;
        if(!order.skipRoyalty &&((order.nftType == BuyingAssetType.ERC721) || (order.nftType == BuyingAssetType.ERC1155))) {
            (_royaltyFee, _tokenCreator, royalty) = IRoyaltyInfo(order.nftAddress)
                    .royaltyInfo(order.tokenId, price);        }
        if(!order.skipRoyalty &&((order.nftType == BuyingAssetType.LazyERC721) || (order.nftType == BuyingAssetType.LazyERC1155))) {
                _royaltyFee = new uint96[](order.royaltyFee.length);
                _tokenCreator = new address[](order.receivers.length);
                for( uint256 i =0; i< order.receivers.length; i++) {
                    royalty += uint96(price * order.royaltyFee[i] / 1000) ;
                    (_tokenCreator[i], _royaltyFee[i]) = (order.receivers[i], uint96(price * order.royaltyFee[i] / 1000));
                }     
        }
        assetFee = price - royalty - sellerFee;
        return Fee(platformFee, assetFee, _royaltyFee, price, _tokenCreator);
    }

    /** 
        @notice transfer and Mint the NFTs(ERC721, ERC1155) and tokens through the transferproxy.
        @param order @dev see {Order}.
        @param fee @dev see {Fee}.
        @param buyer asset buuyer.

    */

    function tradeAsset(
        Order calldata order,
        Fee memory fee,
        address buyer,
        address seller
    ) internal virtual {
        if (order.nftType == BuyingAssetType.ERC721) {
            transferProxy.erc721safeTransferFrom(
                IERC721(order.nftAddress),
                seller,
                buyer,
                order.tokenId
            );
        }

        if (order.nftType == BuyingAssetType.ERC1155) {
            transferProxy.erc1155safeTransferFrom(
                IERC1155(order.nftAddress),
                seller,
                buyer,
                order.tokenId,
                order.qty,
                ""
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC721) {
            transferProxy.mintAndSafe721Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers
            );
        }

        if (order.nftType == BuyingAssetType.LazyERC1155) {
            transferProxy.mintAndSafe1155Transfer(
                ILazyMint(order.nftAddress),
                seller,
                buyer,
                order.tokenURI,
                order.royaltyFee,
                order.receivers,
                order.supply,
                order.qty
            );
        }

        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(order.erc20Address),
                buyer,
                owner,
                fee.platformFee
            );
        }

        for(uint96 i = 0; i < fee.tokenCreator.length; i++) {
            if (fee.royaltyFee[i] > 0 && (!order.skipRoyalty)) {
                transferProxy.erc20safeTransferFrom(
                    IERC20(order.erc20Address),
                    buyer,
                    fee.tokenCreator[i],
                    fee.royaltyFee[i]
                );
            }
        }

        transferProxy.erc20safeTransferFrom(
            IERC20(order.erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }
}