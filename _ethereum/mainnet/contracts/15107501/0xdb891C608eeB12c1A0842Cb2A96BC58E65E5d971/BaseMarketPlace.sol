// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./SignatureHash.sol";

abstract contract BaseMarketPlace is Context, Ownable, SignatureHash {
    using Address for address;
    using SafeMath for uint256;

    // Market address
    address payable internal _marketAddress;

    struct Order {
        // Order ID
        bytes32 id;

        // Owner of the NFT
        address seller;
        
        // NFT registry address
        address nftAddress;

        // Price (in wei) for the published item
        uint256 priceAsset;

        // ExpireAt (UTC timestamp)
        uint256 expireAt;
    }

    // From ERC721 registry assetId to Order (to avoid asset collision)
    mapping(address => mapping(uint256 => mapping(address => Order))) public orderByAssetId;

    // EVENTS
    event OrderCreated(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress,
        uint256 priceAsset,
        uint256 expireAt
    );
    event OrderSuccessful(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress,
        uint256 totalPrice,
        address indexed buyer
    );
    event OrderCancelled(
        bytes32 id,
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress
    );

    constructor(address market, address admin) SignatureHash(admin) {
        _marketAddress = payable(
            address(market)
        );
    }

    /**
     * @dev Verify required ERC721 address
     * @param nftAddress - ERC721 address
     */
    function _requireIERC721(address nftAddress) internal view {
        require(
            nftAddress.isContract(),
            "The NFT Address should be a contract"
        );
        bytes4 TypeIERC721 = type(IERC721).interfaceId;

        IERC721 nftRegistry = IERC721(nftAddress);
        require(
            nftRegistry.supportsInterface(TypeIERC721),
            "The NFT contract has an invalid ERC721 implementation"
        );
    }

    /**
     * @dev Make market fee
     * @param amount - to Calculate market fee
     */
    function _marketFee(uint256 amount) internal pure returns (uint256) {
        //1.5% fee
        uint256 toOwner = SafeMath.mul(amount, 15);
        return SafeMath.div(toOwner, 1000);
    }

    /**
     * @dev Creates a new order
     * @param nftAddress - Non fungible registry address
     * @param assetId - ID of the published NFT
     * @param priceAsset - Price in Wei for the supported coin
     */
    function _createOrder(
        address nftAddress,
        uint256 assetId,
        uint256 priceAsset,
        uint256 expireAt
    ) internal {
        // Require NFT address = ERC721
        _requireIERC721(nftAddress);

        // Datetime now
        uint256 datetime = block.timestamp;

        // Set nftRegistry
        IERC721 nftRegistry = IERC721(nftAddress);

        address assetOwner = nftRegistry.ownerOf(assetId);
        address sender = _msgSender();

        require(expireAt == 0 || expireAt > datetime, "Expire time is not valid");
        require(sender == assetOwner, "Only the owner can create orders");
        require(
            nftRegistry.getApproved(assetId) == address(this) ||
                nftRegistry.isApprovedForAll(assetOwner, address(this)),
            "The contract is not authorized to manage the asset"
        );
        require(priceAsset > 0, "Price should be bigger than 0");

        Order memory order = orderByAssetId[nftAddress][assetId][sender];
        // Delete the older one
        if (order.id != 0) {
            delete order;
        }

        // Hash unique orderId
        bytes32 orderId =
            keccak256(
                abi.encodePacked(
                    datetime,
                    assetOwner,
                    assetId,
                    nftAddress,
                    priceAsset,
                    expireAt
                )
            );

        // Set order Asset Id
        orderByAssetId[nftAddress][assetId][assetOwner] = Order({
            id: orderId,
            seller: assetOwner,
            nftAddress: nftAddress,
            priceAsset: priceAsset,
            expireAt: expireAt  // expireAt UTC timestamp
        });

        // Fire event succeed
        emit OrderCreated(orderId, assetId, assetOwner, nftAddress, priceAsset, expireAt);
    }

    /**
     * @dev Cancel an already published order
     *  can only be canceled by seller or the contract owner
     * @param nftAddress - Address of the NFT registry
     * @param assetId - ID of the published NFT
     */
    function _cancelOrder(address nftAddress, uint256 assetId) internal {
        address sender = _msgSender();
        Order memory order = orderByAssetId[nftAddress][assetId][sender];

        require(order.id != 0, "Asset order not created");
        require(
            order.seller == sender || sender == owner(),
            "Unauthorized user"
        );

        bytes32 orderId = order.id;
        address orderSeller = order.seller;
        address orderNftAddress = order.nftAddress;
        
        // Delete asset Order
        delete orderByAssetId[nftAddress][assetId][sender];

        emit OrderCancelled(orderId, assetId, orderSeller, orderNftAddress);
    }
}
