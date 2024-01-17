// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./Collection.sol";

contract CollectionFactory is Ownable {
    // events
    event NewCollection(address indexed collection, address indexed owner, uint indexed deployIndex);

    // deployed marketplaces
    mapping (uint => address) public collections;
    uint public collectionsCounter;

    /**
     * @notice Constructor
     */
    constructor () {}

    /**
     * @notice Deploy new Collection
     * @param _owner Owner of the new collection contract.
     * @param _name Name of the new collection contract
     * @param _symbol Symbol of the new collection contract
     * @param _baseURI Prefix of the token URI
    */
    function deployCollection(address _owner, string memory _name, string memory _symbol, string memory _baseURI) external onlyOwner {

        Collection collection = new Collection(_name, _symbol);
        collection.setBaseURI(_baseURI);
        collection.transferOwnership(_owner);

        collections[collectionsCounter] = address(collection);
        collectionsCounter += 1;

        emit NewCollection(address(collection), _owner, collectionsCounter - 1);
    }
}
