// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ITraits.sol";
import "./IDegens.sol";

contract Traits is Ownable, ITraits {

    using Strings for uint256;

    bool phase1 = true;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[8] _traitTypes = [
    "Accessories",
    "Clothes",
    "Eyes",
    "Background",
    "Mouth",
    "Body",
    "Hairdo",
    "Alpha"
    ];

    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => mapping(uint8 => Trait))) public traitData;

    // mapping from alphaIndex to its score
    string[4] _alphas = ["8", "7", "6", "5"];

    IDegens public degens;

    constructor() {}

    function setPhase1Enabled(bool _enabled) external onlyOwner {
        phase1 = _enabled;
    }

    /** ADMIN */
    function setDegensContractAddress(address _degensContractAddress) external onlyOwner {
        degens = IDegens(_degensContractAddress);
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
   * @param traits the names and base64 encoded PNGs for each trait
   */
    function uploadTraits(uint8 degenType, uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[degenType][traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
   * @return the <image> element
   */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<image x="0" y="0" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                trait.png,
                '"/>'
            ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
   * @return a valid SVG of the bba / zombie
   */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        IDegens.Degen memory s = degens.getTokenTraits(tokenId);
        bool isNotZombie = !degens.isZombies(s);
        bool isApe = degens.isApes(s);
        bool isBear = degens.isBears(s);
        bool isBull = degens.isBull(s);

        if (phase1) {
            string memory imagelink;
            if (!isNotZombie) {
                imagelink = "https://gameofdegens.com/zombie_placeholder.gif";
            } else if (isApe) {
                imagelink = "https://gameofdegens.com/ape_placeholder.gif";
            } else if (isBear) {
                imagelink = "https://gameofdegens.com/bear_placeholder.gif";
            } else if (isBull) {
                imagelink = "https://gameofdegens.com/bull_placeholder.gif";
            }

            return imagelink;
        }

        string memory svgString = string(abi.encodePacked(
                drawTrait(traitData[0][3][s.background]),
                drawTrait(traitData[s.degenType][5][s.body]),
                isApe ? drawTrait(traitData[s.degenType][2][s.eyes]) : drawTrait(traitData[s.degenType][1][s.clothes]),
                isApe ? drawTrait(traitData[s.degenType][1][s.clothes]) : drawTrait(traitData[s.degenType][2][s.eyes]),
                isNotZombie ? isBear ? drawTrait(traitData[s.degenType][0][s.accessories]) : drawTrait(traitData[s.degenType][4][s.mouth]) : drawTrait(traitData[s.degenType][6][s.hairdo]),
                isBear ? drawTrait(traitData[s.degenType][4][s.mouth]) : drawTrait(traitData[s.degenType][0][s.accessories])

            ));

        return string(abi.encodePacked(
                '<svg id="character" width="100%" height="100%" version="1.1" viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                svgString,
                "</svg>"
            ));
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
   * @param value the token's trait associated with the key
   * @return a JSON dictionary for the single attribute
   */
    function attributeForTypeAndValue(string memory traitType, string memory value) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '{"trait_type":"',
                traitType,
                '","value":"',
                value,
                '"}'
            ));
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
   * @return a JSON array of all of the attributes for given token ID
   */
    function compileAttributes(uint256 tokenId) public view returns (string memory) {
        IDegens.Degen memory s = degens.getTokenTraits(tokenId);
        string memory traits;

        if (phase1) {
            return string(abi.encodePacked(
                    '[{"trait_type":"Generation","value": "',
                    degens.getNFTGeneration(tokenId),
                    '"},{"trait_type":"Type","value": "', degens.getDegenTypeName(s), '"}]'
                ));
        }

        if (degens.isBull(s)) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[0][0][s.accessories].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[0][1][s.clothes].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[0][2][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[0][3][s.background].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[0][4][s.mouth].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[0][5][s.body].name), ','
                ));
        }
        else if (degens.isBears(s)) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[1][0][s.accessories].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[1][1][s.clothes].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[1][2][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[0][3][s.background].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[1][4][s.mouth].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[1][5][s.body].name), ','
                ));
        } else if (degens.isApes(s)) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[2][0][s.accessories].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[2][1][s.clothes].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[2][2][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[0][3][s.background].name), ',',
                    attributeForTypeAndValue(_traitTypes[4], traitData[2][4][s.mouth].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[2][5][s.body].name), ','
                ));
        } else if (degens.isZombies(s)) {
            traits = string(abi.encodePacked(
                    attributeForTypeAndValue(_traitTypes[0], traitData[3][0][s.accessories].name), ',',
                    attributeForTypeAndValue(_traitTypes[1], traitData[3][1][s.clothes].name), ',',
                    attributeForTypeAndValue(_traitTypes[2], traitData[3][2][s.eyes].name), ',',
                    attributeForTypeAndValue(_traitTypes[3], traitData[0][3][s.background].name), ',',
                    attributeForTypeAndValue(_traitTypes[5], traitData[3][5][s.body].name), ',',
                    attributeForTypeAndValue(_traitTypes[6], traitData[3][6][s.hairdo].name), ',',
                    attributeForTypeAndValue("Alpha Score", _alphas[s.alphaIndex]), ','
                ));
        }
        return string(abi.encodePacked(
                '[',
                traits,
                '{"trait_type":"Generation","value":"',
                degens.getNFTGeneration(tokenId),
                '"},{"trait_type":"Type","value":"',
                degens.getDegenTypeName(s),
                '"}]'
            ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
   * @return a base64 encoded JSON dictionary of the token's metadata and SVG
   */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IDegens.Degen memory s = degens.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
                '{"name": "',
                degens.getNFTName(s), ' #',
                tokenId.toString(),
                '", "description": "A group of elite degens unite in a fortress in a metaverse to protect themselves from the zombies. A tempting prize of $GAINS awaits, with deadly high stakes. All the metadata and images are generated and stored 100% on-chain. No IPFS. NO API. Just the Ethereum blockchain.",',
                ' "image":', phase1 ? '"' : '"data:image/svg+xml;base64,',
                phase1 ? drawSVG(tokenId) : '',
                phase1 ? '' : base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            ));

        return string(abi.encodePacked(
                "data:application/json;base64,",
                base64(bytes(metadata))
            ));
    }

    /** BASE 64 - Written by Brech Devos */
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
            mstore(result, encodedLen)

        // prepare the lookup table
            let tablePtr := add(table, 1)

        // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
            let resultPtr := add(result, 32)

        // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }

        return result;
    }
}
