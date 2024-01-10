// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./AccessControl.sol";
import "./EIP712MetaTransaction.sol";
import "./ERC20.sol";

contract VendingMachine is
    AccessControl,
    EIP712MetaTransaction("VendingMachine", "1")
{
    event SeedPurchase(
        address indexed from,
        uint256 indexed itemId,
        uint256 indexed value,
        uint32 itemType,
        bytes varData
    );
    event EtherPurchase(
        address indexed from,
        uint256 indexed itemId,
        uint256 indexed value,
        uint32 itemType,
        bytes varData
    );
    event BreedSeed(
        address indexed breeder,
        address indexed breedee,
        uint256 indexed price,
        bytes varData
    );
    event BreedEth(
        address indexed breeder,
        address indexed breedee,
        uint256 indexed price,
        bytes varData
    );

    struct InventoryEntry {
        uint256 index;
        uint256 seedPrice;
        uint256 ethPrice;
        uint32 quantity;
        uint32 itemType;
    }

    // Constants
    uint32 public constant UINT32_MAX = ~uint32(0);

    // Privileges
    bytes32 public constant PRIV_MANAGE = keccak256("PRIV_MANAGE");
    bytes32 public constant PRIV_WITHDRAW = keccak256("PRIV_WITHDRAW");

    mapping(uint256 => InventoryEntry) public inventoryEntries;
    uint256[] public itemIds;
    uint256 public nugbaseFeeEth = 0.0024 ether;
    uint256 public breedeeFeeEth = 0.0006 ether;
    uint256 public burnedSeed = 1200;
    uint256 public breedeeFeeSeed = 500;
    uint256 public daoSeed = 300;
    address public daoAddress = 0xFc8e07fDF358b8692976Eb649850A90b75079749;

    ERC20 internal seedContract =
        ERC20(0x80D55041E3954405664694899fF9F202c13C0e1c);

    constructor() {
        // Grant other privileges to the contract creator
        _setupRole(DEFAULT_ADMIN_ROLE, msgSender());
        _setupRole(PRIV_MANAGE, msgSender());
        _setupRole(PRIV_WITHDRAW, msgSender());
    }

    function seedPurchase(
        uint256 _itemId,
        uint256 _value,
        bytes calldata _varData
    ) external {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.seedPrice != 0);
        require(_value == inventoryEntry.seedPrice);
        require(seedContract.transferFrom(msgSender(), address(this), _value));
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit SeedPurchase(msgSender(), _itemId, _value, _itemType, _varData);
    }

    function etherPurchase(uint256 _itemId, bytes calldata _varData)
        external
        payable
    {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        require(_inventoryEntryExists(inventoryEntry));
        require(inventoryEntry.ethPrice != 0);
        require(msg.value == inventoryEntry.ethPrice);
        uint32 _itemType = inventoryEntry.itemType; // value saved before entry is deleted
        _deductInventoryItem(inventoryEntry, _itemId);
        emit EtherPurchase(
            msgSender(),
            _itemId,
            msg.value,
            _itemType,
            _varData
        );
    }

    function upsertInventoryItem(
        uint256 _itemId,
        uint256 seedPrice,
        uint256 ethPrice,
        uint32 quantity,
        uint32 itemType
    ) external onlyRole(PRIV_MANAGE) {
        require(quantity > 0);
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            // New item
            inventoryEntry.index = itemIds.length;
            itemIds.push(_itemId);
        }
        inventoryEntry.seedPrice = seedPrice;
        inventoryEntry.ethPrice = ethPrice;
        inventoryEntry.quantity = quantity;
        inventoryEntry.itemType = itemType;
    }

    function deleteInventoryItem(uint256 _itemId)
        external
        onlyRole(PRIV_MANAGE)
    {
        _deleteInventoryItem(_itemId);
    }

    function withdrawSeed(uint256 _amount) external onlyRole(PRIV_WITHDRAW) {
        seedContract.transfer(msgSender(), _amount);
    }

    function withdrawEther(uint256 _amount) external onlyRole(PRIV_WITHDRAW) {
        payable(msgSender()).transfer(_amount);
    }

    function totalItems() public view returns (uint256) {
        return itemIds.length;
    }

    function _deductInventoryItem(
        InventoryEntry storage inventoryEntry,
        uint256 _itemId
    ) internal {
        if (inventoryEntry.quantity == UINT32_MAX) {
            return;
        } else if (inventoryEntry.quantity > 1) {
            inventoryEntry.quantity--;
        } else {
            _deleteInventoryItem(_itemId);
        }
    }

    function _deleteInventoryItem(uint256 _itemId) internal {
        InventoryEntry storage inventoryEntry = inventoryEntries[_itemId];
        if (!_inventoryEntryExists(inventoryEntry)) {
            return;
        }
        uint256 lastItemIndex = itemIds.length - 1; // Safe because at least one item must exist (asserted above)
        uint256 lastItemId = itemIds[lastItemIndex];
        itemIds[inventoryEntry.index] = itemIds[lastItemIndex];
        inventoryEntries[lastItemId].index = inventoryEntry.index;
        delete inventoryEntries[_itemId];
    }

    function _inventoryEntryExists(InventoryEntry storage inventoryEntry)
        internal
        view
        returns (bool)
    {
        return inventoryEntry.quantity != 0;
    }

    function breedEth(address payable _breedee, bytes calldata _varData)
        external
        payable
    {
        require(msg.value == nugbaseFeeEth + breedeeFeeEth);
        payable(address(this)).transfer(nugbaseFeeEth);
        _breedee.transfer(breedeeFeeEth);
        emit BreedEth(
            msg.sender,
            _breedee,
            nugbaseFeeEth + breedeeFeeEth,
            _varData
        );
    }

    function breedSeed(address _breedee, bytes calldata _varData) external {
        // ensure user has enough SEED to breed and has permitted the
        // VendingMachine to spend their SEED
        require(
            seedContract.balanceOf(msgSender()) >=
                (burnedSeed + breedeeFeeSeed + daoSeed)
        );
        require(
            seedContract.allowance(msgSender(), address(this)) >=
                (burnedSeed + breedeeFeeSeed + daoSeed)
        );
        // Split the SEED 3 ways to burn, breedee, and FlowerpatchDAO
        seedContract.burn(msgSender(), burnedSeed);
        if (msgSender() != _breedee) {
            require(
                seedContract.transferFrom(msgSender(), _breedee, breedeeFeeSeed)
            );
        } else {
            require(
                seedContract.transferFrom(
                    msgSender(),
                    address(this),
                    breedeeFeeSeed
                )
            );
        }
        require(seedContract.transferFrom(msgSender(), daoAddress, daoSeed));

        emit BreedSeed(
            msgSender(),
            _breedee,
            burnedSeed + breedeeFeeSeed + daoSeed,
            _varData
        );
    }

    function setBreedeeFeeEth(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        breedeeFeeEth = _fee;
    }

    function setNugbaseFeeEth(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        nugbaseFeeEth = _fee;
    }

    function setBreedeeFeeSeed(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        breedeeFeeSeed = _fee;
    }

    function setBurnedSeed(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        burnedSeed = _fee;
    }

    function setDaoSeed(uint256 _fee) external onlyRole(PRIV_MANAGE) {
        daoSeed = _fee;
    }

    function setDaoAddress(address _dao) external onlyRole(PRIV_MANAGE) {
        daoAddress = _dao;
    }

    function setSeedToken(address _seed) external onlyRole(PRIV_MANAGE) {
        seedContract = ERC20(_seed);
    }
}
