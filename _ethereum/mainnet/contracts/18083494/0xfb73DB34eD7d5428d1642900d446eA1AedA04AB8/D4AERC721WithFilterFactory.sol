// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ClonesUpgradeable.sol";

import "./ID4AERC721Factory.sol";
import "./PDERC721WithFilter.sol";

contract D4AERC721WithFilterFactory is ID4AERC721Factory {
    using ClonesUpgradeable for address;

    PDERC721WithFilter impl;

    event NewD4AERC721WithFilter(address addr);

    constructor() {
        impl = new PDERC721WithFilter();
    }

    function createD4AERC721(
        string memory _name,
        string memory _symbol,
        uint256 startTokenId
    )
        public
        returns (address)
    {
        address t = address(impl).clone();
        PDERC721WithFilter(t).initialize(_name, _symbol, startTokenId);
        PDERC721WithFilter(t).changeAdmin(msg.sender);
        PDERC721WithFilter(t).transferOwnership(msg.sender);
        emit NewD4AERC721WithFilter(t);
        return t;
    }
}
