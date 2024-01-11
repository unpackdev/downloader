// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./SafeERC20.sol";
import "./ILegitArtERC721.sol";
import "./AuthenticatedProxy.sol";

/// @title LegitArt Marketplace
abstract contract MarketPlaceCore is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum OrderStatus {
        PLACED,
        CANCELED,
        EXECUTED
    }

    struct Order {
        address nftContract;
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 createdAt;
        OrderStatus status;
    }

    mapping(bytes32 => Order) public orders;
    IERC20 public immutable usdc;
    ILegitArtERC721 public legitArtNFT;
    address public feeBeneficiary;
    uint256 public primaryFeePercentage; // Use 1e18 for 100%
    uint256 public secondaryFeePercentage; // Use 1e18 for 100%

    event OrderPlaced(
        bytes32 indexed orderId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event OrderExecuted(
        bytes32 indexed orderId,
        address buyer,
        uint256 feeToProtocol,
        uint256 feeToCreator,
        uint256 feeToGallerist
    );
    event OrderCanceled(bytes32 indexed orderId);
    event OrderUpdated(bytes32 indexed orderId, uint256 newPrice);
    event FeeBeneficiaryUpdated(address indexed oldFeeBeneficiary, address indexed newFeeBeneficiary);
    event PrimaryFeePercentageUpdated(uint256 oldPrimaryFeePercentage, uint256 newPrimaryFeePercentage);
    event SecondaryFeePercentageUpdated(uint256 oldSecondaryFeePercentage, uint256 newSecondaryFeePercentage);

    constructor(
        IERC20 _usdc,
        ILegitArtERC721 _legitArtNFT,
        address _feeBeneficiary,
        uint256 _primaryFeePercentage,
        uint256 _secondaryFeePercentage
    ) {
        usdc = _usdc;
        legitArtNFT = _legitArtNFT;
        feeBeneficiary = _feeBeneficiary;
        primaryFeePercentage = _primaryFeePercentage;
        secondaryFeePercentage = _secondaryFeePercentage;
    }

    /// @notice Store a new order
    function _storeOrder(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _createdAt,
        address _seller,
        address _buyer,
        OrderStatus _status
    ) internal returns (bytes32 orderId) {
        orderId = _getOrderIdFromFields(_nftContract, _tokenId, _price, _createdAt, _seller);

        require(!_orderExists(orderId), "Order stored already");

        Order memory order = Order({
            nftContract: _nftContract,
            tokenId: _tokenId,
            seller: _seller,
            buyer: _buyer,
            price: _price,
            createdAt: _createdAt,
            status: _status
        });

        orders[orderId] = order;
    }

    function _bytesToAddress(bytes memory _bytes) private pure returns (address _address) {
        assembly {
            _address := mload(add(_bytes, 32))
        }
    }

    /// @notice Place an item for sale on the marketplace
    function _placeOrder(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        address _seller
    ) internal returns (bytes32 orderId) {
        require(_nftContract != address(0), "NFT contract can not be null");

        orderId = _storeOrder(
            _nftContract,
            _tokenId,
            _price,
            block.timestamp,
            _seller,
            address(0), // buyer
            OrderStatus.PLACED
        );

        // Transfer user's NFT by calling his proxy
        bytes memory call = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            _seller,
            address(this),
            _tokenId
        );
        _getProxyFromMsgSender().proxy(_nftContract, AuthenticatedProxy.HowToCall.Call, call);

        emit OrderPlaced(orderId, _nftContract, _tokenId, _seller, _price);
    }

    function _getProxyFromMsgSender() internal view returns (AuthenticatedProxy) {
        require(Address.isContract(_msgSender()), "The caller is not a proxy");
        return AuthenticatedProxy(_msgSender());
    }

    function _getUserFromMsgSender() internal view returns (address) {
        return _getProxyFromMsgSender().user();
    }

    /// @notice Place an item for sale on the marketplace
    function placeOrder(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price
    ) external nonReentrant returns (bytes32 orderId) {
        address seller = _getUserFromMsgSender();
        orderId = _placeOrder(_nftContract, _tokenId, _price, seller);
    }

    /// @notice Check if an order exists
    function _orderExists(bytes32 _orderId) internal view returns (bool) {
        return orders[_orderId].nftContract != address(0);
    }

    /// @notice Payment processor for secondary market
    function _processOrderPayment(Order memory order, address _payer)
        internal
        virtual
        returns (
            uint256 _toProtocol,
            uint256 _toCreator,
            uint256 _toGallerist,
            uint256 _toSeller
        )
    {
        _toProtocol = (order.price * secondaryFeePercentage) / 1e18;
        if (_toProtocol > 0) {
            usdc.safeTransferFrom(_payer, feeBeneficiary, _toProtocol);
        }

        (address _creator, uint256 _royaltyFee, address _gallerist, uint256 _galleristFee) = legitArtNFT.getFeeInfo(
            order.tokenId
        );

        uint256 _royalty = (order.price * _royaltyFee) / 1e18;

        if (_royalty > 0) {
            _toGallerist = (_royalty * _galleristFee) / 1e18;
            if (_toGallerist > 0) {
                usdc.safeTransferFrom(_payer, _gallerist, _toGallerist);
            }

            _toCreator = _royalty - _toGallerist;
            usdc.safeTransferFrom(_payer, _creator, _toCreator);
        }

        _toSeller = order.price - _toProtocol - _royalty;
        usdc.safeTransferFrom(_payer, order.seller, _toSeller);
    }

    /// @notice Execute a placed order
    function _executeOrder(
        bytes32 _orderId,
        address _buyer,
        address _payer
    ) private {
        require(_orderExists(_orderId), "Order does not exist");

        Order storage order = orders[_orderId];

        require(order.status == OrderStatus.PLACED, "Order status is not valid");

        order.buyer = _buyer;
        order.status = OrderStatus.EXECUTED;

        (uint256 _toProtocol, uint256 _toCreator, uint256 _toGallerist, ) = _processOrderPayment(order, _payer);

        IERC721(order.nftContract).transferFrom(address(this), _buyer, order.tokenId);

        emit OrderExecuted(_orderId, _buyer, _toProtocol, _toCreator, _toGallerist);
    }

    /// @notice Execute a placed order
    function executeOrderOnBehalf(bytes32 _orderId, address _buyer) external nonReentrant {
        address _payer = _msgSender();
        _executeOrder(_orderId, _buyer, _payer);
    }

    /// @notice Execute a placed order
    function executeOrder(bytes32 _orderId) external nonReentrant {
        address _buyerAndPayer = _getUserFromMsgSender();
        _executeOrder(_orderId, _buyerAndPayer, _buyerAndPayer);
    }

    /// @notice Cancel a placed order
    function cancelOrder(bytes32 _orderId) external nonReentrant {
        require(_orderExists(_orderId), "Order does not exist");

        Order storage order = orders[_orderId];

        require(_getUserFromMsgSender() == order.seller, "Only seller can cancel an order");
        require(order.status == OrderStatus.PLACED, "Order status is not valid");

        order.status = OrderStatus.CANCELED;

        IERC721(order.nftContract).transferFrom(address(this), order.seller, order.tokenId);

        emit OrderCanceled(_orderId);
    }

    function updateOrder(bytes32 _orderId, uint256 _newPrice) external nonReentrant {
        require(_orderExists(_orderId), "Order does not exist");

        Order storage order = orders[_orderId];

        require(_getUserFromMsgSender() == order.seller, "Only seller can update an order");
        require(order.status == OrderStatus.PLACED, "Order status is not valid");

        order.price = _newPrice;

        emit OrderUpdated(_orderId, _newPrice);
    }

    /// @notice Generate orderId for a given order by hashing the key params
    function _getOrderIdFromFields(
        address _nftContract,
        uint256 _tokenId,
        uint256 _price,
        uint256 _createdAt,
        address _seller
    ) internal pure returns (bytes32 orderId) {
        orderId = keccak256(abi.encode(_nftContract, _tokenId, _price, _createdAt, _seller));
    }

    function updateFeeBeneficiary(address _newFeeBenenficiary) public onlyOwner {
        require(_newFeeBenenficiary != address(0), "Beneficiary is invalid");
        require(_newFeeBenenficiary != feeBeneficiary, "Beneficiary is the same as current");
        emit FeeBeneficiaryUpdated(feeBeneficiary, _newFeeBenenficiary);
        feeBeneficiary = _newFeeBenenficiary;
    }

    function updatePrimaryFeePercentage(uint256 _newPrimaryFeePercentage) public onlyOwner {
        require(_newPrimaryFeePercentage <= 1e18, "Fee is greater than 100%");
        require(_newPrimaryFeePercentage != primaryFeePercentage, "Fee is the same as current");
        emit PrimaryFeePercentageUpdated(primaryFeePercentage, _newPrimaryFeePercentage);
        primaryFeePercentage = _newPrimaryFeePercentage;
    }

    function updateSecondaryFeePercentage(uint256 _newSecondaryFeePercentage) public onlyOwner {
        require(_newSecondaryFeePercentage <= 1e18, "Fee is greater than 100%");
        require(_newSecondaryFeePercentage != secondaryFeePercentage, "Fee is the same as current");
        emit SecondaryFeePercentageUpdated(secondaryFeePercentage, _newSecondaryFeePercentage);
        secondaryFeePercentage = _newSecondaryFeePercentage;
    }
}
