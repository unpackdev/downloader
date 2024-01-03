//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "./IHLRenderer.sol";
import "./IERC721GeneralSupplyMetadata.sol";
import "./IHLFS.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./IOwnable.sol";

/**
 * @notice HL in-chain Renderer for curated hash based projects
 * @dev Currently supports a fairly fixed configuratoin
 * @author highlight.xyz
 */
contract CuratedRendererV1 {
    /**
     * @notice Throw when invalid input to process mint data
     */
    error InvalidMintData();

    /**
     * @notice Throw when seed input for a token cannot be found
     */
    error SeedInputNotFound();

    /**
     * @notice Throw when transaction sender isn't collection owner
     */
    error NotCollectionOwner();

    /**
     * @notice Input that seeds token metadata
     * @param previousBlockHash Hash of the block before the one the tokens were minted on
     * @param blockTimestamp Timestamp of block that tokens were minted on
     * @param startTokenId ID of first token of minted batch
     */
    struct SeedInput {
        bytes32 previousBlockHash;
        uint48 blockTimestamp;
        uint176 startTokenId;
        uint32 numMinted;
    }

    /**
     * @notice Simple collection config (to be made more complex)
     */
    struct CollectionConfig {
        string name;
        string previewsBaseUri;
        string htmlLang;
        bool htmlBodyExpected;
        bool useCDN;
    }

    uint256 private constant _32_BIT_MAX_MINUS_1 = 2 ** 32 - 1;

    /**
     * @notice Store the seed inputs for each token batch (for each nft contract)
     * @dev Assume startTokenIds are incrementing (up to implementer), assume first batch's startTokenId is 1
     */
    mapping(address => SeedInput[]) public collectionSeedInputs;

    /**
     * @notice Store config per collection
     */
    mapping(address => CollectionConfig) public collectionConfig;

    /**
     * @notice Set a collection's config
     */
    function setCollectionConfig(CollectionConfig calldata config, address collection) external {
        if (IOwnable(collection).owner() == msg.sender || msg.sender == collection) {
            collectionConfig[collection] = config;
        } else {
            _revert(NotCollectionOwner.selector);
        }
    }

    /**
     * @notice See {IHlRenderer-processOneRecipientMint}
     */
    function processOneRecipientMint(uint256 firstTokenId, uint256 numTokens, address recipient) external {
        collectionSeedInputs[msg.sender].push(
            SeedInput(blockhash(block.number - 1), uint48(block.timestamp), uint176(firstTokenId), uint32(numTokens))
        );
    }

    /**
     * @notice See {IHLRenderer-tokenURI}
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        address collection = msg.sender;
        SeedInput memory _seedInput = getSeedInput(tokenId, collection);
        bytes32 curatedHash = getCuratedHash(tokenId, collection);

        string memory tokenIdStr = Strings.toString(tokenId);

        bytes[] memory metadata = new bytes[](3);
        bytes[] memory encodedJson = new bytes[](2);

        // inject values in JS
        string memory injectedToken = string(
            abi.encodePacked(
                'const injectedToken = {"blockHash": "',
                Strings.toHexString(uint256(_seedInput.previousBlockHash)),
                '", "',
                'tokenId": "',
                tokenIdStr,
                '", "',
                'timestamp": "',
                Strings.toString(_seedInput.blockTimestamp),
                '", "',
                'hash": "',
                Strings.toHexString(uint256(curatedHash)),
                '", "',
                'isCurated": "1"',
                "};"
            )
        );

        metadata[0] = abi.encodePacked(
            '{"name": "',
            collectionConfig[collection].name,
            " #",
            tokenIdStr,
            '", "',
            'description": "',
            IHLFS(collection).fileContents("description.txt"),
            '", "',
            'image": "',
            collectionConfig[collection].previewsBaseUri,
            "/",
            Strings.toString(tokenId),
            ".png",
            '", "'
            'animation_url": "data:text/html;base64,'
        );
        metadata[1] = bytes(Base64.encode(_generateHTML(collection, injectedToken, false)));
        metadata[2] = bytes('"}');

        encodedJson[0] = bytes("data:application/json;base64,");
        encodedJson[1] = bytes(Base64.encode(concat(metadata)));
        return string(concat(encodedJson));
    }

    /**
     * @notice See {IHLRenderer-tokenURI}
     */
    function tokenURIWithCDN(uint256 tokenId, address collection) public view virtual returns (string memory) {
        SeedInput memory _seedInput = getSeedInput(tokenId, collection);
        bytes32 curatedHash = getCuratedHash(tokenId, collection);

        string memory tokenIdStr = Strings.toString(tokenId);

        bytes[] memory metadata = new bytes[](3);
        bytes[] memory encodedJson = new bytes[](2);

        // inject values in JS
        string memory injectedToken = string(
            abi.encodePacked(
                'const injectedToken = {"blockHash": "',
                Strings.toHexString(uint256(_seedInput.previousBlockHash)),
                '", "',
                'tokenId": "',
                tokenIdStr,
                '", "',
                'timestamp": "',
                Strings.toString(_seedInput.blockTimestamp),
                '", "',
                'hash": "',
                Strings.toHexString(uint256(curatedHash)),
                '", "',
                'isCurated": "1"',
                "};"
            )
        );

        metadata[0] = abi.encodePacked(
            '{"name": "',
            collectionConfig[collection].name,
            " #",
            tokenIdStr,
            '", "',
            'description": "',
            IHLFS(collection).fileContents("description.txt"),
            '", "',
            'image": "',
            collectionConfig[collection].previewsBaseUri,
            "/",
            Strings.toString(tokenId),
            ".png",
            '", "'
            'animation_url": "data:text/html;base64,'
        );
        metadata[1] = bytes(Base64.encode(_generateHTML(collection, injectedToken, true)));
        metadata[2] = bytes('"}');

        encodedJson[0] = bytes("data:application/json;base64,");
        encodedJson[1] = bytes(Base64.encode(concat(metadata)));
        return string(concat(encodedJson));
    }

    /**
     * @notice Get a token's curated hash
     */
    function getCuratedHash(uint256 tokenId, address collection) public view returns (bytes32) {
        bytes32[] memory curatedHashes = _parseCuratedHashText(
            IHLFS(collection).fileContents("curatedHashes.txt"),
            IERC721GeneralSupplyMetadata(collection).limitSupply()
        );
        uint256 initialCuratedHashesLength = curatedHashes.length;
        bytes32 lastCuratedHash = bytes32(0);

        for (uint256 i = 0; i < tokenId; i++) {
            SeedInput memory _seedInput = getSeedInput(i + 1, collection);
            bytes32 seed = _getSeed(_seedInput, i + 1);
            uint256 generatedIndex = _prngSeedInput(
                seed,
                _seedInput.previousBlockHash,
                i + 1,
                initialCuratedHashesLength - i
            );
            uint256 virtualIndexPlusOne = 0;

            for (uint256 j = 0; j < initialCuratedHashesLength; j++) {
                if (curatedHashes[j] != bytes32(0)) {
                    virtualIndexPlusOne += 1;
                    if (virtualIndexPlusOne == generatedIndex + 1) {
                        // curated hash found for final token id
                        if (i == tokenId - 1) {
                            lastCuratedHash = curatedHashes[j];
                        }
                        curatedHashes[j] = bytes32(0);
                        break;
                    }
                }
            }
        }

        return lastCuratedHash;
    }

    /**
     * Get a token's seed
     */
    function getSeed(uint256 tokenId, address collection) public view returns (bytes32) {
        SeedInput memory _seedInput = getSeedInput(tokenId, collection);
        return _getSeed(_seedInput, tokenId);
    }

    /**
     * @notice Get a token's seed input
     */
    function getSeedInput(uint256 tokenId, address collection) public view returns (SeedInput memory) {
        SeedInput[] memory _seedInputs = collectionSeedInputs[collection];
        uint256 numInputs = _seedInputs.length;
        if (numInputs == 0) {
            _revert(SeedInputNotFound.selector);
        }
        for (uint256 i = numInputs - 1; i >= 0; i--) {
            if (tokenId >= _seedInputs[i].startTokenId) {
                // assume first batch's startTokenId is 1
                if (_seedInputs[i].startTokenId + _seedInputs[i].numMinted <= tokenId) {
                    _revert(SeedInputNotFound.selector);
                } else {
                    return _seedInputs[i];
                }
            }
        }
    }

    /**
     * @notice Generate the project's HTML file
     */
    function _generateHTML(address collection, string memory injectedToken, bool useCDNOverride) public view returns (bytes memory) {
        bytes[] memory html = new bytes[](4);

        bool useCDN = useCDNOverride ? true : collectionConfig[collection].useCDN;
        string memory libScriptPrefix = useCDN ? ' src="' : ">";
        string memory libScriptSuffix = useCDN ? '">' : "";
        html[0] = abi.encodePacked(
            '<!DOCTYPE html><html lang="',
            collectionConfig[collection].htmlLang,
            '">',
            "<head>",
            IHLFS(collection).fileContents("headPrefix.html"),
            "<script>",
            injectedToken,
            IHLFS(collection).fileContents("hl-gen-inchain.js"),
            "</script><script",
            libScriptPrefix
        );
        html[1] = bytes(
            IHLFS(collection).fileContents(useCDN ? "p5-cdn.txt" : "p5.min.js")
        );
        html[2] = abi.encodePacked(
            libScriptSuffix,
            "</script><script>",
            IHLFS(collection).fileContents("sketch.js"),
            "</script>",
            "<style>",
            IHLFS(collection).fileContents("index.css"),
            "</style>",
            "</head>"
        );

        string memory HTMLBody = "";
        if (collectionConfig[collection].htmlBodyExpected) {
            HTMLBody = IHLFS(collection).fileContents("body.html");
        }
        html[3] = abi.encodePacked("<body>", HTMLBody, "</body>", "</html>");

        return concat(html);
    }

    /**
     * @notice Base64 Encode a metadata JSON
     */
    function _encodeMetadataJSON(bytes memory json) private pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @notice Concatenate byte arrays
     */
    function concat(bytes[] memory arrays) public pure returns (bytes memory) {
        uint totalLength = 0;
        for (uint i = 0; i < arrays.length; i++) {
            totalLength += arrays[i].length;
        }

        bytes memory result = new bytes(totalLength);
        uint resultPtr;
        assembly {
            resultPtr := add(result, 0x20)
        }

        for (uint i = 0; i < arrays.length; i++) {
            bytes memory array = arrays[i];
            uint arrayLength = array.length;

            uint arrayPtr;
            assembly {
                arrayPtr := add(array, 0x20)
            }

            // Efficiently copy memory block
            for (uint j = 0; j < arrayLength; j += 32) {
                assembly {
                    let chunk := mload(add(arrayPtr, j))
                    mstore(add(resultPtr, j), chunk)
                }
            }

            resultPtr += arrayLength;
        }

        return result;
    }

    /**
     * @notice Parse out all curated hashes for a mint
     */
    function _parseCuratedHashText(
        string memory curatedHashesText,
        uint256 numLines
    ) private pure returns (bytes32[] memory) {
        bytes32[] memory curatedHashes = new bytes32[](numLines);

        uint256 arrayIndex = 0;
        bytes memory stringBytes = bytes(curatedHashesText);
        uint256 i = 0;

        while (i < stringBytes.length && arrayIndex < numLines) {
            // Skip the "0x" prefix at the start of each line
            if (i == 0 || stringBytes[i - 1] == "\n") {
                i += 2;
            }

            bytes32 line;
            for (uint j = 0; j < 32; j++) {
                // Convert two hex characters to one byte
                bytes1 b1 = _parseHexChar(stringBytes[i]);
                bytes1 b2 = _parseHexChar(stringBytes[i + 1]);
                line |= bytes32((uint8(b1) * 16 + uint8(b2)) * 2 ** (8 * (31 - j)));
                i += 2;
            }

            curatedHashes[arrayIndex] = line;
            arrayIndex++;

            // Skip the newline character
            if (i < stringBytes.length && stringBytes[i] == "\n") {
                i++;
            }
        }

        return curatedHashes;
    }

    /**
     * @notice Parse a byte value represented in string to the byte representation of the value
     */
    function _parseHexChar(bytes1 char) internal pure returns (bytes1) {
        if (uint8(char) >= 48 && uint8(char) <= 57) {
            return bytes1(uint8(char) - 48); // 0-9
        }
        if (uint8(char) >= 65 && uint8(char) <= 70) {
            return bytes1(uint8(char) - 55); // A-F
        }
        if (uint8(char) >= 97 && uint8(char) <= 102) {
            return bytes1(uint8(char) - 87); // a-f
        }
        revert("Invalid hex character");
    }

    /**
     * @notice Generate an index via a prng, given seed input and a max value
     */
    function _prngSeedInput(
        bytes32 generalHash,
        bytes32 blockHash,
        uint256 tokenId,
        uint256 max
    ) private pure returns (uint256) {
        uint256 seed = tokenId;

        // process each byte of generalHash and blockHash
        for (uint256 i = 0; i < 32; i++) {
            // extract and process high and low nibbles for generalHash
            uint8 highNibbleTx = uint8(generalHash[i]) >> 4;
            uint8 lowNibbleTx = uint8(generalHash[i]) & 0x0F;
            if (highNibbleTx <= 9) {
                seed += highNibbleTx;
            }
            if (lowNibbleTx <= 9) {
                seed += lowNibbleTx;
            }

            // extract and process high and low nibbles for blockHash
            uint8 highNibbleBlock = uint8(blockHash[i]) >> 4;
            uint8 lowNibbleBlock = uint8(blockHash[i]) & 0x0F;
            if (highNibbleBlock <= 9) {
                seed += highNibbleBlock;
            }
            if (lowNibbleBlock <= 9) {
                seed += lowNibbleBlock;
            }
        }

        uint256 t = (seed + 0x6D2B79F5) & (_32_BIT_MAX_MINUS_1);
        t = imul(t ^ (t >> 15), t | 1) & (_32_BIT_MAX_MINUS_1);
        t ^= (t + imul(t ^ (t >> 7), t | 61)) & (_32_BIT_MAX_MINUS_1);
        t = (t ^ (t >> 14)) & (_32_BIT_MAX_MINUS_1);
        return t % max;
    }

    /**
     * @notice Replicate js Math.imul
     */
    function imul(uint256 a, uint256 b) private pure returns (uint256) {
        return (a * b) % (_32_BIT_MAX_MINUS_1 + 1);
    }

    /**
     * @notice Get a token's seed util
     */
    function _getSeed(SeedInput memory _seedInput, uint256 tokenId) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_seedInput.previousBlockHash, tokenId, _seedInput.blockTimestamp));
    }

    /**
     * @notice Efficient revert
     */
    function _revert(bytes4 errorSelector) private pure {
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}
