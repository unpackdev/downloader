// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./Strings.sol";
import "./base64.sol";
import "./GenesisNftAttributes.sol";

error AddressInvalid();
error LevelInvalid();

contract GenesisNftData {
    GenesisNftAttributes public immutable attributes;

    uint256 private constant ONE_E18 = 10 ** 18;
    uint256 private constant FOUR_E18 = 4 * 10 ** 18;
    uint256 private constant MAX_LEVEL = 80;

    /**
     * @notice The formula is: (175 + level * 2.5) * ( 3 + floor(level / 10))
     * This formula should be run and accumulated for each level up to the current level and then divided by 4 to fit into a uint16
     */
    uint16[MAX_LEVEL] private levels = [
        131,
        264,
        399,
        535,
        674,
        814,
        957,
        1101,
        1247,
        1395,
        1595,
        1797,
        2002,
        2209,
        2419,
        2631,
        2846,
        3063,
        3283,
        3505,
        3786,
        4070,
        4357,
        4647,
        4941,
        5237,
        5537,
        5840,
        6146,
        6455,
        6830,
        7208,
        7590,
        7976,
        8366,
        8759,
        9156,
        9557,
        9962,
        10370,
        10851,
        11336,
        11826,
        12319,
        12818,
        13320,
        13828,
        14339,
        14855,
        15375,
        15975,
        16579,
        17189,
        17803,
        18423,
        19047,
        19677,
        20311,
        20951,
        21595,
        22326,
        23062,
        23804,
        24551,
        25305,
        26063,
        26828,
        27598,
        28374,
        29155,
        30030,
        30910,
        31797,
        32690,
        33590,
        34495,
        35407,
        36325,
        37250,
        38180
    ];

    /**
     * @notice The formula is: (level * 12 + levelCost) / 500
     */
    uint16[81] public shares = [
        1,
        2,
        3,
        4,
        5,
        7,
        8,
        9,
        10,
        11,
        13,
        15,
        16,
        18,
        20,
        21,
        23,
        25,
        27,
        28,
        31,
        33,
        35,
        38,
        40,
        43,
        45,
        47,
        50,
        52,
        55,
        58,
        61,
        65,
        68,
        71,
        74,
        77,
        81,
        84,
        88,
        92,
        96,
        100,
        104,
        108,
        112,
        116,
        120,
        124,
        129,
        134,
        139,
        144,
        149,
        154,
        159,
        164,
        169,
        174,
        180,
        186,
        192,
        198,
        204,
        210,
        216,
        222,
        229,
        235,
        242,
        249,
        256,
        263,
        270,
        278,
        285,
        292,
        300,
        307,
        320
    ];

    constructor(address _attributesAddress) {
        if (_attributesAddress == address(0)) {
            revert AddressInvalid();
        }
        attributes = GenesisNftAttributes(_attributesAddress);
    }

    /**
     * @notice Returns the level of the NFT based on the amount of tokens staked.
     * @dev Splits 80 into 4 seconds of 20, then splits 20 into 4 sections of 5, then loops over the remaining 5 to find the correct level from the XP array.
     * @param _staked The amount of tokens staked.
     * @return The level of the NFT.
     **/
    function getLevel(uint256 _staked) public view returns (uint256) {
        for (uint256 s1 = 1; s1 <= 4; ++s1) {
            if (_staked < uint256(levels[s1 * 20 - 1]) * FOUR_E18) {
                for (uint256 s2 = 1; s2 <= 4; ++s2) {
                    if (_staked <= uint256(levels[(s1 - 1) * 20 + (s2) * 5 - 1]) * FOUR_E18) {
                        uint256 ls = (s1 - 1) * 20 + (s2 - 1) * 5;
                        for (uint256 level = ls; level <= ls + 4; ++level) {
                            if (_staked < uint256(levels[level]) * FOUR_E18) {
                                return level;
                            }
                        }
                    }
                }
            }
        }
        return MAX_LEVEL;
    }

    /**
     * @notice Returns the level of the NFT based on the amount of tokens staked capped by the tier.
     * @dev Gets the level using getLevel, but then caps it based on the tier as the level does not increase if the tier is not evolved.
     * @param _staked The amount of tokens staked.
     * @param _tier The tier of the NFT.
     * @return The level of the NFT.
     **/
    function getLevelCapped(uint256 _staked, uint256 _tier) external view returns (uint256) {
        uint256 level = getLevel(_staked);
        if ((_tier + 1) * 10 < level) {
            return (_tier + 1) * 10;
        }
        return level;
    }

    /**
     * @notice Returns the amount of tokens required to reach a specific level.
     * @dev Gets the tokens from the level array and multiplies it by 4e18.
     * @param _level The level to get the tokens required for.
     * @return The amount of tokens required to reach the level.
     **/
    function getTokensRequiredForLevel(uint256 _level) external view returns (uint256) {
        if (_level < 1) {
            return 0;
        } else if (_level > MAX_LEVEL) {
            revert LevelInvalid();
        }
        return levels[_level - 1] * FOUR_E18;
    }

    /**
     * @notice Returns the amount of tokens required to reach a specific tier.
     * @dev Gets the tokens required for the specified tier from the level array and multiplies it by 4e18.
     * @param _tier The tier to get the tokens required to reach it for.
     * @return The amount of tokens required to reach the tier.
     **/
    function getTokensRequiredForTier(uint256 _tier) external view returns (uint256) {
        if (_tier == 0) {
            return 0;
        }
        if (_tier * 10 <= levels.length) {
            return levels[(_tier * 10) - 1] * FOUR_E18;
        } else {
            return levels[levels.length - 1] * FOUR_E18;
        }
    }

    /**
     * @notice splits a bytes into an array of uint8's.
     * @param _b The bytes to split.
     * @return _res The array of uint8s's.
     **/
    function splitBytes(bytes memory _b) public pure returns (uint8[11] memory _res) {
        for (uint256 i = 0; i < 11; i++) {
            _res[i] = uint8(bytes1(_b[i]));
        }
    }

    /**
     * @notice Converts bytes32 to a string.
     * @param _bytes32 The bytes to convert.
     * @return The string representation of the bytes32.
     **/
    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    /**
     * @notice Decodes the attributes from the encoded attributes bytes32.
     * @param _encodedAttributes The encoded attributes bytes.
     * @return _attributes The array of attributes.
     **/
    function decodeAttributes(
        bytes32 _encodedAttributes,
        uint256 _initCompleted
    ) public view returns (string[11] memory _attributes) {
        if (_initCompleted > 0) {
            uint8[11] memory i = splitBytes(abi.encode(_encodedAttributes));
            _attributes[0] = bytes32ToString(attributes.gender(i[0]));
            _attributes[1] = bytes32ToString(attributes.body(i[1]));
            _attributes[2] = bytes32ToString(attributes.profession(i[2]));
            _attributes[3] = bytes32ToString(attributes.accessories(i[3]));
            _attributes[4] = bytes32ToString(attributes.background(i[4]));
            _attributes[5] = bytes32ToString(attributes.eyes(i[5]));
            _attributes[6] = bytes32ToString(attributes.hair(i[6]));
            _attributes[7] = bytes32ToString(attributes.mouth(i[7]));
            _attributes[8] = bytes32ToString(attributes.complexion(i[8]));
            _attributes[9] = bytes32ToString(attributes.item(i[9]));
            _attributes[10] = bytes32ToString(attributes.clothes(i[10]));
        } else {
            _attributes = ["?", "?", "?", "?", "?", "?", "?", "?", "?", "?", "?"];
        }
    }

    /**
     * @notice Returns the token URI for the Genesis NFT.
     * @dev Returns the token URI for the Genesis NFT.
     * @param _level The level of the NFT.
     * @param _tier The tier of the NFT.
     * @param _staked The amount of tokens staked.
     * @param _shares The amount of shares.
     * @param _encodedAttributes The encoded attributes string.
     * @param _unlockTime The unlock time of the NFT.
     * @param _initCompleted Weather the initialization of the NFT has completed.
     * @param _imageUri The image URI of the NFT.
     * @return The token URI for the Genesis NFT.
     **/
    function tokenUriTraits(
        uint256 _tokenId,
        uint256 _level,
        uint256 _tier,
        uint256 _staked,
        uint256 _shares,
        bytes32 _encodedAttributes,
        uint256 _unlockTime,
        uint256 _initCompleted,
        string calldata _imageUri
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                part1(_tokenId, _level, _tier, _staked, _imageUri, _initCompleted),
                                part2(_encodedAttributes, _initCompleted, _shares, _unlockTime)
                            )
                        )
                    )
                )
            );
    }

    function part1(
        uint256 _tokenId,
        uint256 _level,
        uint256 _tier,
        uint256 _staked,
        string calldata _imageUri,
        uint256 _initCompleted
    ) private pure returns (string memory) {
        string memory img = _getImageUri(_tokenId, _imageUri, _initCompleted);
        return
            string(
                abi.encodePacked(
                    '{"name":"Work X Genesis #',
                    Strings.toString(_tokenId),
                    '", "description":"This Work X Genesis NFT was obtained by being an early Work X adopter."',
                    img,
                    ',"attributes": [{"trait_type":"Level","value":',
                    Strings.toString(_level),
                    '},{"trait_type":"Tier","value":',
                    Strings.toString(_tier),
                    '},{"trait_type":"$WORK Staked","value":',
                    Strings.toString(_staked / ONE_E18)
                )
            );
    }

    function part2(
        bytes32 _encodedAttributes,
        uint256 _initCompleted,
        uint256 _shares,
        uint256 _unlockTime
    ) private view returns (string memory) {
        string[11] memory attr = decodeAttributes(_encodedAttributes, _initCompleted);

        string memory p1 = string(
            abi.encodePacked(
                '},{"trait_type":"Gender","value":"',
                attr[0],
                '"},{"trait_type":"Body","value":"',
                attr[1],
                '"},{"trait_type":"Profession","value":"',
                attr[2],
                '"},{"trait_type":"Accessories","value":"',
                attr[3],
                '"},{"trait_type":"Background","value":"',
                attr[4],
                '"},{"trait_type":"Eyes","value":"',
                attr[5]
            )
        );

        string memory p2 = string(
            abi.encodePacked(
                '"},{"trait_type":"Hair","value":"',
                attr[6],
                '"},{"trait_type":"Mouth","value":"',
                attr[7],
                '"},{"trait_type":"Complexion","value":"',
                attr[8],
                '"},{"trait_type":"Item","value":"',
                attr[9],
                '"},{"trait_type":"Clothes","value":"',
                attr[10]
            )
        );

        string memory p3 = string(
            abi.encodePacked(
                '"},{"display_type": "boost_number", "trait_type": "Shares","value":',
                Strings.toString(_shares),
                '},{"display_type": "date", "trait_type": "Tokens Unlock","value":',
                Strings.toString(_unlockTime),
                "}]}"
            )
        );

        return string(abi.encodePacked(p1, p2, p3));
    }

    function _getImageUri(
        uint256 _tokenId,
        string calldata _image,
        uint256 _initCompleted
    ) private pure returns (string memory img) {
        if (_initCompleted > 0) {
            img = string.concat(',"image":"', _image, Strings.toString(_tokenId), '.png"');
        } else {
            img = ',"image": "https://content.workx.io/video/Work-X-Lockup.mp4"';
        }
    }
}
