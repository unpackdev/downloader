// SPDX-License-Identifier: MIT



pragma solidity 0.8.4;

import "./Context.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./draft-EIP712.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./MarketPlaceCore.sol";
import "./ILegitArtERC721.sol";

/// @title LegitArt Marketplace
contract MarketPlace is MarketPlaceCore, EIP712 {
    using SafeERC20 for IERC20;

    /// @notice Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function.
    struct NFTVoucher {
        /// @notice The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the redeem function will revert.
        uint256 tokenId;
        /// @notice The price (in wei) that the NFT creator is willing to accept for the initial sale of this NFT.
        uint256 price;
        /// @notice The metadata URI to associate with this token.
        string uri;
        /// @notice The royalty fee
        uint256 royaltyFee;
        /// @notice The gallerist wallet
        address gallerist;
        /// @notice The gallerist fee
        uint256 galleristFee;
        /// @notice The sign timestamp (used for nonce purpose)
        uint256 createdAt;
        /// @notice The EIP-712 signature of all other fields in the NFTVoucher struct. For a voucher to be valid, it must be signed by an account with the MINTER_ROLE.
        bytes signature;
    }

    string private constant SIGNING_DOMAIN = "LegitArtERC721";
    string private constant SIGNATURE_VERSION = "1";

    constructor(
        IERC20 _usdc,
        ILegitArtERC721 _legitArtNFT,
        address _feeBeneficiary,
        uint256 _primaryFeePercentage,
        uint256 _secondaryFeePercentage
    )
        MarketPlaceCore(_usdc, _legitArtNFT, _feeBeneficiary, _primaryFeePercentage, _secondaryFeePercentage)
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION)
    {}

    /// @notice Payment processor for primary market
    function _processOrderPayment(Order memory order, address payer)
        internal
        override
        returns (
            uint256 _toProtocol,
            uint256 _toCreator,
            uint256 _toGallerist,
            uint256 _toSeller
        )
    {
        _toCreator = 0; // On primary market, the seller is the creator

        _toProtocol = (order.price * primaryFeePercentage) / 1e18;
        if (_toProtocol > 0) {
            usdc.safeTransferFrom(payer, feeBeneficiary, _toProtocol);
        }

        (, , address _gallerist, uint256 _galleristFee) = legitArtNFT.getFeeInfo(order.tokenId);
        uint256 _priceAfterFee = order.price - _toProtocol;

        _toGallerist = (_priceAfterFee * _galleristFee) / 1e18;
        if (_toGallerist > 0) {
            usdc.safeTransferFrom(payer, _gallerist, _toGallerist);
        }

        _toSeller = _priceAfterFee - _toGallerist;
        usdc.safeTransferFrom(payer, order.seller, _toSeller);
    }

    function _storeOrder(NFTVoucher calldata _voucher, address _buyer) private returns (bytes32 orderId) {
        address seller = _verify(_voucher);

        address nftContract = address(legitArtNFT);

        orderId = _getOrderIdFromFields(nftContract, _voucher.tokenId, _voucher.price, _voucher.createdAt, seller);

        require(!_orderExists(orderId), "Is not possible to execute a stored order");

        _storeOrder(
            nftContract,
            _voucher.tokenId,
            _voucher.price,
            _voucher.createdAt,
            seller,
            _buyer,
            OrderStatus.EXECUTED
        );

        emit OrderPlaced(orderId, nftContract, _voucher.tokenId, seller, _voucher.price);
    }

    function executeLazyOnBehalf(NFTVoucher calldata _voucher, address buyer) external nonReentrant {
        address payer = _msgSender();
        _executeLazy(_voucher, buyer, payer);
    }

    function executeLazy(NFTVoucher calldata _voucher) external nonReentrant {
        address buyerAndPayer = _getUserFromMsgSender();
        _executeLazy(_voucher, buyerAndPayer, buyerAndPayer);
    }

    /// @notice Order execution by supporting lazy-minting
    /// @dev A voucher signed by the seller is used to mint the NFT, place and execute an order
    /// in the same call
    function _executeLazy(
        NFTVoucher calldata _voucher,
        address buyer,
        address payer
    ) private {
        bytes32 orderId = _storeOrder(_voucher, buyer);

        Order memory order = orders[orderId];

        legitArtNFT.mintTo(
            order.seller,
            _voucher.royaltyFee,
            _voucher.gallerist,
            _voucher.galleristFee,
            buyer,
            _voucher.tokenId,
            _voucher.uri
        );

        (uint256 _toProtocol, uint256 _toCreator, uint256 _toGallerist, ) = _processOrderPayment(order, payer);

        emit OrderExecuted(orderId, buyer, _toProtocol, _toCreator, _toGallerist);
    }

    /// @notice Cancel an lazy-minting order
    function cancelLazy(NFTVoucher calldata _voucher) external {
        address seller = _verify(_voucher);
        require(_getUserFromMsgSender() == seller, "Only seller can cancel an order");

        address nftContract = address(legitArtNFT);

        bytes32 orderId = _getOrderIdFromFields(
            nftContract,
            _voucher.tokenId,
            _voucher.price,
            _voucher.createdAt,
            seller
        );

        require(!_orderExists(orderId), "Is not possible to cancel a stored order");

        _storeOrder(
            nftContract,
            _voucher.tokenId,
            _voucher.price,
            _voucher.createdAt,
            seller,
            address(0), // buyer
            OrderStatus.CANCELED
        );

        emit OrderPlaced(orderId, nftContract, _voucher.tokenId, seller, _voucher.price);
        emit OrderCanceled(orderId);
    }

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    function _hash(NFTVoucher calldata _voucher) internal view returns (bytes32) {
        // @todo - ALEXANDRE - suggested adding _voucher.signature
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "NFTVoucher(uint256 tokenId,uint256 price,string uri,uint256 royaltyFee,address gallerist,uint256 galleristFee,uint256 createdAt)"
                    ),
                    _voucher.tokenId,
                    _voucher.price,
                    keccak256(bytes(_voucher.uri)),
                    _voucher.royaltyFee,
                    _voucher.gallerist,
                    _voucher.galleristFee,
                    _voucher.createdAt
                )
            );
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    function _verify(NFTVoucher calldata _voucher) internal view returns (address signer) {
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            _domainSeparatorV4(),
            _hash(_voucher)
        ));
        signer = ECDSA.recover(digest, _voucher.signature);
    }
}
