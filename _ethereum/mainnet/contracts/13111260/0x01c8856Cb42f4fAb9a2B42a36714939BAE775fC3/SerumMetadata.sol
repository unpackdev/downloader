// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";

contract SerumMetadata is Ownable, VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint16 public constant COLLECTION_SIZE = 10000;

    uint256 public collectionStartingIndex;
    uint8[COLLECTION_SIZE] public serumTypes;

    event SerumTypeMetadataLoaded(
        uint256 indexed _fromIndex,
        uint256 indexed _numItems
    );
    event StartingIndexSet(uint256 indexed _startingIndex);

    constructor(
        address vrfCoordinator,
        address linkTokenAddress,
        bytes32 _keyHash
    ) VRFConsumerBase(vrfCoordinator, linkTokenAddress) {
        keyHash = _keyHash;
        fee = 2 * 10**18;
    }

    function loadSerumMetadata(uint8[] memory types, uint256 offset)
        external
        onlyOwner
    {
        for (uint256 i; i < types.length; i++) {
            uint256 idx = i + offset;
            serumTypes[idx] = types[i];
        }

        emit SerumTypeMetadataLoaded(offset, types.length);
    }

    function computeOriginalSequenceId(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return (tokenId + collectionStartingIndex) % COLLECTION_SIZE;
    }

    function getSerumTypeById(uint256 tokenId) external view returns (uint8) {
        uint256 originalSeqId = computeOriginalSequenceId(tokenId);
        return serumTypes[originalSeqId];
    }

    function requestRandomnessForStartingIndex()
        public
        onlyOwner
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        require(
            collectionStartingIndex == 0,
            "Metadata starting index already set"
        );

        collectionStartingIndex = (randomness % COLLECTION_SIZE);

        if (collectionStartingIndex == 0) {
            collectionStartingIndex++;
        }

        emit StartingIndexSet(collectionStartingIndex);
    }
}
