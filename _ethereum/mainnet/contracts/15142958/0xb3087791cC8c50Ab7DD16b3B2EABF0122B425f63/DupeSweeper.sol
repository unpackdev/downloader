// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./base64.sol";
    
import "./SSTORE2.sol";
import "./DynamicBuffer.sol";

import "./console.sol";
import "./ERC2981.sol";


library HelperLib {
    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

contract DupeSweeper is ERC721A, ReentrancyGuard, Ownable, ERC2981 {
    using HelperLib for uint256;
    using DynamicBuffer for bytes;

    struct TraitDTO {
        string name;
        string mimetype;
        bytes data;
    }
    
    struct Trait {
        string name;
        string mimetype;
    }

    struct ContractData {
        string name;
        string description;
        string image;
        string banner;
        string website;
        uint256 royalties;
        string royaltiesRecipient;
    }

    mapping(uint256 => address[]) internal _traitDataPointers;
    mapping(uint256 => mapping(uint256 => Trait)) internal _traitDetails;

    uint256 private constant NUM_LAYERS = 6;
    uint256 private constant MAX_BATCH_MINT = 20;
    uint256[][NUM_LAYERS] private TIERS;
    string[] private LAYER_NAMES = [unicode"Lasers", unicode"Mouth", unicode"Face", unicode"Head", unicode"Shirt", unicode"Background"];
    uint256 public constant maxTokens = 10000;
    uint public constant dupeCatcherRewardInTokens = 10;
    uint256 public constant mintPrice = 0.005 ether;
    // uint256 public constant mintPrice = 0;
    ContractData public contractData = ContractData(unicode"Dupe Sweeper", unicode"Help reach 10k unique Invisible Kevins by reporting duplicates and earning free mints!", "", "", "", 1000, "0xC2172a6315c1D7f6855768F843c420EbB36eDa97");

    constructor() ERC721A(unicode"Dupe Sweeper", unicode"SWEEP") {
    _setDefaultRoyalty(address(this), 1000);

            TIERS[0] = [25,250,250,500,500,500,7975];
TIERS[1] = [187,220,823,839,881,942,982,1082,1389,2655];
TIERS[2] = [108,137,415,576,635,769,929,957,1015,1280,1375,1804];
TIERS[3] = [37,98,135,207,210,301,364,504,803,935,1033,1071,1590,2712];
TIERS[4] = [23,92,102,117,127,202,225,404,555,577,602,631,641,711,906,938,3147];
TIERS[5] = [99,115,196,641,701,856,965,1246,1808,3373];
    }

    modifier whenPublicMintActive() {
        require(isPublicMintActive(), "Public sale not open");
        _;
    }

    function rarityGen(uint256 _randinput, uint256 _rarityTier)
        internal
        view
        returns (uint256)
    {
        uint256 currentLowerBound = 0;
        for (uint256 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint256 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return i;
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        if (from == address(0)) {
            uint256 randomNumber = uint256(
                keccak256(
                    abi.encodePacked(
                        tx.gasprice,
                        block.number,
                        block.timestamp,
                        block.difficulty,
                        blockhash(block.number - 1),
                        msg.sender
                    )
                )
            );
            return uint24(randomNumber);
        }
        return previousExtraData;
    }

    function getTokenSeed(uint256 _tokenId) internal view returns (uint24) {
        return _ownershipOf(_tokenId).extraData;
    }

    function tokenIdToHash(
        uint256 _tokenId
    ) public view returns (string memory) {
        require(_exists(_tokenId), "Invalid token");
        // This will generate a NUM_LAYERS * 3 character string.
        bytes memory hashBytes = DynamicBuffer.allocate(NUM_LAYERS * 4);

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 _randinput = uint256(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            getTokenSeed(_tokenId),
                            _tokenId,
                            _tokenId + i
                        )
                    )
                ) % maxTokens
            );

            uint256 rarity = rarityGen(_randinput, i);

            if (rarity < 10) {
                hashBytes.appendSafe("00");
            } else if (rarity < 100) {
                hashBytes.appendSafe("0");
            }
            if (rarity > 999) {
                hashBytes.appendSafe("999");
            } else {
                hashBytes.appendSafe(bytes(_toString(rarity)));
            }
        }

        return string(hashBytes);
    }
    
    function stringCompare(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    
    function tokensAreDuplicates(uint tokenId1, uint tokenId2) public view returns (bool) {
        return stringCompare(
            tokenIdToHash(tokenId1),
            tokenIdToHash(tokenId2)
        );
    }
    
    function sweepDupes(
        uint[] memory groupA,
        uint[] memory groupB
    ) public whenPublicMintActive {
        for (uint i; i < groupA.length; ++i) {
            uint tokenId1 = groupA[i];
            uint tokenId2 = groupB[i];
            
            require(tokensAreDuplicates(tokenId1, tokenId2), "All tokens must be duplicates");
            
            uint largerTokenId = tokenId1 > tokenId2 ? tokenId1 : tokenId2;
            
            _initializeOwnershipAt(largerTokenId);
            if (_exists(largerTokenId + 1)) {
                _initializeOwnershipAt(largerTokenId + 1);
            }
            
            uint24 newEntropy = uint24(uint(keccak256(abi.encodePacked(
                block.timestamp, blockhash(block.number - 1)
            ))));
            
            _setExtraDataAt(largerTokenId, newEntropy);
            
            mintToRecipient(msg.sender, dupeCatcherRewardInTokens);
            _setAux(msg.sender, _getAux(msg.sender) + 1);
        }
    }
    
    function numberOfDupesSweptByAddress(address _address) public view returns (uint) {
        return _getAux(_address);
    }
    
    function mint(uint256 _count) public nonReentrant payable returns (uint256) {
        return mintToRecipient(msg.sender, _count);
    }

    function mintToRecipient(address recipient, uint256 _count) internal whenPublicMintActive returns (uint256) {
        uint256 totalMinted = _totalMinted();
        require(_count > 0, "Invalid token count");
        require(totalMinted + _count <= maxTokens, "All tokens are gone");
        require(_count * mintPrice == msg.value, "Incorrect amount of ether sent");

        uint256 batchCount = _count / MAX_BATCH_MINT;
        uint256 remainder = _count % MAX_BATCH_MINT;

        for (uint256 i = 0; i < batchCount; i++) {
            _mint(recipient, MAX_BATCH_MINT);
        }

        if (remainder > 0) {
            _mint(recipient, remainder);
        }

        return totalMinted;
    }

    function isPublicMintActive() public view returns (bool) {
        return _totalMinted() < maxTokens;
    }

    function hashToSVG(string memory _hash)
        public
        view
        returns (string memory)
    {
        uint256 thisTraitIndex;
        
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        svgBytes.appendSafe('<svg width="1200" height="1200" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-image:url(');

        for (uint256 i = 0; i < NUM_LAYERS - 1; i++) {
            thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            svgBytes.appendSafe(
                abi.encodePacked(
                    "data:",
                    _traitDetails[i][thisTraitIndex].mimetype,
                    ";base64,",
                    Base64.encode(SSTORE2.read(_traitDataPointers[i][thisTraitIndex])),
                    "),url("
                )
            );
        }

        thisTraitIndex = HelperLib.parseInt(
            HelperLib._substring(_hash, (NUM_LAYERS * 3) - 3, NUM_LAYERS * 3)
        );

        svgBytes.appendSafe(
            abi.encodePacked(
                "data:",
                _traitDetails[NUM_LAYERS - 1][thisTraitIndex].mimetype,
                ";base64,",
                Base64.encode(SSTORE2.read(_traitDataPointers[NUM_LAYERS - 1][thisTraitIndex])),
                ');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>'
            )
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svgBytes)
            )
        );
    }

    function hashToMetadata(string memory _hash)
        public
        view
        returns (string memory)
    {
        bytes memory metadataBytes = DynamicBuffer.allocate(1024 * 128);
        metadataBytes.appendSafe("[");

        for (uint256 i = 0; i < NUM_LAYERS; i++) {
            uint256 thisTraitIndex = HelperLib.parseInt(
                HelperLib._substring(_hash, (i * 3), (i * 3) + 3)
            );
            metadataBytes.appendSafe(
                abi.encodePacked(
                    '{"trait_type":"',
                    LAYER_NAMES[i],
                    '","value":"',
                    _traitDetails[i][thisTraitIndex].name,
                    '"}'
                )
            );
            
            if (i == NUM_LAYERS - 1) {
                metadataBytes.appendSafe("]");
            } else {
                metadataBytes.appendSafe(",");
            }
        }

        return string(metadataBytes);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(_tokenId), "Invalid token");
        require(_traitDataPointers[0].length > 0,  "Traits have not been added");

        string memory tokenHash = tokenIdToHash(_tokenId);

        bytes memory jsonBytes = DynamicBuffer.allocate(1024 * 128);
        jsonBytes.appendSafe(unicode"{\"name\":\"Dupe Sweeper #");

        jsonBytes.appendSafe(
            abi.encodePacked(
                _toString(_tokenId),
                "\",\"description\":\"",
                contractData.description,
                "\","
            )
        );

        string memory svgCode = hashToSVG(tokenHash);
        
        jsonBytes.appendSafe(
            abi.encodePacked(
                '"image_data":"',
                svgCode,
                '",'
            )
        );

        jsonBytes.appendSafe(
            abi.encodePacked(
                '"attributes":',
                hashToMetadata(tokenHash),
                "}"
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(jsonBytes)
            )
        );
    }

    function contractURI()
        public
        view
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        contractData.name,
                        '","description":"',
                        contractData.description,
                        '","external_link":"',
                        "https://www.capsule21.com/collections/dupe-sweeper",
                        '","seller_fee_basis_points":',
                        _toString(contractData.royalties),
                        ',"fee_recipient":"',
                        contractData.royaltiesRecipient,
                        '"}'
                    )
                )
            )
        );
    }

    function tokenIdToSVG(uint256 _tokenId)
        public
        view
        returns (string memory)
    {
        return hashToSVG(tokenIdToHash(_tokenId));
    }

    function traitDetails(uint256 _layerIndex, uint256 _traitIndex)
        public
        view
        returns (Trait memory)
    {
        return _traitDetails[_layerIndex][_traitIndex];
    }

    function traitData(uint256 _layerIndex, uint256 _traitIndex)
        public
        view
        returns (string memory)
    {
        return string(SSTORE2.read(_traitDataPointers[_layerIndex][_traitIndex]));
    }

    function addLayer(uint256 _layerIndex, TraitDTO[] memory traits)
        public
        onlyOwner
    {
        require(TIERS[_layerIndex].length == traits.length, "Traits size does not match tiers for this index");
        require(traits.length < 100, "There cannot be over 99 traits per layer");
        address[] memory dataPointers = new address[](traits.length);
        for (uint256 i = 0; i < traits.length; i++) {
            dataPointers[i] = SSTORE2.write(traits[i].data);
            _traitDetails[_layerIndex][i] = Trait(traits[i].name, traits[i].mimetype);
        }
        _traitDataPointers[_layerIndex] = dataPointers;
        return;
    }

    function withdraw() external onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}("");
        require(success, "Withdrawal failed");
    }
    
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}