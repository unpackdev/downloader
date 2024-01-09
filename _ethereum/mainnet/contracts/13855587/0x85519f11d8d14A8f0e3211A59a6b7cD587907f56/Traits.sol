// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ITraits.sol";
import "./IPnG.sol";

import "./Accessable.sol";

contract Traits is Accessable, ITraits {
    using Strings for uint256;

    string public description;
    IPnG public nftContract;

    struct Trait {
        string name;
        string png;
    }

    // mapping from trait type (index) to its name
    string[15] private _traitTypes = [
        // Galleons
        "base",
        "deck",
        "sails",
        "crows nest",
        "decor",
        "flags",
        "bowsprit",
        // Pirates
        "skin",
        "clothes",
        "hair",
        "earrings",
        "mouth",
        "eyes",
        "weapon",
        "hat"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    // mapping from rankIndex to its score
    string[4] private _ranks = [
        "5",
        "6",
        "7",
        "8"
    ];


    constructor() {
        description = "With the sweet $CACAO becoming the most precious commodity, Galleons and Pirates engage in a risk-it-all battle in the Ethereum waters to get the biggest share. A play-to-earn game fully 100% on-chain, with commit-reveal minting and flashbots protection.";
    }

    /** ADMIN */

    function _setNftContract(address _nftContract) external onlyAdmin {
        nftContract = IPnG(_nftContract);
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function _uploadTraits(uint8 traitType, uint8[] calldata traitIds, Trait[] calldata traits) external onlyAdmin {
        require(traitIds.length == traits.length, "Mismatched inputs");
        for (uint i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function _setDescription(string memory _description) external onlyAdmin {
        description = _description;
    }

    function _withdraw() external onlyTokenClaimer {
        payable(_msgSender()).transfer(address(this).balance);
    }


    /** RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<image x="4" y="4" width="64" height="64" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
            trait.png,
            '"/>'
        ));
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Galleon or Pirate
     */
    function drawSVG(uint256 tokenId) internal view returns (string memory) {
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        string memory svgString;

        if (s.isGalleon) {
            svgString = string(abi.encodePacked(
                drawTrait(traitData[0][s.base]),
                drawTrait(traitData[1][s.deck]),
                drawTrait(traitData[2][s.sails]),
                drawTrait(traitData[3][s.crowsNest]),
                drawTrait(traitData[4][s.decor]),
                drawTrait(traitData[5][s.flags]),
                drawTrait(traitData[6][s.bowsprit])
            ));
        }
        else {
            svgString = string(abi.encodePacked(
                drawTrait(traitData[7][s.skin]),
                drawTrait(traitData[8][s.clothes]),
                drawTrait(traitData[9][s.hair]),
                drawTrait(traitData[10][s.earrings]),
                drawTrait(traitData[11][s.mouth]),
                drawTrait(traitData[12][s.eyes]),
                drawTrait(traitData[13][s.weapon]),
                s.hat > 0 ? drawTrait(traitData[14][s.hat]) : ''
            ));
        }

        return string(abi.encodePacked(
            '<svg id="GalletonPirateNFT" width="100%" height="100%" version="1.1" viewBox="0 0 72 72" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
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
    function compileAttributes(uint256 tokenId) internal view returns (string memory) {
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);
        string memory traits;
        if (s.isGalleon) {
            traits = string(abi.encodePacked(
                attributeForTypeAndValue(_traitTypes[0], traitData[0][s.base].name),',',
                attributeForTypeAndValue(_traitTypes[1], traitData[1][s.deck].name),',',
                attributeForTypeAndValue(_traitTypes[2], traitData[2][s.sails].name),',',
                attributeForTypeAndValue(_traitTypes[3], traitData[3][s.crowsNest].name),',',
                attributeForTypeAndValue(_traitTypes[4], traitData[4][s.decor].name),',',
                attributeForTypeAndValue(_traitTypes[5], traitData[5][s.flags].name),',',
                attributeForTypeAndValue(_traitTypes[6], traitData[6][s.bowsprit].name)
            ));
        } else {
            traits = string(abi.encodePacked(
                attributeForTypeAndValue(_traitTypes[7], traitData[7][s.skin].name),',',
                attributeForTypeAndValue(_traitTypes[8], traitData[8][s.clothes].name),',',
                attributeForTypeAndValue(_traitTypes[9], traitData[9][s.hair].name),',',
                attributeForTypeAndValue(_traitTypes[10], traitData[10][s.earrings].name),',',
                attributeForTypeAndValue(_traitTypes[11], traitData[11][s.mouth].name),',',
                attributeForTypeAndValue(_traitTypes[12], traitData[12][s.eyes].name),',',
                attributeForTypeAndValue(_traitTypes[13], traitData[13][s.weapon].name),',',
                attributeForTypeAndValue(_traitTypes[14], s.hat > 0 ? traitData[14][s.hat].name : 'None'), ',',
                attributeForTypeAndValue("rank", _ranks[s.alphaIndex])
            ));
        }
        
        return string(abi.encodePacked(
            '[',
            traits,
            ',{"trait_type":"generation","value":',
            tokenId <= nftContract.getPaidTokens() ? '"Gen 0"' : '"Gen 1"',
            '},{"trait_type":"type","value":',
            s.isGalleon ? '"Galleon"' : '"Pirate"',
            '}]'
        ));
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_msgSender() == address(nftContract) || isAdmin(_msgSender()), "???");
        IPnG.GalleonPirate memory s = nftContract.getTokenTraits(tokenId);

        string memory metadata = string(abi.encodePacked(
            '{"name": "',
            s.isGalleon ? 'Galleon #' : 'Pirate #',
            tokenId.toString(),
            '", "description": "',
            description, 
            '", "image": "data:image/svg+xml;base64,',
            base64(bytes(drawSVG(tokenId))),
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
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(                input,    0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}