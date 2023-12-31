//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./INameWrapper.sol";
import "./DataTypes.sol";
import "./Controllable.sol";

contract NameRegistry is Controllable {
    mapping(bytes32 => DomainListingDetails) public listingDetails;

    event NameListed(
        bytes32 indexed node,
        uint256 basePrice,
        Pricing[] subnamePrices,
        uint256 deadline
    );

    event NamesListed(
        bytes32[] indexed nodes,
        uint256[] basePrices,
        Pricing[][] subnamePrices,
        uint256[] deadlines
    );

    event NameUnlisted(bytes32 indexed node);

    event NamesUnlisted(bytes32[] indexed nodes);

    function addListing(
        bytes32 node,
        DomainListingDetails calldata config
    ) external {
        _addListing(node, config);

        emit NameListed(node, config.basePrice, config.prices, config.deadline);
    }

    function addListings(
        bytes32[] calldata nodes,
        DomainListingDetails[] calldata config
    ) external {
        uint256[] memory basePrices = new uint256[](nodes.length);
        Pricing[][] memory prices = new Pricing[][](nodes.length);
        uint256[] memory deadlines = new uint256[](nodes.length);

        for (uint i = 0; i < nodes.length; i++) {
            _addListing(nodes[i], config[i]);
            prices[i] = config[i].prices;
            deadlines[i] = config[i].deadline;
            basePrices[i] = config[i].basePrice;
        }

        emit NamesListed(nodes, basePrices, prices, deadlines);
    }

    function _addListing(
        bytes32 node,
        DomainListingDetails calldata config
    ) private onlyController {
        listingDetails[node] = config;
    }

    function removeListing(bytes32 node) external {
        _removeListing(node);

        emit NameUnlisted(node);
    }

    function removeListings(bytes32[] calldata nodes) external {
        for (uint i = 0; i < nodes.length; i++) {
            _removeListing(nodes[i]);
        }

        emit NamesUnlisted(nodes);
    }

    function _removeListing(bytes32 node) private onlyController {
        delete listingDetails[node];
    }

    function getListing(
        bytes32 node
    ) external view returns (DomainListingDetails memory) {
        return listingDetails[node];
    }

    function getListings(
        bytes32[] memory nodes
    ) external view returns (DomainListingDetails[] memory listings) {
        listings = new DomainListingDetails[](nodes.length);

        for (uint256 i = 0; i < nodes.length; i++) {
            listings[i] = listingDetails[nodes[i]];
        }
    }
}
