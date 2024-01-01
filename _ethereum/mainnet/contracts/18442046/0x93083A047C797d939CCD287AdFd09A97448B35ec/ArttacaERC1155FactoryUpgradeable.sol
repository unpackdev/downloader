// SPDX-License-Identifier: MIT
// Arttaca Contracts (last updated v1.0.0) (collections/erc1155/ArttacaERC1155Factory.sol)

pragma solidity ^0.8.4;

import "./BeaconProxy.sol";

import "./OperableUpgradeable.sol";
import "./ArttacaERC1155Upgradeable.sol";
import "./ArttacaERC1155Beacon.sol";

/**
 * @title ArttacaERC1155Factory
 * @dev This contract is a factory to create ERC1155 collections.
 */
contract ArttacaERC1155FactoryUpgradeable is OperableUpgradeable {

    mapping(uint => address) private collections;
    uint public collectionsCount;
    ArttacaERC1155Beacon beacon;

    /**
     * @dev Emitted when a new ArttacaERC1155 contract is created.
     */
    event Arrtaca1155Created(
        address indexed collectionAddress,
        address indexed owner,
        string name,
        string symbol,
        uint royaltyPercentage,
        string contractURI
    );

    function __ArttacaERC1155Factory_initialize(address _initBlueprint) public initializer onlyInitializing {
        __OperableUpgradeable_init(msg.sender);
        __ArttacaERC1155Factory_initialize_unchained(_initBlueprint);
    }

    function __ArttacaERC1155Factory_initialize_unchained(address _initBlueprint) public onlyInitializing {
        beacon = new ArttacaERC1155Beacon(_initBlueprint);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        uint _royaltyPercentage,
        string memory _contractURI
    ) external returns (address) {

        BeaconProxy collection = new BeaconProxy(
            address(beacon),
            abi.encodeWithSelector(
                ArttacaERC1155Upgradeable(address(0)).__ArttacaERC1155_initialize.selector,
                address(this),
                msg.sender,
                _name,
                _symbol,
                _royaltyPercentage,
                _contractURI
            )
        );
        address newCollectionAddress = address(collection);
        collections[collectionsCount] = newCollectionAddress;
        collectionsCount++;

        emit Arrtaca1155Created(
            newCollectionAddress,
            _msgSender(),
            _name,
            _symbol,
            _royaltyPercentage,
            _contractURI
        );

        return newCollectionAddress;
    }

    function getCollectionAddress(uint _index) public view returns (address) {
        return collections[_index];
    }

    function getBeacon() public view returns (address) {
        return address(beacon);
    }

    function getImplementation() public view returns (address) {
        return beacon.implementation();
    }

    uint256[50] private __gap;
}
