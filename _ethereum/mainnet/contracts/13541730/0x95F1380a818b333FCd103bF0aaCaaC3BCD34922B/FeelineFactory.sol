// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./FeelineClub.sol";

/**
 * @title FeelineFactory
 */
contract FeelineFactory is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Feeline Club Contract
    FeelineClub private _FeelineClub;
    address public FEELINE_CLUB_CONTRACT_ADDRESS =
        0xb5Cc5D1a848432EED564426f733d7E83BF3aE653;

    // Max alowed limit per address to mint
    uint256 private _itemsPerAddress;

    // How many items are available to sell on the Store
    uint256 private _inventory;

    // Activation Flag
    bool private _active;

    // Contract is working
    bool private _stopped;

    // How many items per address have been minted
    uint256 private _saleCount;
    mapping(address => uint256) private _mintedCount1;
    mapping(address => uint256) private _mintedCount2;
    mapping(address => uint256) private _mintedCount3;
    mapping(address => uint256) private _mintedCount4;
    mapping(address => uint256) private _mintedCount5;

    // Price per item
    uint256 private _price;

    event InventoryChanged(uint256 from, uint256 to);
    event ActiveChanged(bool from, bool to);

    constructor() {
        //FeelineClub Contract Address
        _FeelineClub = FeelineClub(FEELINE_CLUB_CONTRACT_ADDRESS);
        _active = false;
        _stopped = false;
        _saleCount = 0;
        _inventory = 0;
        // 0.02 ETH
        _price = 2 * 10**16;
        _itemsPerAddress = 20;
    }

    /**
     * @dev Checks if stopped is false
     */
    modifier notStopped() {
        require(_stopped == false, "Contract not active");
        _;
    }

    /**
     * @dev Gets the count of items per address
     */
    function getMintedCount(address _address)
        public
        view
        notStopped
        returns (uint256)
    {
        if (_saleCount == 0) {
            return _mintedCount1[_address];
        } else if (_saleCount == 1) {
            return _mintedCount2[_address];
        } else if (_saleCount == 2) {
            return _mintedCount3[_address];
        } else if (_saleCount == 3) {
            return _mintedCount4[_address];
        } else {
            return _mintedCount5[_address];
        }
    }

    /**
     * @dev Sets mintCount of an address
     */
    function _setMintedCount(address _address, uint256 _count)
        private
        notStopped
    {
        if (_saleCount == 0) {
            _mintedCount1[_address] = _count;
        } else if (_saleCount == 1) {
            _mintedCount2[_address] = _count;
        } else if (_saleCount == 2) {
            _mintedCount3[_address] = _count;
        } else if (_saleCount == 3) {
            _mintedCount4[_address] = _count;
        } else {
            _mintedCount5[_address] = _count;
        }
    }

    /**
     * @dev Get the sale count
     */
    function getSaleCount() public view notStopped returns (uint256) {
        return _saleCount;
    }

    /**
     * @dev Set the sale count
     */
    function setSaleCount(uint256 _newSaleCount) public onlyOwner notStopped {
        require(_newSaleCount <= 4, "Cannot use a number bigger than 5");
        _saleCount = _newSaleCount;
    }

    /**
     * @dev Gets the current active state
     */
    function getActive() public view notStopped returns (bool) {
        return _active;
    }

    /**
     * @dev Gets the current inventory
     */
    function getInventory() public view notStopped returns (uint256) {
        return _inventory;
    }

    /**
     * @dev Mints the number of {_count} to {_address}
     */
    function mint(uint256 _count)
        public
        payable
        notStopped
        nonReentrant
    {
        require(
            _FeelineClub.totalSupply().add(_count) <=
                _FeelineClub.MAX_FEELINES(),
            "Cannot exceed max token limit"
        );
        require(
            _inventory.sub(_count) >= 0,
            "Cannot mint more than available on inventory"
        );
        require(_count > 0, "Count must be bigger that 1");
        require(_active == true, "Mint is not active");
        uint256 mintedCount = getMintedCount(msg.sender);
        require(
            (mintedCount.add(_count)) <= _itemsPerAddress,
            "Cannot exceed max token per address"
        );
        require(msg.value == _price.mul(_count), "Price is not correct");
        _inventory = _inventory.sub(_count);
        _setMintedCount(msg.sender, (mintedCount.add(_count)));
        _FeelineClub.mintMultipleTo(msg.sender, _count);
    }

    /**
     * @dev Admin Mint for giveaways
     */
    function adminMint(address _to, uint256 _count)
        public
        onlyOwner
        notStopped
    {
        require(
            _FeelineClub.totalSupply().add(_count) <=
                _FeelineClub.MAX_FEELINES(),
            "Cannot exceed max token limit"
        );
        require(_count > 0, "Count must be bigger that 1");
        _FeelineClub.mintMultipleTo(_to, _count);
    }

    /**
     * @dev Activates the ability to mint items
     */
    function activateMint() public onlyOwner notStopped {
        emit ActiveChanged(false, true);
        _active = true;
    }

    /**
     * @dev Deactivates the ability to mint items
     */
    function deactivateMint() public onlyOwner notStopped {
        emit ActiveChanged(true, false);
        _active = false;
    }

    /**
     * @dev Add items to inventory
     */
    function addToInventory(uint256 _numItems) public onlyOwner notStopped {
        require(
            _FeelineClub.totalSupply().add(_numItems) <=
                _FeelineClub.MAX_FEELINES(),
            "Cannot add to inventory more that max limit"
        );
        uint256 prevInventory = _inventory;
        _inventory = _inventory + _numItems;
        emit InventoryChanged(prevInventory, _inventory);
    }

    /**
     * @dev Remove items from inventory
     */
    function removeFromInventory(uint256 _numItems)
        public
        onlyOwner
        notStopped
    {
        require(
            _inventory.sub(_numItems) >= 0,
            "Cannot remove from inventory more that available"
        );
        uint256 prevInventory = _inventory;
        _inventory = _inventory - _numItems;
        emit InventoryChanged(prevInventory, _inventory);
    }

    /**
     * @dev Transfer the ownership of the contract back to the owner
     */
    function transferBackToOwner() public onlyOwner notStopped {
        _FeelineClub.transferOwnership(owner());
    }

    /**
     * @dev Stops the factory functions
     */
    function stopContract() public onlyOwner notStopped {
        _stopped = true;
        _active = false;
        _inventory = 0;
    }

    /**
     * @dev Gets allowed items per address
     */
    function getItemsPerAddress() public view notStopped returns (uint256) {
        return _itemsPerAddress;
    }

    /**
     * @dev Sets allowed items per address
     */
    function setItemsPerAddress(uint256 numItems) public onlyOwner notStopped {
        _itemsPerAddress = numItems;
    }

    /**
     * @dev Withdraw contract funds
     */
    function withdrawAll() public payable notStopped onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed.");
    }

    /**
     * @dev Gets the price per item
     */
    function getPrice() public view notStopped returns (uint256) {
        return _price;
    }

    /**
     * @dev Sets the price per item
     */
    function setPrice(uint256 _newPrice) public notStopped onlyOwner {
        _price = _newPrice;
    }
}
