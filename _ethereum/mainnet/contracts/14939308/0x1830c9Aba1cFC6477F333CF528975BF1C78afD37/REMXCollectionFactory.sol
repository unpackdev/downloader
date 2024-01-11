//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "./Context.sol";
import "./Clones.sol";
import "./IREMXCollectionFactory.sol";
import "./REMXCollection.sol";

contract REMXCollectionFactory is IREMXCollectionFactory, Context {
    address immutable implementation;

    constructor() {
        implementation = address(new REMXCollection());
    }

    function createCollection(
        address _admin,
        address _minter,
        address revenueSplitter,
        string memory name,
        string memory symbol,
        uint256 royalty,
        string memory baseURI
    ) external override returns (address) {
        address clone = Clones.clone(implementation);
        REMXCollection collection = REMXCollection(payable(clone));
        collection.initialize(
            _admin,
            _minter,
            revenueSplitter,
            name,
            symbol,
            royalty,
            baseURI
        );
        return clone;
    }
}
