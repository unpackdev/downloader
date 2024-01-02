// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC2981.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";

contract Web3BasicNftMarketplaceV2 is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address payable;
    using SafeMath for uint256;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    event SaleCreated(
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 startingTime,
        uint256 endTime
    );

    event SaleUpdated(
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    );

    event SaleCancelled(
        address indexed seller,
        address indexed collection,
        uint256 tokenId
    );

    event SaleMade(
        address indexed buyer,
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 totalPrice
    );

    event MarketplaceFeeUpdated(
        address marketplaceFeeReceiver,
        uint256 marketplaceFee
    );

    /// @notice struct for a basic sale
    struct Sale {
        uint256 amount;
        uint256 price;
        uint256 startingTime;
        uint256 endTime;
    }

    /// @notice collection => tokenId => seller => sale
    mapping(address => mapping(uint256 => mapping(address => Sale)))
        public sales;

    /// @notice Web3 Platform: Marketplace Fee receiver
    address payable public marketplaceFeeReceiver;

    /// @notice Web3 Platform: Marketplace Fee in basic points
    uint256 public marketplaceFee;

    modifier notOnSale(
        address _collection,
        uint256 _tokenId,
        address _seller
    ) {
        _checkNotOnSale(_collection, _tokenId, _seller);
        _;
    }

    modifier onSale(
        address _collection,
        uint256 _tokenId,
        address _seller
    ) {
        Sale memory sale = sales[_collection][_tokenId][_seller];
        require(sale.amount > 0, "token is already sold out");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice initialize the contract and its upgrade
    function initialize(
        address payable _marketplaceFeeReceiver,
        uint256 _marketplaceFee
    ) public initializer {
        marketplaceFeeReceiver = _marketplaceFeeReceiver;
        marketplaceFee = _marketplaceFee;
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
    }

    /// @notice method for updating the marketplace fee receiver
    /// @dev only owner can call this method
    /// @param _marketplaceFeeReceiver address of the new marketplace fee receiver
    function updatePlatformFeeReceiver(
        address payable _marketplaceFeeReceiver
    ) external onlyOwner {
        marketplaceFeeReceiver = _marketplaceFeeReceiver;
        emit MarketplaceFeeUpdated(marketplaceFeeReceiver, marketplaceFee);
    }

    /// @notice method for updating the marketplace fee
    /// @dev only owner can call this method
    /// @param _marketplaceFee new marketplace fee in basic points
    function updatePlatformFee(uint256 _marketplaceFee) external onlyOwner {
        marketplaceFee = _marketplaceFee;
        emit MarketplaceFeeUpdated(marketplaceFeeReceiver, marketplaceFee);
    }

    /// @notice method for creating a basic sale
    /// @param _contract address of the collection
    /// @param _tokenId tokenId to be sold
    /// @param _amount amount to be put on sale (must be 1 for 721)
    /// @param _price price per item
    /// @param _startingTime starting time of the sale (0 for immediate)
    /// @param _endTime end time of the sale (0 for no end time)
    function createSale(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _startingTime,
        uint256 _endTime
    ) external nonReentrant notOnSale(_contract, _tokenId, _msgSender()) {
        _createSale(
            _contract,
            _tokenId,
            _amount,
            _price,
            _startingTime,
            _endTime,
            _msgSender()
        );
    }

    /// @notice method for creating basic sales
    /// @param _contract address of the collection
    /// @param _tokenIds tokenIds to be sold
    /// @param _amounts amount to be put on sales (must be 1 for 721)
    /// @param _prices prices per item per sale
    /// @param _startingTimes starting times of the sales (0 for immediate)
    /// @param _endTimes end times of the sales (0 for no end time)
    function createSaleBatch(
        address _contract,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256[] memory _prices,
        uint256[] memory _startingTimes,
        uint256[] memory _endTimes
    ) external nonReentrant {
        require(_tokenIds.length == _amounts.length, "invalid input length");
        require(_tokenIds.length == _prices.length, "invalid input length");
        require(
            _tokenIds.length == _startingTimes.length,
            "invalid input length"
        );
        require(_tokenIds.length == _endTimes.length, "invalid input length");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _checkNotOnSale(_contract, _tokenIds[i], _msgSender());
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createSale(
                _contract,
                _tokenIds[i],
                _amounts[i],
                _prices[i],
                _startingTimes[i],
                _endTimes[i],
                _msgSender()
            );
        }
    }

    /// @notice method for creating a basic sale from an operator
    /// @param _contract address of the collection
    /// @param _tokenId tokenId to be sold
    /// @param _amount amount to be put on sale (must be 1 for 721)
    /// @param _price price per item
    /// @param _startingTime starting time of the sale (0 for immediate)
    /// @param _endTime end time of the sale (0 for no end time)
    /// @param _owner owner of the token to be put on sale (must be operated by the caller)
    function createSaleDelegate(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _startingTime,
        uint256 _endTime,
        address _owner
    ) external nonReentrant notOnSale(_contract, _tokenId, _owner) {
        _checkTokenOperator(_contract, _owner, _msgSender());
        _createSale(
            _contract,
            _tokenId,
            _amount,
            _price,
            _startingTime,
            _endTime,
            _owner
        );
    }

    /// @notice method for creating basic sales
    /// @param _contract address of the collection
    /// @param _tokenIds tokenIds to be sold
    /// @param _amounts amount to be put on sales (must be 1 for 721)
    /// @param _prices prices per item per sale
    /// @param _startingTimes starting times of the sales (0 for immediate)
    /// @param _endTimes end times of the sales (0 for no end time)
    /// @param _owner owner of the token to be put on sale (must be operated by the caller)
    function createSaleDelegateBatch(
        address _contract,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256[] memory _prices,
        uint256[] memory _startingTimes,
        uint256[] memory _endTimes,
        address _owner
    ) external nonReentrant {
        require(_tokenIds.length == _amounts.length, "invalid input length");
        require(_tokenIds.length == _prices.length, "invalid input length");
        require(
            _tokenIds.length == _startingTimes.length,
            "invalid input length"
        );
        require(_tokenIds.length == _endTimes.length, "invalid input length");
        _checkTokenOperator(_contract, _owner, _msgSender());
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _checkNotOnSale(_contract, _tokenIds[i], _owner);
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _createSale(
                _contract,
                _tokenIds[i],
                _amounts[i],
                _prices[i],
                _startingTimes[i],
                _endTimes[i],
                _owner
            );
        }
    }

    /// @notice method for updating a basic sale
    /// @param _contract address of the collection
    /// @param _tokenId tokenId on sale
    /// @param _amount amount to be put on sale (must be 1 for 721)
    /// @param _price price per item
    function updateSale(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) external nonReentrant onSale(_contract, _tokenId, _msgSender()) {
        _updateSale(_contract, _tokenId, _amount, _price, _msgSender());
    }

    /// @notice method for updating a basic sale from an operator
    /// @param _contract address of the collection
    /// @param _tokenId tokenId on sale
    /// @param _amount amount to be put on sale (must be 1 for 721)
    /// @param _price price per item
    /// @param _owner owner of the token on sale (must be operated by the caller)
    function updateSaleDelegate(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _owner
    ) external nonReentrant onSale(_contract, _tokenId, _owner) {
        _checkTokenOperator(_contract, _owner, _msgSender());
        _updateSale(_contract, _tokenId, _amount, _price, _owner);
    }

    /// @notice method for cancelling a basic sale
    /// @param _contract address of the collection
    /// @param _tokenId tokenId on sale
    function cancelSale(
        address _contract,
        uint256 _tokenId
    ) external nonReentrant onSale(_contract, _tokenId, _msgSender()) {
        _cancelSale(_contract, _tokenId, _msgSender());
    }

    /// @notice method for cancelling a basic sale from an operator
    /// @param _contract address of the collection
    /// @param _tokenId tokenId on sale
    /// @param _owner owner of the token on sale (must be operated by the caller)
    function cancelSaleDelegate(
        address _contract,
        uint256 _tokenId,
        address _owner
    ) external nonReentrant onSale(_contract, _tokenId, _owner) {
        _checkTokenOperator(_contract, _owner, _msgSender());
        _cancelSale(_contract, _tokenId, _owner);
    }

    /// @notice method for purchasing a sale
    /// @param _contract address of the collection
    /// @param _tokenId tokenId on sale
    /// @param _amount amount to be purchased (must be 1 for 721)
    /// @param _seller seller (owner) of the token on sale
    function purchase(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        address _seller
    ) external payable nonReentrant onSale(_contract, _tokenId, _seller) {
        _purchase(_contract, _tokenId, _amount, _seller, _msgSender());
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function _createSale(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        uint256 _startingTime,
        uint256 _endTime,
        address _owner
    ) private {
        _checkTokenOwner(_contract, _tokenId, _owner);
        _checkTokenOperator(_contract, _owner, address(this));
        _checkTokenBalance(_contract, _tokenId, _owner, _amount);
        _checkValidMinterFee(_contract, _tokenId, _amount, _price);
        require(
            _endTime == 0 || _startingTime <= _endTime,
            "invalid time window"
        );
        // solhint-disable-next-line not-rely-on-time
        require(
            _endTime == 0 || block.timestamp < _endTime,
            "invalid end time"
        );

        sales[_contract][_tokenId][_owner] = Sale(
            _amount,
            _price,
            _startingTime,
            _endTime
        );

        emit SaleCreated(
            _owner,
            _contract,
            _tokenId,
            _amount,
            _price,
            _startingTime,
            _endTime
        );
    }

    function _updateSale(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price,
        address _owner
    ) private {
        _checkTokenOwner(_contract, _tokenId, _owner);
        _checkTokenOperator(_contract, _owner, address(this));
        _checkTokenBalance(_contract, _tokenId, _owner, _amount);

        Sale storage sale = sales[_contract][_tokenId][_owner];
        sale.amount = _amount;
        sale.price = _price;

        emit SaleUpdated(_owner, _contract, _tokenId, _amount, _price);
    }

    function _cancelSale(
        address _contract,
        uint256 _tokenId,
        address _owner
    ) private {
        _checkTokenOwner(_contract, _tokenId, _owner);

        delete (sales[_contract][_tokenId][_owner]);

        emit SaleCancelled(_owner, _contract, _tokenId);
    }

    function _purchase(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        address _seller,
        address _buyer
    ) private {
        Sale storage sale = sales[_contract][_tokenId][_seller];
        _checkTokenOwner(_contract, _tokenId, _seller);
        _checkTokenOperator(_contract, _seller, address(this));
        _checkTokenBalance(_contract, _tokenId, _seller, _amount);
        // solhint-disable-next-line not-rely-on-time
        _checkValidTimeWindow(block.timestamp, sale.startingTime, sale.endTime);
        require(sale.amount >= _amount, "not enough amount");

        uint256 price = sale.price;
        uint256 totalPrice = price.mul(_amount);
        require(msg.value == totalPrice, "not enough payment");

        uint256 totalMarketplaceFee = totalPrice.mul(marketplaceFee).div(10000);
        uint256 remainer = totalPrice.sub(totalMarketplaceFee);
        payable(marketplaceFeeReceiver).transfer(totalMarketplaceFee);

        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981)) {
            IERC2981 collection = IERC2981(_contract);
            (address minter, uint256 minterFee) = collection.royaltyInfo(
                _tokenId,
                totalPrice
            );
            require(
                minterFee == 0 ||
                    minterFee < totalPrice.sub(totalMarketplaceFee),
                "minter fee too high"
            );
            require(minter != address(0), "invalid minter");

            remainer = remainer.sub(minterFee);
            payable(minter).transfer(minterFee);
        }

        payable(_seller).transfer(remainer);

        sale.amount = sale.amount.sub(_amount);
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC721)) {
            IERC721 collection = IERC721(_contract);
            collection.safeTransferFrom(_seller, _buyer, _tokenId);
        } else if (
            IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC1155)
        ) {
            IERC1155 collection = IERC1155(_contract);
            collection.safeTransferFrom(
                _seller,
                _buyer,
                _tokenId,
                _amount,
                "0x0"
            );
        } else {
            revert("invalid contract");
        }
        if (sale.amount == 0) {
            delete sales[_contract][_tokenId][_seller];
        }

        emit SaleMade(
            _buyer,
            _seller,
            _contract,
            _tokenId,
            _amount,
            price,
            totalPrice
        );
    }

    function _checkTokenOwner(
        address _contract,
        uint256 _tokenId,
        address _owner
    ) internal view {
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC721)) {
            IERC721 collection = IERC721(_contract);
            require(collection.ownerOf(_tokenId) == _owner, "caller not owner");
        } else if (
            IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC1155)
        ) {
            IERC1155 collection = IERC1155(_contract);
            require(
                collection.balanceOf(_owner, _tokenId) > 0,
                "caller not owner"
            );
        } else {
            revert("invalid contract");
        }
    }

    function _checkTokenOperator(
        address _contract,
        address _owner,
        address _caller
    ) internal view {
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC721)) {
            IERC721 collection = IERC721(_contract);
            require(
                collection.isApprovedForAll(_owner, _caller),
                _caller == address(this)
                    ? "contract is not approved"
                    : "delegate is not approved"
            );
        } else if (
            IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC1155)
        ) {
            IERC1155 collection = IERC1155(_contract);
            require(
                collection.isApprovedForAll(_owner, _caller),
                _caller == address(this)
                    ? "contract is not approved"
                    : "delegate is not approved"
            );
        } else {
            revert("invalid contract");
        }
    }

    function _checkTokenBalance(
        address _contract,
        uint256 _tokenId,
        address _owner,
        uint256 _amount
    ) internal view {
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC721)) {
            require(_amount == 1, "invalid amount");
        } else if (
            IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC1155)
        ) {
            IERC1155 collection = IERC1155(_contract);
            require(
                collection.balanceOf(_owner, _tokenId) >= _amount,
                "balance not enough"
            );
        } else {
            revert("invalid contract");
        }
    }

    //TODO(dani): test price = 0
    function _checkValidMinterFee(
        address _contract,
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) internal view {
        if (IERC165(_contract).supportsInterface(_INTERFACE_ID_ERC2981)) {
            IERC2981 collection = IERC2981(_contract);

            uint256 totalPrice = _price.mul(_amount);
            uint256 totalMarketplaceFee = totalPrice.mul(marketplaceFee).div(
                10000
            );

            (address minter, uint256 minterFee) = collection.royaltyInfo(
                _tokenId,
                totalPrice
            );
            require(
                minterFee == 0 ||
                    minterFee < totalPrice.sub(totalMarketplaceFee),
                "minter fee too high"
            );
            require(minter != address(0), "invalid minter");
        }
    }

    function _checkValidTimeWindow(
        uint256 _timestamp,
        uint256 _startingTime,
        uint256 _endTime
    ) internal pure {
        require(
            _startingTime == 0 || _timestamp >= _startingTime,
            "sale not started"
        );
        require(_endTime == 0 || _timestamp <= _endTime, "sale already ended");
    }

    function _checkNotOnSale(
        address _collection,
        uint256 _tokenId,
        address _seller
    ) internal view {
        Sale memory sale = sales[_collection][_tokenId][_seller];
        require(sale.amount == 0, "token is already for sale");
    }
}
