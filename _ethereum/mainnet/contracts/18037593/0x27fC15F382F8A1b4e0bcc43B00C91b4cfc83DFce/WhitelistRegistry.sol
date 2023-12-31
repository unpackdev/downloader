//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./DataTypes.sol";
import "./Controllable.sol";

contract WhitelistRegistry is Controllable {
    mapping(bytes32 => mapping(address => uint256)) public whitelists;
    mapping(bytes32 => uint256[]) public versions;
    mapping(bytes32 => uint8) public whitelistTypes;

    event WhitelistingsAdded(
        bytes32 indexed parentNode,
        address[] whitelistings,
        uint8 whitelistType
    );

    event BulkWhitelistingsAdded(
        bytes32[] indexed parentNodes,
        address[][] whitelistings,
        uint8[] whitelistTypes
    );

    event WhitelistClaimed(bytes32 indexed parentNode, address claimer);

    event RemovedFromWhitelist(bytes32 indexed parentNode, address removed);

    event BulkRemovedFromWhitelist(
        bytes32[] indexed parentNodes,
        address[][] removed
    );

    event UpdatedWhitelisting(bytes32 indexed node, address[] whitelist);

    event UpdatedWhitelistings(bytes32[] indexed nodes, address[][] whitelists);

    event UpdatedWhitelistingType(bytes32 indexed node, uint8 wlType);

    event UpdatedWhitelistingTypes(bytes32[] indexed nodes, uint8[] wlTypes);

    function isWhitelisted(
        bytes32 node,
        address claimer
    ) external view returns (bool) {
        uint256 wlVersion = versions[node].length;
        uint256 version = whitelists[node][claimer];
        return wlVersion > 0 && wlVersion == version;
    }

    function update(
        bytes32 node,
        address[] calldata newWhitelistings
    ) external {
        _update(node, newWhitelistings);
        emit UpdatedWhitelisting(node, newWhitelistings);
    }

    function update(
        bytes32[] calldata nodes,
        address[][] calldata newWhitelistings
    ) external {
        for (uint i = 0; i < nodes.length; i++) {
            _update(nodes[i], newWhitelistings[i]);
        }
        emit UpdatedWhitelistings(nodes, newWhitelistings);
    }

    function _update(
        bytes32 node,
        address[] calldata newWhitelistings
    ) private {
        uint256 version = versions[node].length + 1;
        _setWhitelisting(node, newWhitelistings, version);
    }

    function updateWhitelistTypes(
        bytes32[] calldata nodes,
        uint8[] calldata types
    ) external onlyController {
        for (uint i = 0; i < nodes.length; i++) {
            whitelistTypes[nodes[i]] = types[i];
        }
        emit UpdatedWhitelistingTypes(nodes, types);
    }

    function updateWhitelistType(
        bytes32 node,
        uint8 whitelistType
    ) external onlyController {
        whitelistTypes[node] = whitelistType;
        emit UpdatedWhitelistingType(node, whitelistType);
    }

    function addWhitelisting(
        bytes32 node,
        address[] calldata whitelisted,
        uint8 whitelistType
    ) external {
        _addWhitelisting(node, whitelisted, whitelistType);
        emit WhitelistingsAdded(node, whitelisted, whitelistType);
    }

    function addWhitelistings(
        bytes32[] calldata nodes,
        address[][] calldata whitelisted,
        uint8[] calldata types
    ) external {
        for (uint i = 0; i < nodes.length; i++) {
            _addWhitelisting(nodes[i], whitelisted[i], types[i]);
        }
        emit BulkWhitelistingsAdded(nodes, whitelisted, types);
    }

    function _addWhitelisting(
        bytes32 node,
        address[] calldata whitelisted,
        uint8 whitelistType
    ) private {
        uint256 version = versions[node].length + 1;
        _setWhitelisting(node, whitelisted, version);
        whitelistTypes[node] = whitelistType;
    }

    function _setWhitelisting(
        bytes32 node,
        address[] calldata whitelisted,
        uint256 version
    ) private onlyController {
        for (uint i = 0; i < whitelisted.length; i++) {
            address wl = whitelisted[i];
            whitelists[node][wl] = version;
        }

        versions[node].push(version);
    }

    function claim(bytes32 node, address claimer) external {
        _remove(node, claimer);

        emit WhitelistClaimed(node, claimer);
    }

    function remove(bytes32 node, address claimer) public {
        _remove(node, claimer);

        emit RemovedFromWhitelist(node, claimer);
    }

    function remove(
        bytes32[] calldata nodes,
        address[][] calldata addresses
    ) public {
        for (uint i = 0; i < nodes.length; i++) {
            for (uint j = 0; j < addresses[i].length; j++) {
                _remove(nodes[i], addresses[i][j]);
            }
        }

        emit BulkRemovedFromWhitelist(nodes, addresses);
    }

    function _remove(bytes32 node, address claimer) private onlyController {
        delete whitelists[node][claimer];
    }

    function getVersions(
        bytes32 node
    ) external view returns (uint256[] memory) {
        return versions[node];
    }
}
