// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./HasSecondarySaleFees.sol";

contract MarketplaceV2_5 is Ownable {
    using SafeERC20 for IERC20;

    enum TokenType {ERC1155, ERC721, ERC721Deprecated}

    struct nftToken {
        address collection;
        uint256 id;
        TokenType tokenType;
    }

    struct Position {
        nftToken nft;
        uint256 amount;
        uint256 price;
        address owner;
        address currency;
    }

    struct MarketplaceFee {
        bool customFee;
        uint16 buyerFee;
        uint16 sellerFee;
    }

    struct CollectionRoyalties {
        address recipient;
        uint256 fee;
    }

    mapping(uint256 => Position) public positions;
    uint256 public positionsCount = 0;

    address public marketplaceBeneficiaryAddress;
    mapping(address => MarketplaceFee) private marketplaceCollectionFee;
    mapping(address => CollectionRoyalties) private customCollectionRoyalties;

    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    /**
     * @dev Emitted when changing `MarketplaceFee` for an `colection`.
     */
    event MarketplaceFeeChanged(
        address indexed colection,
        uint16 buyerFee,
        uint16 sellerFee
    );

    /**
     * @dev Emitted when changing custom `CollectionRoyalties` for an `colection`.
     */
    event CollectionRoyaltiesChanged(
        address indexed colection,
        address recipient,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when `owner` puts `token` from `collection` on sale for `price` `currency` per one.
     */
    event NewPosition(
        address indexed owner,
        uint256 indexed id,
        address collection,
        uint256 token,
        uint256 amount,
        uint256 price,
        address currency
    );

    /**
     * @dev Emitted when `buyer` buys `token` from `owner`.
     */
    event Buy(
        address owner,
        address buyer,
        uint256 indexed position,
        address indexed collection,
        uint256 indexed token,
        uint256 amount,
        uint256 price,
        address currency
    );

    /**
     * @dev Emitted when `owner` cancells his `position`.
     */
    event Cancel(address owner, uint256 position);

    constructor() {
        marketplaceBeneficiaryAddress = payable(msg.sender);
        marketplaceCollectionFee[address(0)] = MarketplaceFee(true, 250, 250);
    }

    /**
     * @dev Change marketplace beneficiary address.
     *
     * @param _marketplaceBeneficiaryAddress address of the beneficiary
     */
    function changeMarketplaceBeneficiary(
        address _marketplaceBeneficiaryAddress
    ) external onlyOwner {
        marketplaceBeneficiaryAddress = _marketplaceBeneficiaryAddress;
    }

    /**
     * @dev Returns `MarketplaceFee` for given `_collection`.
     *
     * @param _collection address of collection
     */
    function getMarketplaceFee(address _collection) public view returns(MarketplaceFee memory) {
        if (marketplaceCollectionFee[_collection].customFee) {
            return marketplaceCollectionFee[_collection];
        }
        return marketplaceCollectionFee[address(0)];
    }

    /**
     * @dev Change `MarketplaceFee` for given `_collection`.
     *
     * @param _collection address of collection
     * @param _buyerFee needed buyer fee
     * @param _sellerFee needed seller fee
     *
     * Emits a {MarketplaceFeeChanged} event.
     */
    function changeMarketplaceCollectionFee(
        address _collection,
        uint16 _buyerFee,
        uint16 _sellerFee
    ) external onlyOwner {
        marketplaceCollectionFee[_collection] = MarketplaceFee(
            true,
            _buyerFee,
            _sellerFee
        );
        emit MarketplaceFeeChanged(_collection, _buyerFee, _sellerFee);
    }

    /**
     * @dev Remove `MarketplaceFee` for given `_collection`.
     *
     * @param _collection address of collection
     *
     * Emits a {MarketplaceFeeChanged} event.
     */
    function removeMarketplaceCollectionFee(address _collection) external onlyOwner {
        require(_collection != address(0), "Wrong collection");
        delete marketplaceCollectionFee[_collection];
        emit MarketplaceFeeChanged(
            _collection,
            marketplaceCollectionFee[address(0)].buyerFee,
            marketplaceCollectionFee[address(0)].sellerFee
        );
    }

    /**
     * @dev Returns `CollectionRoyalties` for given `_collection`.
     *
     * @param _collection address of collection
     */
    function getCustomCollectionRoyalties(address _collection) public view returns(CollectionRoyalties memory) {
        return customCollectionRoyalties[_collection];
    }

    /**
     * @dev Change `CollectionRoyalties` for given `_collection`.
     *
     * @param _collection address of collection
     * @param _recipient royalties recipient
     * @param _amount royalties amount
     *
     * Emits a {CollectionRoyaltiesChanged} event.
     */
    function changeCollectionRoyalties(
        address _collection,
        address _recipient,
        uint256 _amount
    ) external onlyOwner {
        require(_collection != address(0), "Wrong collection");
        require(_amount > 0 && _amount < 10000, "Wrong amount");
        require(!IERC165(_collection).supportsInterface(_INTERFACE_ID_FEES), "Collection haw own royalties");
        customCollectionRoyalties[_collection] = CollectionRoyalties(_recipient, _amount);
        emit CollectionRoyaltiesChanged(_collection, _recipient, _amount);
    }

    /**
     * @dev Remove `CollectionRoyalties` for given `_collection`.
     *
     * @param _collection address of collection
     *
     * Emits a {CollectionRoyaltiesChanged} event.
     */
    function removeCollectionRoyalties(address _collection) external onlyOwner {
        delete customCollectionRoyalties[_collection];
        emit CollectionRoyaltiesChanged(_collection, address(0), 0);
    }

    /**
     * @dev Create new sale position for token with `_id` from `_collection`.
     *
     * @param _collection address of collection
     * @param _tokenType TokenType of collection contract
     * @param _id address token id in collection
     * @param _amount amount of tokens to sale
     * @param _price proce for one token
     * @param _currency sale currency token address, use `address(0)` for BNB
     *
     * Emits a {NewPosition} event.
     */
    function putOnSale(
        address _collection,
        TokenType _tokenType,
        uint256 _id,
        uint256 _amount,
        uint256 _price,
        address _currency
    ) external returns (uint256) {
        if (_tokenType == TokenType.ERC1155) {
            require(
                IERC1155(_collection).balanceOf(msg.sender, _id) >= _amount,
                "Wrong amount"
            );
        } else {
            require(
                (IERC721(_collection).ownerOf(_id) == msg.sender) &&
                    (_amount == 1),
                "Wrong amount"
            );
        }
        positions[++positionsCount] = Position(
            nftToken(_collection, _id, _tokenType),
            _amount,
            _price,
            msg.sender,
            _currency
        );

        emit NewPosition(
            msg.sender,
            positionsCount,
            _collection,
            _id,
            _amount,
            _price,
            _currency
        );
        return positionsCount;
    }

    /**
     * @dev Remove position `_id` from sale.
     *
     * @param _id position id
     *
     * Emits a {Cancel} event.
     */
    function cancel(uint256 _id) external {
        require(msg.sender == positions[_id].owner || msg.sender == owner(), "Access denied");
        positions[_id].amount = 0;

        emit Cancel(msg.sender, _id);
    }

    /**
     * @dev Purchase `amount` of tokens by specific `position`.
     *
     * @param _position position id
     * @param _amount amount of tokens needed
     * @param _buyer address of the token destination
     * @param _data additional data for erc1155
     *
     * Emits a {Buy} event.
     */
    function buy(
        uint256 _position,
        uint256 _amount,
        address _buyer,
        bytes calldata _data
    ) external payable {
        Position memory position = positions[_position];
        require(position.amount >= _amount, "Wrong amount");

        transferWithFees(_position, _amount);

        if (_buyer == address(0)) {
            _buyer = msg.sender;
        }
        if (position.nft.tokenType == TokenType.ERC1155) {
            IERC1155(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id,
                _amount,
                _data
            );
        } else if (position.nft.tokenType == TokenType.ERC721) {
            require(_amount == 1, "Wrong amount");
            IERC721(position.nft.collection).safeTransferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        } else if (position.nft.tokenType == TokenType.ERC721Deprecated) {
            require(_amount == 1, "Wrong amount");
            IERC721(position.nft.collection).transferFrom(
                position.owner,
                _buyer,
                position.nft.id
            );
        }
        emit Buy(
            position.owner,
            _buyer,
            _position,
            position.nft.collection,
            position.nft.id,
            _amount,
            position.price,
            position.currency
        );
    }

    /**
     * @dev Calculate all needed fees and transfers them to recipients.
     */
    function transferWithFees(uint256 _position, uint256 _amount) internal {
        Position storage position = positions[_position];
        uint256 price = position.price * _amount;
        MarketplaceFee memory marketplaceFee = getMarketplaceFee(position.nft.collection);
        uint256 buyerFee = getFee(price, marketplaceFee.buyerFee);
        uint256 sellerFee = getFee(price, marketplaceFee.sellerFee);
        uint256 total = price + buyerFee;

        if (position.currency == address(0)) {
            require(msg.value >= total, "Insufficient balance");
            uint256 returnBack = msg.value - total;
            if (returnBack > 0) {
                payable(msg.sender).transfer(returnBack);
            }
        }

        if (buyerFee + sellerFee > 0) {
            transfer(
                marketplaceBeneficiaryAddress,
                position.currency,
                buyerFee + sellerFee
            );
        }
        uint256 fees = transferFees(price, position) + sellerFee;
        transfer(position.owner, position.currency, price - fees);

        position.amount = position.amount - _amount;
    }

    function transfer(
        address _to,
        address _currency,
        uint256 _amount
    ) internal {
        if (_currency == address(0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_currency).transferFrom(msg.sender, _to, _amount);
        }
    }

    /**
     * @dev Calculate royalties fee.
     */
    function transferFees(uint256 _price, Position memory position)
        internal
        returns (uint256)
    {
        HasSecondarySaleFees collection =
            HasSecondarySaleFees(position.nft.collection);
        uint256 result = 0;
        if (
            (position.nft.tokenType == TokenType.ERC1155 &&
                IERC1155(position.nft.collection).supportsInterface(
                    _INTERFACE_ID_FEES
                )) ||
            ((position.nft.tokenType == TokenType.ERC721 ||
                position.nft.tokenType == TokenType.ERC721Deprecated) &&
                IERC721(position.nft.collection).supportsInterface(
                    _INTERFACE_ID_FEES
                ))
        ) {
            uint256[] memory fees = collection.getFeeBps(position.nft.id);
            address payable[] memory recipients =
                collection.getFeeRecipients(position.nft.id);
            for (uint256 i = 0; i < fees.length; i++) {
                uint256 fee = getFee(_price, fees[i]);
                if (fee > 0) {
                    transfer(recipients[i], position.currency, fee);
                    result = result + fee;
                }
            }
        } else if (customCollectionRoyalties[position.nft.collection].fee > 0) {
            uint256 fee = getFee(_price, customCollectionRoyalties[position.nft.collection].fee);
            transfer(customCollectionRoyalties[position.nft.collection].recipient, position.currency, fee);
            result = result + fee;
        }
        return result;
    }

    /**
     * @dev Calculate the fee for an `_amount`.
     */
    function getFee(uint256 _amount, uint256 _fee)
        internal
        pure
        returns (uint256)
    {
        return _amount * _fee / 10000;
    }
}