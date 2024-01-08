// SPDX-License-Identifier: MIT
// Latest stable version of solidity
pragma solidity ^0.8.7;
pragma experimental ABIEncoderV2;

import "./AccessControl.sol";
import "./EnumerableSet.sol";
import "./CollectionFree.sol";
import "./IFarmV2.sol";

contract FactoryFree is AccessControl {
    event NewCollection(
        string uri,
        uint256 total,
        uint256 startTime,
        uint256 endTime,
        address admin,
        address collectionAddress
    );

    bytes32 public constant COLLECTION_ROLE =
        bytes32(keccak256("COLLECTION_ROLE"));

    CollectionFree[] public collections;

    struct Card {
        uint256 total;
        uint256 startTime;
        uint256 endTime;
        string uri;
    }

    mapping(address => Card) public cards;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createCollection(CollectionData memory collecData)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address)
    {
        CollectionFree collection = new CollectionFree(collecData);

        collections.push(collection);

        IFarmV2(collecData.farm).grantRole(
            COLLECTION_ROLE,
            address(collection)
        );

        cards[address(collection)] = Card(
            collecData.total,
            collecData.startTime,
            collecData.endTime,
            collecData.uri
        );

        emit NewCollection(
            collecData.uri,
            collecData.total,
            collecData.startTime,
            collecData.endTime,
            collecData.admin,
            address(collection)
        );
        return address(collection);
    }

    function collectionLength() external view returns (uint256) {
        return collections.length;
    }

    function buy(
        address collection,
        uint256 id,
        address buyer
    ) external returns (bool) {
        require(buyer == msg.sender, "Factory: you are not authorized ");

        CollectionFree _collection = CollectionFree(collection);

        _collection.buy(buyer, id);

        return true;
    }
}
