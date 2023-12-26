// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SSTORE2.sol";
import "./ECDSA.sol";

import "./LibString.sol";
import "./Base64.sol";

import "./LeetCollectiveGuarded.sol";
import "./LeetERC721.sol";

/**
 * @title Claim your achievements within 1337 ecosystem
 * @author hoanh.eth
 * @author snjolfur.eth
 */
contract Achievements is ERC721L, LeetCollectiveGuarded {
    bool public isOpen;
    bool public useExternalURI;
    string public externalURI;

    using ECDSA for bytes32;

    address private _offchainSigner;
    mapping(bytes32 => bool) private _claimed;
    Achievement[] private _achievements;
    uint256[] private _tokens;

    error AlreadyClaimed();
    error ClaimClosed();
    error InvalidExternalURI();
    error InvalidPayload();
    error InvalidOffchainSigner();
    error TraitsMustBePairs();

    struct Achievement {
        address image;
        string name;
        string description;
        string[] traits;
    }

    constructor(string memory name, string memory symbol, address collective)
        ERC721L(name, symbol, "Achievements within the 1337 ecosystem")
        LeetCollectiveGuarded(collective)
    {}

    function toggleClaim() external serOrOwner {
        isOpen = !isOpen;
    }

    function toggleExternalURI() external serOrOwner {
        useExternalURI = !useExternalURI;
    }

    function setOffchainSigner(address addr) external serOrOwner {
        _offchainSigner = addr;
    }

    function setExternalURI(string memory url) external serOrOwner {
        externalURI = url;
    }

    function hasClaim(address addr, uint256 achievementID) public view returns (bool) {
        bytes32 msgHash = keccak256(abi.encodePacked(addr, achievementID));
        return _claimed[msgHash];
    }

    function add(bytes memory image, string memory name, string memory description, string[] calldata traits)
        public
        serOrOwner
    {
        if (traits.length % 2 != 0) revert TraitsMustBePairs();
        Achievement memory achievement;
        achievement.image = SSTORE2.write(image);
        achievement.name = name;
        achievement.description = description;
        achievement.traits = traits;

        _achievements.push(achievement);
    }

    function change(
        uint256 achievementID,
        bytes calldata image,
        string calldata name,
        string calldata description,
        string[] calldata traits
    ) external serOrOwner {
        if (traits.length % 2 != 0) revert TraitsMustBePairs();

        Achievement memory old = _achievements[achievementID];
        bytes memory existing = SSTORE2.read(old.image);
        if (_isDifferent(existing, image)) {
            _achievements[achievementID].image = SSTORE2.write(image);
        }
        if (_isDifferent(bytes(old.name), bytes(name))) {
            _achievements[achievementID].name = name;
        }
        if (_isDifferent(bytes(old.description), bytes(description))) {
            _achievements[achievementID].description = description;
        }

        while (_achievements[achievementID].traits.length > traits.length) {
            // Remove traits from existing list if the new trait list is shorter
            _achievements[achievementID].traits.pop();
        }

        uint256 i = 0;
        while (i < _achievements[achievementID].traits.length) {
            // Set the new keys and values if they changed of slots that already exist
            if (_isDifferent(bytes(_achievements[achievementID].traits[i]), bytes(traits[i]))) {
                _achievements[achievementID].traits[i] = traits[i];
            }
            if (_isDifferent(bytes(_achievements[achievementID].traits[i + 1]), bytes(traits[i + 1]))) {
                _achievements[achievementID].traits[i + 1] = traits[i + 1];
            }

            i = i + 2;
        }

        while (i < traits.length) {
            // Add new traits if the new trait list is longer
            _achievements[achievementID].traits.push(traits[i]);
            _achievements[achievementID].traits.push(traits[i + 1]);
            i = i + 2;
        }
    }

    function _isDifferent(bytes memory a, bytes memory b) internal pure returns (bool) {
        return a.length != b.length || keccak256(a) != keccak256(b);
    }

    function achievementsCount() external view returns (uint256) {
        return _achievements.length;
    }

    function getAchievements(uint256 offset, uint256 count) external view returns (string memory) {
        if (offset >= _achievements.length) revert IndexOutOfBounds();
        if (offset + count > _achievements.length) revert IndexOutOfBounds();

        string memory json = "[";
        string memory image;
        string memory attributes;
        uint256 j;
        uint256 i = offset;

        unchecked {
            uint256 end = offset + count;
            while (i < end) {
                Achievement memory achievement = _achievements[i];

                image = _getImage(achievement.image);
                attributes = "";
                j = 0;
                while (j < achievement.traits.length) {
                    if (keccak256(abi.encodePacked(achievement.traits[j])) != keccak256(abi.encodePacked(""))) {
                        attributes = string.concat(
                            attributes, _buildMetadata(achievement.traits[j], achievement.traits[j + 1]), ","
                        );
                    }
                    j = j + 2;
                }
                attributes = string.concat(attributes, _buildMetadata("name", achievement.name));

                string memory achievementJson = string.concat(
                    '{"name": "',
                    achievement.name,
                    '", "id":',
                    LibString.toString(i),
                    ', "description":"',
                    achievement.description,
                    '","image":"data:image/svg+xml;base64,',
                    image,
                    '","attributes": [',
                    attributes,
                    "]}"
                );

                json = string.concat(json, achievementJson);
                if (i != end - 1) {
                    json = string.concat(json, ",");
                }

                ++i;
            }
        }

        json = string.concat(json, "]");
        return json;
    }

    function claim(uint256 achievementID, bytes memory signature) public {
        if (!isOpen) revert ClaimClosed();
        if (!_isValidPayload(achievementID, signature)) revert InvalidPayload();
        if (_achievements.length <= achievementID) revert IndexOutOfBounds();

        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, achievementID));
        if (_claimed[msgHash]) revert AlreadyClaimed();
        _claimed[msgHash] = true;

        _tokens.push(achievementID);
        _mint(msg.sender);
    }

    function tokenURI(uint256 tokenID) public view virtual override(IERC721Metadata) returns (string memory) {
        if (!_exists(tokenID)) revert TokenDoesNotExist();

        Achievement memory achievement = _achievements[_tokens[tokenID]];
        string memory image = _getImage(achievement.image);
        string memory animationURL = string.concat('"data:image/svg+xml;base64,', image, '",');
        if (useExternalURI) {
            if (bytes(externalURI).length == 0) revert InvalidExternalURI();
            animationURL = string.concat('"', externalURI, LibString.toString(tokenID), '",');
        }

        string memory attributes = "";
        uint256 i = 0;
        while (i < achievement.traits.length) {
            if (keccak256(abi.encodePacked(achievement.traits[i])) != keccak256(abi.encodePacked(""))) {
                attributes =
                    string.concat(attributes, _buildMetadata(achievement.traits[i], achievement.traits[i + 1]), ",");
            }
            i = i + 2;
        }
        attributes = string.concat(attributes, _buildMetadata("name", achievement.name));

        bytes memory json = abi.encodePacked(
            '{"name": "',
            achievement.name,
            '", "description":"',
            achievement.description,
            '","image":"data:image/svg+xml;base64,',
            image,
            '","animation_url":',
            animationURL,
            '"attributes": [',
            attributes,
            "]}"
        );

        return string(abi.encodePacked("data:application/json,", json));
    }

    function _getImage(address image) internal view returns (string memory) {
        return Base64.encode(
            abi.encodePacked(
                '<svg width="100%" height="100%" viewBox="0 0 20000 20000" xmlns="http://www.w3.org/2000/svg">',
                "<style>svg{background-color:transparent;background-image:url(data:image/png;base64,",
                Base64.encode(SSTORE2.read(image)),
                ");background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;}</style></svg>"
            )
        );
    }

    function _isValidPayload(uint256 tokenID, bytes memory signature) internal view returns (bool) {
        if (_offchainSigner == address(0)) {
            revert InvalidOffchainSigner();
        }

        bytes32 msgHash = keccak256(abi.encodePacked(msg.sender, tokenID));
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        return signedHash.recover(signature) == _offchainSigner;
    }
}
