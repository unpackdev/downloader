// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ENS.sol";
import "./AddrResolver.sol";
import "./TextResolver.sol";
import "./Ownable.sol";

contract CitizenENSResolver is Ownable, AddrResolver, TextResolver {

    ENS public immutable _registry;

    constructor(ENS registry) {

        _registry = registry;

    }

    // Overrides.

    function isAuthorised(bytes32 node) internal override view returns(bool) {

        return owner() == msg.sender || _registry.owner(node) == msg.sender;

    }

    function supportsInterface(bytes4 interfaceID) virtual override(AddrResolver, TextResolver) public pure returns(bool) {

        return super.supportsInterface(interfaceID);

    }

}
