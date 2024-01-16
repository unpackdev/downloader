// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

import "./TransferProxy.sol";

contract TradeV2 {
    enum BuyingAssetType {
        ERC1155,
        ERC721
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SellerFee(uint8 sellerFee);
    event BuyerFee(uint8 buyerFee);
    event BuyAsset721(
        address indexed assetOwner,
        uint256 indexed tokenId,
        address indexed buyer,
        Fee fee
    );
    event BuyAsset1155(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer,
        Fee fee
    );
    event ExecuteBid721(
        address indexed assetOwner,
        uint256 indexed tokenId,
        address indexed buyer,
        Fee fee
    );
    event ExecuteBid1155(
        address indexed assetOwner,
        uint256 indexed tokenId,
        uint256 quantity,
        address indexed buyer,
        Fee fee
    );

    uint8 public buyerFeePermille; // buyer's fee, above the lot price
    uint8 public sellerFeePermille; // fee from the seller, deducted from the price of the lot
    TransferProxy public transferProxy;
    address public owner;
    address public beneficiary; // Wallet address to receive fee
    mapping(uint256 => bool) public usedNonce;

    struct Fee {
        uint256 platformFee;
        uint256 assetFee;
        uint256 royaltyFee;
        uint256 price;
        address tokenCreator;
    }

    /* An ECDSA signature. */
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Order721 {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 nonce;
    }

    struct Order1155 {
        address seller;
        address buyer;
        address erc20Address;
        address nftAddress;
        uint256 unitPrice;
        uint256 amount;
        uint256 tokenId;
        uint256 qty;
        uint256 nonce;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier checkNonce(uint256 nonce) {
        require(usedNonce[nonce] == false, "Used nonce");
        usedNonce[nonce] = true;
        _;
    }

    constructor(
        uint8 _buyerFee,
        uint8 _sellerFee,
        address _beneficiary,
        TransferProxy _transferProxy
    ) {
        buyerFeePermille = _buyerFee;
        sellerFeePermille = _sellerFee;
        beneficiary = _beneficiary;
        transferProxy = _transferProxy;
        owner = msg.sender;
    }

    function setBuyerServiceFee(uint8 _buyerFee)
        public
        onlyOwner
        returns (bool)
    {
        buyerFeePermille = _buyerFee;
        emit BuyerFee(buyerFeePermille);
        return true;
    }

    function setSellerServiceFee(uint8 _sellerFee)
        public
        onlyOwner
        returns (bool)
    {
        sellerFeePermille = _sellerFee;
        emit SellerFee(sellerFeePermille);
        return true;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
        returns (bool)
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function buyAsset721(Order721 memory order, Sign memory sign)
        public
        payable
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            msg.value,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC721
        );
        require((msg.value >= order.unitPrice), "Paid invalid value");
        _verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.nonce,
            sign
        );
        order.buyer = msg.sender;
        _tradeAsset721(order, fee);
        emit BuyAsset721(order.seller, order.tokenId, msg.sender, fee);
        return true;
    }

    function buyAsset1155(Order1155 memory order, Sign memory sign)
        public
        payable
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            msg.value,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC1155
        );
        require(
            (msg.value >= order.unitPrice * order.qty),
            "Paid invalid value"
        );
        _verifySellerSign(
            order.seller,
            order.tokenId,
            order.unitPrice,
            order.erc20Address,
            order.nftAddress,
            order.nonce,
            sign
        );
        order.buyer = msg.sender;
        _tradeAsset1155(order, fee);
        emit BuyAsset1155(
            order.seller,
            order.tokenId,
            order.qty,
            msg.sender,
            fee
        );
        return true;
    }

    function executeBid721(Order721 memory order, Sign memory sign)
        public
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            order.amount,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC721
        );
        _verifyBuyerSign721(order, sign);
        order.seller = msg.sender;
        _tradeBid721(order, fee);
        emit ExecuteBid721(msg.sender, order.tokenId, order.buyer, fee);
        return true;
    }

    function executeBid1155(Order1155 memory order, Sign memory sign)
        public
        checkNonce(order.nonce)
        returns (bool)
    {
        Fee memory fee = _getFees(
            order.amount,
            order.nftAddress,
            order.tokenId,
            BuyingAssetType.ERC1155
        );
        _verifyBuyerSign1155(order, sign);
        order.seller = msg.sender;
        _tradeBid1155(order, fee);
        emit ExecuteBid1155(
            msg.sender,
            order.tokenId,
            order.qty,
            order.buyer,
            fee
        );
        return true;
    }

    function _getFees(
        uint256 paymentAmt,
        address buyingAssetAddress,
        uint256 tokenId,
        BuyingAssetType buyingAssetType
    ) internal view returns (Fee memory) {
        address tokenCreator;
        uint256 platformFee;
        uint256 royaltyFee;
        uint256 assetFee;
        uint256 royaltyPermille;
        uint256 buyerFee = (paymentAmt / (1000 + buyerFeePermille)) *
            buyerFeePermille;
        // platform fee from the buyer
        uint256 price = paymentAmt - buyerFee;
        // real price of the lot
        uint256 sellerFee = (price * sellerFeePermille) / 1000;
        // platform fee from the buyer
        platformFee = buyerFee + sellerFee;
        if (buyingAssetType == BuyingAssetType.ERC721) {
            royaltyPermille = (
                (IERC721(buyingAssetAddress).royaltyFee(tokenId))
            );
            tokenCreator = ((IERC721(buyingAssetAddress).getCreator(tokenId)));
        }
        if (buyingAssetType == BuyingAssetType.ERC1155) {
            royaltyPermille = (
                (IERC1155(buyingAssetAddress).royaltyFee(tokenId))
            );
            tokenCreator = ((IERC1155(buyingAssetAddress).getCreator(tokenId)));
        }
        royaltyFee = (price * royaltyPermille) / 1000;
        // token creator fee
        assetFee = price - royaltyFee - sellerFee;
        return Fee(platformFee, assetFee, royaltyFee, price, tokenCreator);
    }

    function _tradeBid721(Order721 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc721safeTransferFrom(
            IERC721(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId
        );
        _tradeBidFee(order.erc20Address, order.buyer, order.seller, fee);
    }

    function _tradeBid1155(Order1155 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc1155safeTransferFrom(
            IERC1155(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId,
            order.qty,
            ""
        );
        _tradeBidFee(order.erc20Address, order.buyer, order.seller, fee);
    }

    function _tradeBidFee(
        address erc20Address,
        address buyer,
        address seller,
        Fee memory fee
    ) internal {
        if (fee.platformFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(erc20Address),
                buyer,
                beneficiary,
                fee.platformFee
            );
        }
        if (fee.royaltyFee > 0) {
            transferProxy.erc20safeTransferFrom(
                IERC20(erc20Address),
                buyer,
                fee.tokenCreator,
                fee.royaltyFee
            );
        }
        transferProxy.erc20safeTransferFrom(
            IERC20(erc20Address),
            buyer,
            seller,
            fee.assetFee
        );
    }

    function _tradeAsset721(Order721 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc721safeTransferFrom(
            IERC721(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId
        );
        _tradeAssetFee(order.seller, fee);
    }

    function _tradeAsset1155(Order1155 memory order, Fee memory fee)
        internal
        virtual
    {
        transferProxy.erc1155safeTransferFrom(
            IERC1155(order.nftAddress),
            order.seller,
            order.buyer,
            order.tokenId,
            order.qty,
            ""
        );
        _tradeAssetFee(order.seller, fee);
    }

    function _tradeAssetFee(address seller, Fee memory fee) internal {
        if (fee.platformFee > 0) {
            require(payable(beneficiary).send(fee.platformFee));
        }
        if (fee.royaltyFee > 0) {
            require(payable(fee.tokenCreator).send(fee.royaltyFee));
        }
        require(payable(seller).send(fee.assetFee));
    }

    function _getSigner(bytes32 hash, Sign memory sign)
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

    function _verifySellerSign(
        address seller,
        uint256 tokenId,
        uint256 amount,
        address paymentAssetAddress,
        address assetAddress,
        uint256 nonce,
        Sign memory sign
    ) internal pure {
        bytes32 hash = keccak256(
            abi.encodePacked(
                assetAddress,
                tokenId,
                paymentAssetAddress,
                amount,
                nonce
            )
        );
        require(
            seller == _getSigner(hash, sign),
            "seller sign verification failed"
        );
    }

    function _verifyBuyerSign721(Order721 memory order, Sign memory sign)
        internal
        pure
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                order.nftAddress,
                order.tokenId,
                order.erc20Address,
                order.amount,
                order.nonce
            )
        );
        require(
            order.buyer == _getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }

    function _verifyBuyerSign1155(Order1155 memory order, Sign memory sign)
        internal
        pure
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                order.nftAddress,
                order.tokenId,
                order.erc20Address,
                order.amount,
                order.qty,
                order.nonce
            )
        );
        require(
            order.buyer == _getSigner(hash, sign),
            "buyer sign verification failed"
        );
    }
}
