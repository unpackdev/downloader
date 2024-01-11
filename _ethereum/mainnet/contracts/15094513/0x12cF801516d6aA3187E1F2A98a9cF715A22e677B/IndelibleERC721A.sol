
    // SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    import "./ERC721A.sol";
    import "./ReentrancyGuard.sol";
    import "./Ownable.sol";
    import "./Base64.sol";
    import "./SSTORE2.sol";
    import "./DynamicBuffer.sol";
    import "./HelperLib.sol";

    contract IndelibleERC721A is ERC721A, ReentrancyGuard, Ownable {
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
        mapping(uint256 => bool) internal _renderTokenOffChain;

        uint256 private constant NUM_LAYERS = 8;
        uint256 private constant MAX_BATCH_MINT = 20;
        uint256[][NUM_LAYERS] private TIERS;
        string[] private LAYER_NAMES = [unicode"Accessories", unicode"Hand", unicode"Sleeve", unicode"Rocks", unicode"Dirty Doug", unicode"Wormz", unicode"Dirt", unicode"Cup"];
        bool private shouldWrapSVG = true;
        uint256 public constant maxTokens = 8008;
        uint256 public maxPerAddress = 100;
        uint256 public maxFreePerAddress = 0;
        uint256 public mintPrice = 0 ether;
        string public baseURI = "";
        bool public isMintingPaused = true;
        ContractData public contractData = ContractData(unicode"Cup of Dirt", unicode"It's a cup... of dirt. With this cup, you now own the dirt in the cup. The dirt represents land in the metaverse. Land that will never be usable. There will be no game. Scarce digital land is stupid. This is not a joke. RUG. DIRT. DIRT. DIRT. DIRT. DIRT. DIRT.", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/profile/e431f4ea-6e56-449d-ba9b-107b3e6c48fc", "https://indeliblelabs-prod.s3.us-east-2.amazonaws.com/banner/e431f4ea-6e56-449d-ba9b-107b3e6c48fc", "", 500, "0x01A1A79E83e26A9DE566F65A1AcDf02DeC449D26");

        constructor() ERC721A(unicode"Cup of Dirt", unicode"COD") {
            TIERS[0] = [10,15,17,31,32,33,60,63,79,88,108,128,130,146,163,184,185,190,203,210,228,238,256,257,286,359,392,435,454,454,559,587,635,793];
TIERS[1] = [34,89,134,281,379,585,674,816,1157,1320,2539];
TIERS[2] = [2,3,10,40,44,45,48,49,64,74,94,107,169,178,199,215,219,236,250,251,277,285,306,340,352,363,373,398,941,996,1080];
TIERS[3] = [121,258,648,948,1078,2187,2768];
TIERS[4] = [25,46,50,50,59,98,140,143,196,348,352,357,469,570,583,617,794,896,967,1248];
TIERS[5] = [31,91,142,213,347,447,745,954,1440,1624,1974];
TIERS[6] = [17,18,21,23,24,29,35,37,41,44,60,68,71,83,94,113,157,173,184,214,219,242,255,258,274,286,289,306,332,342,346,363,474,673,782,1061];
TIERS[7] = [34,40,44,53,132,174,187,209,228,263,299,321,358,409,430,559,576,1077,1088,1527];
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

        function mint(uint256 _count) external payable nonReentrant whenPublicMintActive returns (uint256) {
            uint256 totalMinted = _totalMinted();
            require(_count > 0, "Invalid token count");
            require(totalMinted + _count <= maxTokens, "All tokens are gone");
            require(_count * mintPrice == msg.value, "Incorrect amount of ether sent");
            require(balanceOf(msg.sender) + _count <= maxPerAddress, "Exceeded max mints allowed.");

            uint256 batchCount = _count / MAX_BATCH_MINT;
            uint256 remainder = _count % MAX_BATCH_MINT;

            for (uint256 i = 0; i < batchCount; i++) {
                _mint(msg.sender, MAX_BATCH_MINT);
            }

            if (remainder > 0) {
                _mint(msg.sender, remainder);
            }

            return totalMinted;
        }

        function isPublicMintActive() public view returns (bool) {
            return _totalMinted() < maxTokens && isMintingPaused == false;
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
            jsonBytes.appendSafe(unicode"{\"name\":\"Cup of Dirt #");

            jsonBytes.appendSafe(
                abi.encodePacked(
                    _toString(_tokenId),
                    "\",\"description\":\"",
                    contractData.description,
                    "\","
                )
            );

            if (bytes(baseURI).length > 0 && _renderTokenOffChain[_tokenId]) {
                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"image":"',
                        baseURI,
                        _toString(_tokenId),
                        "?dna=",
                        tokenHash,
                        '&network=mainnet",'
                    )
                );
            } else {
                string memory svgCode = "";
                if (shouldWrapSVG) {
                    string memory svgString = hashToSVG(tokenHash);
                    svgCode = string(
                        abi.encodePacked(
                            "data:image/svg+xml;base64,",
                            Base64.encode(
                                abi.encodePacked(
                                    '<svg width="100%" height="100%" viewBox="0 0 1200 1200" version="1.2" xmlns="http://www.w3.org/2000/svg"><image width="1200" height="1200" href="',
                                    svgString,
                                    '"></image></svg>'
                                )
                            )
                        )
                    );
                    jsonBytes.appendSafe(
                        abi.encodePacked(
                            '"svg_image_data":"',
                            svgString,
                            '",'
                        )
                    );
                } else {
                    svgCode = hashToSVG(tokenHash);
                }

                jsonBytes.appendSafe(
                    abi.encodePacked(
                        '"image_data":"',
                        svgCode,
                        '",'
                    )
                );
            }

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
                            '","image":"',
                            contractData.image,
                            '","banner":"',
                            contractData.banner,
                            '","external_link":"',
                            contractData.website,
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

        function addTrait(uint256 _layerIndex, uint256 _traitIndex, TraitDTO memory trait)
            public
            onlyOwner
        {
            require(_traitIndex < 99, "There cannot be over 99 traits per layer");
            _traitDetails[_layerIndex][_traitIndex] = Trait(trait.name, trait.mimetype);
            address[] memory dataPointers = _traitDataPointers[_layerIndex];
            dataPointers[_traitIndex] = SSTORE2.write(trait.data);
            _traitDataPointers[_layerIndex] = dataPointers;
            return;
        }

        function changeContractData(ContractData memory _contractData) external onlyOwner {
            contractData = _contractData;
        }

        function changeMaxPerAddress(uint256 _maxPerAddress) external onlyOwner {
            maxPerAddress = _maxPerAddress;
        }

        function changeBaseURI(string memory _baseURI) external onlyOwner {
            baseURI = _baseURI;
        }

        function changeRenderOfTokenId(uint256 _tokenId, bool _renderOffChain) external {
            require(msg.sender == ownerOf(_tokenId), "Only the token owner can change the render method");
            _renderTokenOffChain[_tokenId] = _renderOffChain;
        }

        function toggleWrapSVG() external onlyOwner {
            shouldWrapSVG = !shouldWrapSVG;
        }

        function toggleMinting() external onlyOwner {
            isMintingPaused = !isMintingPaused;
        }

        function withdraw() external onlyOwner nonReentrant {
            (bool success,) = msg.sender.call{value : address(this).balance}("");
            require(success, "Withdrawal failed");
        }
    }
