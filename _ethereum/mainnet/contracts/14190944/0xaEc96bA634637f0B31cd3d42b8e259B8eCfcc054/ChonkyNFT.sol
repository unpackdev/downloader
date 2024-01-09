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
    event Reveal(uint256 offset);

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
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        require(l.offset == 0, "Already revealed");

        requestId = requestRandomness(VRF_KEY_HASH, VRF_FEE);

        emit RevealInitiated(requestId);
    }

    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        // Set  offset, which reveals the NFTs
        l.offset = (randomness % (MAX_ELEMENTS - RESERVED_AMOUNT)) + 1; // We add 1 to ensure offset is not 0 (unrevealed)

        emit Reveal(l.offset);
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

    function _getGenomeId(uint256 _tokenId) internal view returns (uint256) {
        ChonkyNFTStorage.Layout storage l = ChonkyNFTStorage.layout();

        // 10000 = Unrevealed
        uint256 finalId = 10000;

        if (_tokenId < RESERVED_AMOUNT) {
            finalId = _tokenId;
        } else if (l.offset > 0) {
            finalId =
                ((_tokenId + l.offset) % (MAX_ELEMENTS - RESERVED_AMOUNT)) +
                RESERVED_AMOUNT;
        }

        return finalId;
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

    function getOffset() external view returns (uint256) {
        return ChonkyNFTStorage.layout().offset;
    }
}
