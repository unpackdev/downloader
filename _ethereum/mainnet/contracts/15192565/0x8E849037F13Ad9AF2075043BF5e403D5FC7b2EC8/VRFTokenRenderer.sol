// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ITokenRenderer.sol";

contract VRFTokenRenderer is VRFConsumerBaseV2, Ownable, ITokenRenderer {
    using Strings for uint256;
    string private _defaultTokenURI;
    string private _baseURI;

    VRFCoordinatorV2Interface immutable COORDINATOR;

    uint64 immutable _subscriptionId;
    bytes32 immutable _keyHash;

    uint32 constant CALLBACK_GAS_LIMIT = 100000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 1;

    bool private _entropyRequested;
    bool private _entropyReceived;
    uint256 private _entropy;

    uint256 constant COLLECTION_SIZE = 7777;

    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        _keyHash = keyHash;
        _subscriptionId = subscriptionId;
    }

    function requestEntropy() external onlyOwner {
        require(!_entropyRequested, "Already requested entropy");
        _entropyRequested = true;
        COORDINATOR.requestRandomWords(_keyHash, _subscriptionId, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, NUM_WORDS);
    }

    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        _entropyReceived = true;
        _entropy = randomWords[0];
    }

    function setDefaultTokenURI(string memory newURI) external onlyOwner {
        _defaultTokenURI = newURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId, bytes32) public view virtual override returns (string memory) {
        if (_entropyReceived && bytes(_baseURI).length > 0) {
            return string(abi.encodePacked(_baseURI, _metadataId(tokenId)));
        } else {
            return _defaultTokenURI;
        }
    }

    function _metadataId(uint256 tokenId) internal view virtual returns (string memory) {
        uint256 offset = _entropy % COLLECTION_SIZE;
        uint256 hashedId = uint256(keccak256(abi.encodePacked((tokenId + offset) % COLLECTION_SIZE)));
        return hashedId.toHexString();
    }
}
