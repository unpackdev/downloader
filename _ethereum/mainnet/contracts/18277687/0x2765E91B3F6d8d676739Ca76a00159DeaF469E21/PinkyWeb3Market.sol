/**
 * Pinky Finance Web 3 Official Smart Contract
 *
 * Website: www.pinky.finance/marketplace
 * Telegram: @pinkyfinanceen
 */
// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/Context.sol@v4.9.3

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File @openzeppelin/contracts/access/Ownable.sol@v4.9.3

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File contracts/Marketplace.sol

pragma solidity ^0.8.17;

contract PinkyWeb3Market is Ownable {
    uint256 public itemCount;
    address public feeReceiverAddress;
    uint256 public createFee;
    uint256 public buyFeePercent;

    mapping(uint256 => Item) public items;
    mapping(address => uint256[]) public ownerItems;
    mapping(address => uint256[]) public purchaseItems;
    mapping(uint256 => mapping(address => bool)) public isBoughtBy;

    struct Item {
        string name;
        address owner;
        uint256 price;
    }

    event ItemCreated(uint256 id, address owner, string name, uint256 price);
    event ItemPriceUpdated(uint256 id, uint256 price);
    event ItemPurchased(
        uint256 id,
        address owner,
        address buyer,
        uint256 price
    );

    constructor(
        uint256 _createFee,
        uint256 _buyFeePercent,
        address _feeReceiverAddress
    ) {
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

    function addItemOnPinky(string memory _name, uint256 _price) public payable {
        require(msg.value >= createFee, "Not enough funds");

        itemCount++;
        items[itemCount] = Item(_name, msg.sender, _price);
        ownerItems[msg.sender].push(itemCount);
        payable(feeReceiverAddress).transfer(createFee);

        emit ItemCreated(itemCount, msg.sender, _name, _price);
    }

    function updateItemPrice(uint256 _id, uint256 _price) public {
        require(_id > 0 && _id <= itemCount, "Invalid Item ID");
        Item storage item = items[_id];
        require(item.owner == msg.sender, "You are not the owner");
        item.price = _price;

        emit ItemPriceUpdated(_id, _price);
    }

    function buyDappOnPinky(uint256 _id) public payable {
        require(_id > 0 && _id <= itemCount, "Invalid Item ID");
        Item storage item = items[_id];
        require(msg.value >= item.price, "Not enough funds");
        require(item.owner != msg.sender, "You can't buy your own item");
        purchaseItems[msg.sender].push(_id);
        isBoughtBy[_id][msg.sender] = true;

        uint256 fee = (msg.value * buyFeePercent) / 100;
        payable(feeReceiverAddress).transfer(fee);
        payable(item.owner).transfer(msg.value - fee);

        emit ItemPurchased(_id, item.owner, msg.sender, item.price);
    }
}