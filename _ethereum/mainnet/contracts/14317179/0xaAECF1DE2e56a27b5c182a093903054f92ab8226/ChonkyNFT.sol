// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721BaseStorage.sol";
import "./OwnableInternal.sol";

import "./VRFConsumerBase.sol";

import "./ChonkyGenomeLib.sol";
import "./ChonkyMetadata.sol";
import "./ChonkyNFTStorage.sol";
import "./IChonkyNFT.sol";

contract ChonkyNFT is IChonkyNFT, ERC721, VRFConsumerBase, OwnableInternal {
    using ERC721BaseStorage for ERC721BaseStorage.Layout;

    uint256 internal constant MAX_ELEMENTS = 7777;

    // Price per unit if buying < AMOUNT_DISCOUNT_ONE
    uint256 internal constant PRICE = 70 * 10**15;
    // Price per unit if buying >= AMOUNT_DISCOUNT_ONE
    uint256 internal constant PRICE_DISCOUNT_ONE = 65 * 10**15;
    // Price per unit if buying MAX_AMOUNT
    uint256 internal constant PRICE_DISCOUNT_MAX = 60 * 10**15;

    uint256 internal constant AMOUNT_DISCOUNT_ONE = 10;
    uint256 internal constant MAX_AMOUNT = 20;

    uint256 internal constant RESERVED_AMOUNT = 16;

    uint256 internal constant BITS_PER_GENOME = 58;

    string internal constant CID =
        "QmdafmnRuwqdnYGpVstF6raAqW64AD4i4maDAyvbeVDTGe";

    // Chainlink VRF
    bytes32 private immutable VRF_KEY_HASH;
    uint256 private immutable VRF_FEE;

    event CreateChonky(uint256 indexed id);
    event RevealInitiated(bytes32 indexed requestId);
    event Reveal(
        uint256 indexed startId,
        uint256 indexed endId,
        uint256 indexed offset
    );

    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _vrfKeyHash,
        uint256 _vrfFee
    ) VRFConsumerBase(_vrfCoordinator, _link) {
        VRF_KEY_HASH = _vrfKeyHash;
        VRF_FEE = _vrfFee;
    }

    function mintReserved(uint256 amount) external onlyOwner {
        // Mint reserved chonky
        for (uint256 i = 0; i < amount; i++) {
            _mintChonky(msg.sender);
        }
    }

    function setStartTimestamp(uint256 timestamp) external onlyOwner {
        ChonkyNFTStorage.layout().startTimestamp = timestamp;
    }

    function reveal() external onlyOwner returns (bytes32 requestId) {
        requestId = requestRandomness(VRF_KEY_HASH, VRF_FEE);

        emit RevealInitiated(requestId);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 startId = _getRevealStartId();
        require(startId < MAX_ELEMENTS, "Reveal already completed");
        require(l.currentId >= startId, "No new mint to reveal");

        uint256 offset = (randomness % (MAX_ELEMENTS - RESERVED_AMOUNT));

        _reveal(l, startId, offset);
    }

    function _reveal(
        ChonkyNFTStorage.Layout storage l,
        uint256 startId,
        uint256 baseOffset
    ) internal {
        // If first reveal, we dont need to check for range collisions
        if (l.revealRanges.length == 0) {
            l.revealRanges.push(
                ChonkyNFTStorage.RevealRange(startId, l.currentId, baseOffset)
            );

            emit Reveal(startId, l.currentId, baseOffset);

            return;
        }

        uint256 offset = _checkStartRangeCollision(l, startId, baseOffset);
        uint256 endId = _checkEndRangeCollision(
            l,
            startId,
            offset,
            l.currentId
        );

        l.revealRanges.push(
            ChonkyNFTStorage.RevealRange(startId, endId, offset)
        );

        emit Reveal(startId, endId, offset);

        if (endId != l.currentId) {
            // If there was a collision, we calculate the next range
            _reveal(l, endId + 1, baseOffset);
        }
    }

    function _checkStartRangeCollision(
        ChonkyNFTStorage.Layout storage l,
        uint256 _startId,
        uint256 _initialOffset
    ) internal returns (uint256 offset) {
        offset = _initialOffset;
        uint256 newRangeStartId = _applyOffset(_startId, _initialOffset);

        for (uint256 i = 0; i < l.revealRanges.length; i++) {
            ChonkyNFTStorage.RevealRange memory range = l.revealRanges[i];
            uint256 rangeStart = _applyOffset(range.startId, range.offset);
            uint256 rangeEnd = _applyOffset(range.endId, range.offset);

            if (rangeStart > rangeEnd) {
                if (newRangeStartId <= rangeEnd) {
                    offset += (rangeEnd - newRangeStartId) + 1;
                    return _checkStartRangeCollision(l, _startId, offset);
                } else if (
                    newRangeStartId >= rangeStart &&
                    newRangeStartId <= MAX_ELEMENTS
                ) {
                    offset +=
                        (rangeEnd - RESERVED_AMOUNT) +
                        (MAX_ELEMENTS - newRangeStartId) +
                        1;
                    return _checkStartRangeCollision(l, _startId, offset);
                }
            } else {
                if (
                    newRangeStartId >= rangeStart && newRangeStartId <= rangeEnd
                ) {
                    offset += (rangeEnd - newRangeStartId) + 1;
                    return _checkStartRangeCollision(l, _startId, offset);
                }
            }
        }

        return _initialOffset;
    }

    function _checkEndRangeCollision(
        ChonkyNFTStorage.Layout storage l,
        uint256 _startId,
        uint256 _offset,
        uint256 _initialEndId
    ) internal view returns (uint256 endId) {
        uint256 startIdWithOffset = _applyOffset(_startId, _offset);
        uint256 endIdWithOffset = _applyOffset(_initialEndId, _offset);

        uint256 collisionDistance;

        for (uint256 i = 0; i < l.revealRanges.length; i++) {
            ChonkyNFTStorage.RevealRange memory range = l.revealRanges[i];
            uint256 rangeStart = _applyOffset(range.startId, range.offset);

            uint256 distance;
            if (endIdWithOffset < startIdWithOffset) {
                if (
                    rangeStart > startIdWithOffset && rangeStart <= MAX_ELEMENTS
                ) {
                    distance =
                        (endIdWithOffset - RESERVED_AMOUNT) +
                        (MAX_ELEMENTS - rangeStart) +
                        1;
                } else if (rangeStart < endIdWithOffset) {
                    distance = (endIdWithOffset - rangeStart) + 1;
                }
            } else {
                if (
                    rangeStart > startIdWithOffset &&
                    rangeStart <= endIdWithOffset
                ) {
                    distance = (endIdWithOffset - rangeStart) + 1;
                }
            }

            if (distance > 0 && distance > collisionDistance) {
                collisionDistance = distance;
            }
        }

        if (collisionDistance == 0) return _initialEndId;

        return _initialEndId - collisionDistance;
    }

    function _applyOffset(uint256 _tokenId, uint256 _offset)
        internal
        pure
        returns (uint256)
    {
        return
            ((_tokenId + _offset) % (MAX_ELEMENTS - RESERVED_AMOUNT)) +
            RESERVED_AMOUNT;
    }

    function _getRevealStartId() internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 rangesAmount = l.revealRanges.length;
        if (rangesAmount == 0) return RESERVED_AMOUNT;

        return l.revealRanges[rangesAmount - 1].endId + 1;
    }

    function mint() external payable {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        require(
            l.startTimestamp > 0 && block.timestamp > l.startTimestamp,
            "Minting not started"
        );
        require(l.currentId < MAX_ELEMENTS, "Sale ended");
        require(msg.value <= MAX_AMOUNT * PRICE_DISCOUNT_MAX, "> Max amount");

        uint256 count;
        if (msg.value >= MAX_AMOUNT * PRICE_DISCOUNT_MAX) {
            count = MAX_AMOUNT;
        } else if (msg.value >= PRICE_DISCOUNT_ONE * AMOUNT_DISCOUNT_ONE) {
            count = msg.value / PRICE_DISCOUNT_ONE;
        } else {
            count = msg.value / PRICE;
        }

        require(l.currentId + count <= MAX_ELEMENTS, "Max limit");

        for (uint256 i = 0; i < count; i++) {
            _mintChonky(msg.sender);
        }
    }

    function _mintChonky(address _to) private {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 id = l.currentId;
        _safeMint(_to, id);
        l.currentId += 1;
        emit CreateChonky(id);
    }

    function withdraw(address[] memory _addresses, uint256[] memory _amounts)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _withdraw(_addresses[i], _amounts[i]);
        }
    }

    function parseGenome(uint256 _genome)
        external
        pure
        returns (uint256[12] memory result)
    {
        return ChonkyGenomeLib.parseGenome(_genome);
    }

    function formatGenome(uint256[12] memory _attributes)
        external
        pure
        returns (uint256 genome)
    {
        return ChonkyGenomeLib.formatGenome(_attributes);
    }

    function getGenome(uint256 _id) external view returns (uint256) {
        return _getGenome(_id);
    }

    function _getGenome(uint256 _id) internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 startBit = BITS_PER_GENOME * _id;
        uint256 genomeIndex = startBit / 256;

        uint256 genome = l.genomes[genomeIndex] >> (startBit % 256);

        if ((startBit % 256) + BITS_PER_GENOME <= 256) {
            uint256 mask = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff >>
                    (256 - BITS_PER_GENOME);
            genome &= mask;
        } else {
            uint256 remainingBits = 256 - (startBit % 256);
            uint256 missingBits = BITS_PER_GENOME - remainingBits;
            uint256 genomeNext = (l.genomes[genomeIndex + 1] <<
                (256 - missingBits)) >> (256 - missingBits - remainingBits);

            genome += genomeNext;
        }

        return genome;
    }

    function addPackedGenomes(uint256[] memory _genomes) external onlyOwner {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        for (uint256 i = 0; i < _genomes.length; i++) {
            l.genomes.push(_genomes[i]);
        }
    }

    function setPackedGenomes(uint256[] memory _ids, uint256[] memory _genomes)
        external
        onlyOwner
    {
        require(_ids.length == _genomes.length, "Invalid arrays length");

        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        for (uint256 i = 0; i < _genomes.length; i++) {
            l.genomes[_ids[i]] = _genomes[i];
        }
    }

    function _getGenomeId(uint256 _tokenId) internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        // Honoraries
        if (_tokenId < RESERVED_AMOUNT) return _tokenId;

        for (uint256 i = 0; i < l.revealRanges.length; i++) {
            if (_tokenId <= l.revealRanges[i].endId) {
                return _applyOffset(_tokenId, l.revealRanges[i].offset);
            }
        }

        // 10000 = Unrevealed
        return 10000;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            ERC721BaseStorage.layout().exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        uint256 genomeId = _getGenomeId(_tokenId);
        return
            ChonkyMetadata(l.chonkyMetadata).buildTokenURI(
                _tokenId,
                genomeId,
                genomeId == 10000 ? 0 : _getGenome(genomeId),
                CID,
                l.chonkyAttributes,
                l.chonkySet
            );
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function getChonkyAttributesAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkyAttributes;
    }

    function getChonkyMetadataAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkyMetadata;
    }

    function getChonkySetAddress() external view returns (address) {
        return ChonkyNFTStorage.layout().chonkySet;
    }

    function getCID() external pure returns (string memory) {
        return CID;
    }

    function getStartTimestamp() external view returns (uint256) {
        return ChonkyNFTStorage.layout().startTimestamp;
    }
}
