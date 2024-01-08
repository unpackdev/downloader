// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxied.sol";
import "./StringsUpgradeable.sol";

import "./ITraits.sol";
import "./IChickenNoodle.sol";

contract Traits is Proxied, ITraits {
    using StringsUpgradeable for uint256;
    using StringsUpgradeable for uint8;

    // mapping from trait type (index) to its name
    string[7] _traitTypes;

    // storage for image baseURI
    string public imageBaseURI;
    // storage for metadata description
    string public description;
    // storage of each traits name
    mapping(uint8 => mapping(uint8 => string)) public traitData;

    IChickenNoodle public chickenNoodle;

    // constructor(string memory _imageBaseURI) {
    //     initialize(_imageBaseURI);
    // }

    function initialize(string memory _imageBaseURI) public proxied {
        imageBaseURI = _imageBaseURI;

        _traitTypes = [
            'Backgrounds',
            'Snake Bodies',
            'Mouth Accessories',
            'Pupils',
            'Body Accessories',
            'Hats',
            'Tier'
        ];
    }

    /** ADMIN */

    function setChickenNoodle(address _chickenNoodle) external onlyProxyAdmin {
        chickenNoodle = IChickenNoodle(_chickenNoodle);
    }

    /**
     * administrative to set metadata description
     * @param _imageBaseURI base URI for the image
     */
    function setImageBaseURI(string calldata _imageBaseURI)
        external
        onlyProxyAdmin
    {
        imageBaseURI = _imageBaseURI;
    }

    /**
     * administrative to set metadata description
     * @param _description the standard description for metadata
     */
    function setDescription(string calldata _description)
        external
        onlyProxyAdmin
    {
        description = _description;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param names the names for each trait
     */
    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        string[] calldata names
    ) external onlyProxyAdmin {
        require(traitIds.length == names.length, 'Mismatched inputs');
        for (uint256 i = 0; i < names.length; i++) {
            traitData[traitType][traitIds[i]] = names[i];
        }
    }

    /** RENDER */

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IChickenNoodle.ChickenNoodleTraits memory s = chickenNoodle.tokenTraits(
            tokenId
        );
        string memory traits;

        if (!s.minted) {
            return
                string(
                    abi.encodePacked(
                        '[{"trait_type":"Generation","value":',
                        tokenId <= chickenNoodle.PAID_TOKENS()
                            ? '"Gen 0"'
                            : '"Gen 1"',
                        '},{"trait_type":"Status","value":"Minting"}]'
                    )
                );
        }

        if (s.isChicken) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.backgrounds]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.snakeBodies]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.mouthAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.pupils]
                    ),
                    ',',
                    attributeForTypeAndValue(_traitTypes[4], 'Chicken Suit'),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.hats]
                    )
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        _traitTypes[0],
                        traitData[0][s.backgrounds]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[1],
                        traitData[1][s.snakeBodies]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[2],
                        traitData[2][s.mouthAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[3],
                        traitData[3][s.pupils]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[4],
                        traitData[4][s.bodyAccessories]
                    ),
                    ',',
                    attributeForTypeAndValue(
                        _traitTypes[5],
                        traitData[5][s.hats]
                    ),
                    ',',
                    attributeForTypeAndValue('Tier', s.tier.toString())
                )
            );
        }

        return
            string(
                abi.encodePacked(
                    '[',
                    '{"trait_type":"Generation","value":',
                    tokenId <= chickenNoodle.PAID_TOKENS()
                        ? '"Gen 0"'
                        : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    s.isChicken ? '"Chicken"' : '"Snake"',
                    '},',
                    traits,
                    ']'
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        IChickenNoodle.ChickenNoodleTraits memory s = chickenNoodle.tokenTraits(
            tokenId
        );

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isChicken ? 'Chicken #' : 'Noodle #',
                tokenId.toString(),
                '", "image": "',
                imageBaseURI,
                tokenId.toString(),
                '.png", "description": "',
                description,
                '", "attributes":',
                compileAttributes(tokenId),
                '}'
            )
        );

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    base64(bytes(metadata))
                )
            );
    }

    /** BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}
