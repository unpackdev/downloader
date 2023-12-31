//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./DataTypes.sol";
import "./Controllable.sol";

contract ReservedRegistry is Controllable {
    mapping(bytes32 => uint256[]) public versions;
    mapping(bytes32 => mapping(bytes32 => ReservedListingDetails))
        public reservedListings;

    struct ReservedListingDetails {
        uint256 price;
        uint256 version;
    }

    event ReservedSubnamesListed(
        bytes32 indexed parentNode,
        ReservedListing[] listings
    );

    event BulkReservedSubnamesListed(
        bytes32[] indexed parentNodes,
        ReservedListing[][] listings
    );

    event ReservedSubnameRemoved(bytes32 indexed parentNode, string label);

    event ReservedSubnamesRemoved(bytes32 indexed parentNode, string[] labels);

    event BulkReservedSubnamesRemoved(
        bytes32[] indexed parentNodes,
        string[][] labels
    );

    event ReservedSubnameDelisted(bytes32 indexed parentNode);

    event UpdatedNode(bytes32 indexed node, ReservedListing[] listings);

    event UpdatedNodes(bytes32[] indexed nodes, ReservedListing[][] listings);

    /**
     * Updates the resereved lables for the provided nodes.
     *
     * @param nodes Parent nodes that have name reservations
     * @param newReservations New reservation data
     */
    function bulkUpdate(
        bytes32[] calldata nodes,
        ReservedListing[][] calldata newReservations
    ) external {
        bulkReserve(nodes, newReservations);
        emit UpdatedNodes(nodes, newReservations);
    }

    function update(
        bytes32 node,
        ReservedListing[] calldata newReservations
    ) external {
        _reserve(node, newReservations);
        emit UpdatedNode(node, newReservations);
    }

    function reserve(
        bytes32 node,
        ReservedListing[] calldata reservations
    ) external {
        _reserve(node, reservations);

        emit ReservedSubnamesListed(node, reservations);
    }

    function bulkReserve(
        bytes32[] calldata nodes,
        ReservedListing[][] calldata reservations
    ) public {
        for (uint256 i = 0; i < nodes.length; i++) {
            _reserve(nodes[i], reservations[i]);
        }

        emit BulkReservedSubnamesListed(nodes, reservations);
    }

    function _reserve(
        bytes32 node,
        ReservedListing[] calldata reservations
    ) private onlyController {
        uint256 version = versions[node].length + 1;

        for (uint256 i = 0; i < reservations.length; i++) {
            reservedListings[node][
                keccak256(bytes(reservations[i].label))
            ] = ReservedListingDetails(reservations[i].price, version);
        }

        versions[node].push(version);
    }

    /**
     * @notice Removes single label from node.
     *
     * @param node Parent node with label reservations
     * @param label Label to be removed
     */
    function remove(bytes32 node, string calldata label) external {
        _remove(node, label);

        emit ReservedSubnameRemoved(node, label);
    }

    /**
     * @notice Removes labels from the node.
     *
     * @param node Parent node with label reservations
     * @param labels Labels to be removed
     */
    function remove(bytes32 node, string[] calldata labels) public {
        for (uint i = 0; i < labels.length; i++) {
            _remove(node, labels[i]);
        }

        emit ReservedSubnamesRemoved(node, labels);
    }

    /**
     * @notice Removes multiple label from the provided nodes.
     *
     * @param nodes Parent nodes with label reservations
     * @param labels Labels to be removed for each provided node
     */
    function remove(
        bytes32[] calldata nodes,
        string[][] calldata labels
    ) public {
        for (uint i = 0; i < nodes.length; i++) {
            for (uint j = 0; j < labels.length; j++) {
                _remove(nodes[i], labels[i][j]);
            }
        }

        emit BulkReservedSubnamesRemoved(nodes, labels);
    }

    function _remove(
        bytes32 node,
        string calldata label
    ) private onlyController {
        delete reservedListings[node][keccak256(bytes(label))];
    }

    function getReservedDetails(
        bytes32 parentNode,
        bytes32 labelHash
    ) external view returns (bool reserved, uint256 price) {
        uint256 currentVersion = versions[parentNode].length;
        ReservedListingDetails memory listing = reservedListings[parentNode][
            labelHash
        ];

        price = listing.price;
        reserved = listing.version > 0 && listing.version == currentVersion;
    }

    function getVersions(
        bytes32 node
    ) external view returns (uint256[] memory) {
        return versions[node];
    }
}
