// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./SafeERC20.sol";
import "./OwnableUpgradeable.sol";

contract PinkyWeb3Market is OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint public constant VERSION = 1;

    uint256 public itemCount;
    address public feeReceiverAddress;
    uint256 public createFee;
    uint256 public buyFeePercent;

    mapping(uint256 => Item) public items;
    mapping(uint256 => mapping(address => uint256)) public itemPrice;
    mapping(uint256 => ItemDiscount) public itemDiscounts;
    mapping(address => uint256[]) public ownerItems;
    mapping(address => uint256[]) public purchaseItems;
    mapping(uint256 => mapping(address => bool)) public isBoughtBy;

    struct Item {
        string name;
        address owner;
    }

    struct ItemDiscount {
        uint256 percent;
        uint256 expiration;
    }

    event ItemCreated(
        uint256 indexed id,
        address indexed owner,
        string name,
        address token,
        uint256 price
    );
    event ItemPriceUpdated(uint256 indexed id, address token, uint256 price);
    event ItemPurchased(
        uint256 indexed id,
        address indexed owner,
        address buyer,
        address token,
        uint256 price
    );

    function initialize(
        uint256 _createFee,
        uint256 _buyFeePercent,
        address _feeReceiverAddress
    ) public initializer {
        __Ownable_init(msg.sender);

        createFee = _createFee;
        buyFeePercent = _buyFeePercent;
        feeReceiverAddress = _feeReceiverAddress;
    }

    function setFeeReceiverAddress(address _address) public onlyOwner {
        feeReceiverAddress = _address;
    }

    function setCreateFee(uint256 _fee) public onlyOwner {
        createFee = _fee;
    }

    function setBuyFee(uint256 _percent) public onlyOwner {
        buyFeePercent = _percent;
    }

    function _addItem(
        string memory _name,
        address _token,
        uint256 _price,
        address _owner
    ) private {
        itemCount++;
        items[itemCount] = Item({name: _name, owner: _owner});
        itemPrice[itemCount][_token] = _price;
        ownerItems[_owner].push(itemCount);
    }

    function addMultiableItems(
        string[] memory _names,
        address[] memory _tokens,
        uint256[] memory _prices,
        address[] memory _owners
    ) external onlyOwner {
        require(
            _names.length == _tokens.length && _names.length == _prices.length,
            "Invalid input"
        );

        for (uint256 i = 0; i < _names.length; i++) {
            _addItem(_names[i], _tokens[i], _prices[i], _owners[i]);
        }
    }

    function addMultiableItemBuyer(
        uint256[] memory _ids,
        address[] memory _buyers
    ) external onlyOwner {
        require(_ids.length == _buyers.length, "Invalid input");

        for (uint256 i = 0; i < _ids.length; i++) {
            purchaseItems[_buyers[i]].push(_ids[i]);
            isBoughtBy[_ids[i]][_buyers[i]] = true;
        }
    }

    function addItemOnPinky(
        string memory _name,
        address _token,
        uint256 _price
    ) external payable {
        if (createFee > 0) {
            require(msg.value >= createFee, "Not enough funds");
            payable(feeReceiverAddress).transfer(createFee);
        }

        _addItem(_name, _token, _price, msg.sender);

        emit ItemCreated(itemCount, msg.sender, _name, _token, _price);
    }

    function updateItemPrice(
        uint256 _id,
        address _token,
        uint256 _price
    ) public {
        require(_id > 0 && _id <= itemCount, "Invalid Item ID");
        Item storage item = items[_id];
        require(item.owner == msg.sender, "You are not the owner");
        itemPrice[itemCount][_token] = _price;

        emit ItemPriceUpdated(_id, _token, _price);
    }

    function setItemDiscount(
        uint256 _id,
        uint256 _percent,
        uint256 _expiration
    ) public {
        require(_id > 0 && _id <= itemCount, "Invalid Item ID");
        itemDiscounts[_id] = ItemDiscount({
            percent: _percent,
            expiration: _expiration
        });
    }

    function buyDappOnPinky(uint256 _id, address _token) public payable {
        Item storage item = items[_id];
        uint256 price = itemPrice[_id][_token];

        require(_id > 0 && _id <= itemCount, "Invalid Item ID");
        require(item.owner != msg.sender, "You can't buy your own item");
        require(price > 0, "Unsupported token");

        if (itemDiscounts[_id].expiration > block.timestamp) {
            price = (price * itemDiscounts[_id].percent) / 10000;
        }

        uint256 fee = (price * buyFeePercent) / 10000;

        if (_token != address(0)) {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                feeReceiverAddress,
                fee
            );
            IERC20(_token).safeTransferFrom(
                msg.sender,
                item.owner,
                price - fee
            );
        } else {
            require(msg.value >= price, "Not enough funds");
            payable(feeReceiverAddress).transfer(fee);
            payable(item.owner).transfer(msg.value - fee);
        }

        purchaseItems[msg.sender].push(_id);
        isBoughtBy[_id][msg.sender] = true;

        emit ItemPurchased(_id, item.owner, msg.sender, _token, price);
    }
}
