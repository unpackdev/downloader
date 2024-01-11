// SPDX-License-Identifier: MIT

/** ✧･ﾟ: *✧･ﾟ:*  ˢᵐᵒˡᵖʰᵘⁿᵏˢ *:･ﾟ✧*:･ﾟ✧
 * 
 * @title On-Chain SmolPhunks
 * @author ogkenobi.eth & chopperdad.eth
 * @website https://smolphunks.io
 * 
 * @description 
 * 
 *      An on-chain transformation of the original 10k CryptoPhunks NFTs
 *      Images and Attributes sourced from On-Chain CrytpoPunks by LarvaLabs
 *      Extended Attributes sourced from FashionHatPunks by middlemarch.eth
 *      Contract template sourced from CyberPhunks by @dovetailNFT & middlemarch.eth
 *   
 *✧･ﾟ: *✧･ﾟ:* for TangoTron♡ *:･ﾟ✧*:･ﾟ✧*/ 

pragma solidity 0.8.14;
pragma abicoder v2;
import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";

import "./DynamicBuffer.sol";
import "./StringUtils.sol";
import "./base64.sol";
import "./ERC721F.sol";

interface PunkDataInterface {
    function punkImage(uint16 index) external view returns (bytes memory);
    function punkAttributes(uint16 index) external view returns (string memory);
}

interface ExtendedPunkDataInterface {
        enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH, FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}

        enum PunkAttributeValue {
                NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, 
                BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, 
                CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING,
                EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN,
                GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP,
                LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS,
                NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT,
                PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS,
                SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE,
                STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR,
                WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE
                }

    function attrStringToEnumMapping(string memory) external view returns (ExtendedPunkDataInterface.PunkAttributeValue);
    function attrEnumToStringMapping(PunkAttributeValue) external view returns (string memory);
    function attrValueToTypeEnumMapping(PunkAttributeValue) external view returns (ExtendedPunkDataInterface.PunkAttributeType);
}

contract SmolPhunks is Ownable, ERC721F {
    enum PunkAttributeType {SEX, HAIR, EYES, BEARD, EARS, LIPS, MOUTH, FACE, EMOTION, NECK, NOSE, CHEEKS, TEETH}

    enum PunkAttributeValue {
                NONE, ALIEN, APE, BANDANA, BEANIE, BIG_BEARD, BIG_SHADES, BLACK_LIPSTICK, BLONDE_BOB, 
                BLONDE_SHORT, BLUE_EYE_SHADOW, BUCK_TEETH, CAP, CAP_FORWARD, CHINSTRAP, CHOKER, CIGARETTE, CLASSIC_SHADES, 
                CLOWN_EYES_BLUE, CLOWN_EYES_GREEN, CLOWN_HAIR_GREEN, CLOWN_NOSE, COWBOY_HAT, CRAZY_HAIR, DARK_HAIR, DO_RAG, EARRING,
                EYE_MASK, EYE_PATCH, FEDORA, FEMALE, FRONT_BEARD, FRONT_BEARD_DARK, FROWN, FRUMPY_HAIR, GOAT, GOLD_CHAIN,
                GREEN_EYE_SHADOW, HALF_SHAVED, HANDLEBARS, HEADBAND, HOODIE, HORNED_RIM_GLASSES, HOT_LIPSTICK, KNITTED_CAP,
                LUXURIOUS_BEARD, MALE, MEDICAL_MASK, MESSY_HAIR, MOHAWK, MOHAWK_DARK, MOHAWK_THIN, MOLE, MUSTACHE, MUTTONCHOPS,
                NERD_GLASSES, NORMAL_BEARD, NORMAL_BEARD_BLACK, ORANGE_SIDE, PEAK_SPIKE, PIGTAILS, PILOT_HELMET, PINK_WITH_HAT,
                PIPE, POLICE_CAP, PURPLE_EYE_SHADOW, PURPLE_HAIR, PURPLE_LIPSTICK, RED_MOHAWK, REGULAR_SHADES, ROSY_CHEEKS,
                SHADOW_BEARD, SHAVED_HEAD, SILVER_CHAIN, SMALL_SHADES, SMILE, SPOTS, STRAIGHT_HAIR, STRAIGHT_HAIR_BLONDE,
                STRAIGHT_HAIR_DARK, STRINGY_HAIR, TASSLE_HAT, THREE_D_GLASSES, TIARA, TOP_HAT, VAMPIRE_HAIR, VAPE, VR,
                WELDING_GOGGLES, WILD_BLONDE, WILD_HAIR, WILD_WHITE_HAIR, ZOMBIE
                }

    struct SmolPhunk {
        uint16 id;
        PunkAttributeValue sex;
        PunkAttributeValue hair;
        PunkAttributeValue eyes;
        PunkAttributeValue beard;
        PunkAttributeValue ears;
        PunkAttributeValue lips;
        PunkAttributeValue mouth;
        PunkAttributeValue face;
        PunkAttributeValue emotion;
        PunkAttributeValue neck;
        PunkAttributeValue nose;
        PunkAttributeValue cheeks;
        PunkAttributeValue teeth;
    }

    using StringUtils for string;
    using Address for address;
    using DynamicBuffer for bytes;
    using Strings for uint256;
    using Strings for uint16;
    using Strings for uint8;

    uint256 private constant costPerToken = 0.01 ether;
    uint256 private constant maxSupply = 10_000;
    uint256 public nextPhunkIndexToAssign = 0;
    uint256 public phunksRemainingToAssign = 10_000;
    bool public isMintActive;

    bytes private constant externalLink = "https://smolphunks.io";
    bytes private constant tokenDescription = "One of 10,000 tokens in the OC SmolPhunks collection, an on-chain transformation of the original CryptoPhunks.";

    PunkDataInterface private immutable punkDataContract;
    ExtendedPunkDataInterface private immutable extendedPunkDataContract;

    function flipMintState() external onlyOwner {
        isMintActive = !isMintActive;
    }

    constructor(address punkDataContractAddress, address extendedPunkDataContractAddress)
        ERC721F("OC SmolPhunks", "SMOLPHUNK") {
        punkDataContract = PunkDataInterface(punkDataContractAddress);
        extendedPunkDataContract = ExtendedPunkDataInterface(extendedPunkDataContractAddress);
    }

    function _internalMint(address toAddress, uint numTokens) private {
        require(msg.value == totalMintCost(numTokens), "Need exact payment");
        require(msg.sender == tx.origin, "Contracts cannot mint");
        require(numTokens + totalSupply() <= maxSupply, "Supply limit reached.");
        require(isMintActive, "Mint is not active");
        require(numTokens > 0, "Mint at least one");
        require(numTokens <= 30, "Mint 30 or less phunks");
        for(uint256 i; i < numTokens && phunksRemainingToAssign !=0;){
            if(!_exists(nextPhunkIndexToAssign) && nextPhunkIndexToAssign < maxSupply){
                _safeMint( toAddress, nextPhunkIndexToAssign );
                unchecked{ 
                    phunksRemainingToAssign--;
                }
            }else if(totalSupply()<maxSupply && phunksRemainingToAssign < maxSupply){ 
                unchecked{numTokens++;}
            }
            unchecked{ 
                i++;             
                nextPhunkIndexToAssign++;
            }
        }
    }

    function mint(uint numTokens) external payable {
        _internalMint(msg.sender, numTokens);
    }

    function exists(uint tokenId) internal view returns (bool) {
        return _exists(tokenId);
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");
        return constructTokenURI(uint16(id));
    }

    function constructTokenURI(uint16 tokenId) private view returns (string memory) {
        bytes memory svg = bytes(tokenImage(tokenId));
        bytes memory title = abi.encodePacked("SmolPhunk #", tokenId.toString());
        
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{',
                                '"name":"', title, '",'
                                '"description":"', tokenDescription, '",'
                                '"background_color":"638596",'
                                '"image_data":"data:image/svg+xml;base64,', Base64.encode(svg), '",'
                                '"external_url":"', externalLink, '",'
                                '"attributes": ',
                                punkAttributesAsJSON(tokenId), 
                                '}'
                            )
                        )
                    )
                )
            );
    }

    function initializePunk(uint16 punkId) private view returns (SmolPhunk memory) {
        SmolPhunk memory phunk = SmolPhunk({
            id: punkId,
            sex: PunkAttributeValue.NONE,
            hair: PunkAttributeValue.NONE,
            eyes: PunkAttributeValue.NONE,
            beard: PunkAttributeValue.NONE,
            ears: PunkAttributeValue.NONE,
            lips: PunkAttributeValue.NONE,
            mouth: PunkAttributeValue.NONE,
            face: PunkAttributeValue.NONE,
            emotion: PunkAttributeValue.NONE,
            neck: PunkAttributeValue.NONE,
            nose: PunkAttributeValue.NONE,
            cheeks: PunkAttributeValue.NONE,
            teeth: PunkAttributeValue.NONE
        });
        
        phunk.id = punkId;
        
        string memory attributes = punkDataContract.punkAttributes(phunk.id);

        string[] memory attributeArray = attributes.split(",");
        
        for (uint i = 0; i < attributeArray.length; i++) {
            string memory untrimmedAttribute = attributeArray[i];
            string memory trimmedAttribute;
            
            if (i < 1) {
                trimmedAttribute = untrimmedAttribute.split(' ')[0];
            } else {
                trimmedAttribute = untrimmedAttribute._substring(int(bytes(untrimmedAttribute).length - 1), 1);
            }
            
            PunkAttributeValue attrValue = PunkAttributeValue(uint(extendedPunkDataContract.attrStringToEnumMapping(trimmedAttribute)));
            PunkAttributeType attrType = PunkAttributeType(uint(extendedPunkDataContract.attrValueToTypeEnumMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attrValue)))));
            
            if (attrType == PunkAttributeType.SEX) {
                phunk.sex = attrValue;
            } else if (attrType == PunkAttributeType.HAIR) {
                phunk.hair = attrValue;
            } else if (attrType == PunkAttributeType.EYES) {
                phunk.eyes = attrValue;
            } else if (attrType == PunkAttributeType.BEARD) {
                phunk.beard = attrValue;
            } else if (attrType == PunkAttributeType.EARS) {
                phunk.ears = attrValue;
            } else if (attrType == PunkAttributeType.LIPS) {
                phunk.lips = attrValue;
            } else if (attrType == PunkAttributeType.MOUTH) {
                phunk.mouth = attrValue;
            } else if (attrType == PunkAttributeType.FACE) {
                phunk.face = attrValue;
            } else if (attrType == PunkAttributeType.EMOTION) {
                phunk.emotion = attrValue;
            } else if (attrType == PunkAttributeType.NECK) {
                phunk.neck = attrValue;
            } else if (attrType == PunkAttributeType.NOSE) {
                phunk.nose = attrValue;
            } else if (attrType == PunkAttributeType.CHEEKS) {
                phunk.cheeks = attrValue;
            } else if (attrType == PunkAttributeType.TEETH) {
                phunk.teeth = attrValue;
            }
        }
        
        return phunk;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function tokenImage(uint16 tokenId) public view returns (string memory) {
        bytes memory pixels = punkDataContract.punkImage(uint16(tokenId));
        bytes memory svgBytes = DynamicBuffer.allocate(1024 * 128);
        
        svgBytes.appendSafe('<svg width="600" height="600" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 240 240"><style>rect{width:1px;height:1px} g{width: 24px; height: 24px;}</style><rect x="0" y="0" style="width:100%;height:100%" fill="#638596" /><g style="transform: translate(calc(50% - 12px), calc(50% - 12px))">');
        
        bytes memory buffer = new bytes(8);
        for (uint256 y = 0; y < 24; y++) {
            for (uint256 x = 0; x < 24; x++) {
                uint256 p = (y * 24 + x) * 4;
                if (uint8(pixels[p + 3]) > 0) {
                    for (uint256 i = 0; i < 4; i++) {
                        uint8 value = uint8(pixels[p + i]);
                        
                        buffer[i * 2 + 1] = _HEX_SYMBOLS[value & 0xf];
                        value >>= 4;
                        buffer[i * 2] = _HEX_SYMBOLS[value & 0xf];
                    }

                    string memory oldColor = string(buffer);
                    
                    uint flippedX = 23 - x;
                    
                    svgBytes.appendSafe(
                        abi.encodePacked(
                            '<rect x="',
                            flippedX.toString(),
                            '" y="',
                            y.toString(),
                            '" fill="#',
                            oldColor,
                            '"/>'
                        )
                    );
                }
            }
        }
        
        svgBytes.appendSafe('</g></svg>');
        return string(svgBytes);
    }

    address constant chopperAddress = 0xda27bF313dCeF0Ee3916c9506A6Ad45F306F9F3b;
    address constant kenobiAddress = 0x68b6Ba6385a5d395c1ff73c79c9cB2bD2D614dBC;
    address constant claireAddress = 0x015F08Af4Fe34e94BF363034b62033FE5167eC32;

    function withdraw() external {
        require(address(this).balance > 0, "Nothing to withdraw");
        
        uint total = address(this).balance;
        uint fiver = (total * 5) / 100; // 5% to da goat
        uint half = (total - fiver) / 2;
        
        Address.sendValue(payable(claireAddress), fiver);
        Address.sendValue(payable(chopperAddress), half);
        Address.sendValue(payable(kenobiAddress), total - (half + fiver));
    }

    function totalMintCost(uint numTokens) private pure returns (uint256) {
        return numTokens * costPerToken;
    }

    function punkAttributeCount(SmolPhunk memory phunk) private pure returns (uint totalCount) {
        PunkAttributeValue[13] memory attrArray = [
            phunk.sex,
            phunk.hair,
            phunk.eyes,
            phunk.beard,
            phunk.ears,
            phunk.lips,
            phunk.mouth,
            phunk.face,
            phunk.emotion,
            phunk.neck,
            phunk.nose,
            phunk.cheeks,
            phunk.teeth
        ];
        
        for (uint i = 0; i < 13; ++i) {
            if (attrArray[i] != PunkAttributeValue.NONE) {
                totalCount++;
            }
        }
        // Don't count sex as an attribute
        totalCount--;
    }

    function punkAttributesAsJSON(uint16 punkId) public view returns (string memory json) {
        SmolPhunk memory phunk = initializePunk(punkId);
        PunkAttributeValue none = PunkAttributeValue.NONE;
        
        bytes memory output = "[";
        
        PunkAttributeValue[13] memory attrArray = [
            phunk.sex,
            phunk.hair,
            phunk.eyes,
            phunk.beard,
            phunk.ears,
            phunk.lips,
            phunk.mouth,
            phunk.face,
            phunk.emotion,
            phunk.neck,
            phunk.nose,
            phunk.cheeks,
            phunk.teeth
        ];

        uint attrCount = punkAttributeCount(phunk);
        uint count = 0;

        for (uint i = 0; i < 13; ++i) {
            PunkAttributeValue attrVal = attrArray[i];

            if (attrVal != none) {
                output = abi.encodePacked(output, punkAttributeAsJSON(attrVal));

                if (count < attrCount) {
                    output.appendSafe(",");
                    ++count;
                }
            }
        }
        
        return string(abi.encodePacked(output, "]"));
    }

    function punkAttributeAsJSON(PunkAttributeValue attribute) internal view returns (string memory json) {
        require(attribute != PunkAttributeValue.NONE);

        string memory attributeAsString = extendedPunkDataContract.attrEnumToStringMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attribute)));
        string memory attributeTypeAsString;
        
        PunkAttributeType attrType = PunkAttributeType(uint(extendedPunkDataContract.attrValueToTypeEnumMapping(ExtendedPunkDataInterface.PunkAttributeValue(uint(attribute)))));

        if (attrType == PunkAttributeType.SEX) {
            attributeTypeAsString = "Sex";
        } else if (attrType == PunkAttributeType.HAIR) {
            attributeTypeAsString = "Hair";
        } else if (attrType == PunkAttributeType.EYES) {
            attributeTypeAsString = "Eyes";
        } else if (attrType == PunkAttributeType.BEARD) {
            attributeTypeAsString = "Beard";
        } else if (attrType == PunkAttributeType.EARS) {
            attributeTypeAsString = "Ears";
        } else if (attrType == PunkAttributeType.LIPS) {
            attributeTypeAsString = "Lips";
        } else if (attrType == PunkAttributeType.MOUTH) {
            attributeTypeAsString = "Mouth";
        } else if (attrType == PunkAttributeType.FACE) {
            attributeTypeAsString = "Face";
        } else if (attrType == PunkAttributeType.EMOTION) {
            attributeTypeAsString = "Emotion";
        } else if (attrType == PunkAttributeType.NECK) {
            attributeTypeAsString = "Neck";
        } else if (attrType == PunkAttributeType.NOSE) {
            attributeTypeAsString = "Nose";
        } else if (attrType == PunkAttributeType.CHEEKS) {
            attributeTypeAsString = "Cheeks";
        } else if (attrType == PunkAttributeType.TEETH) {
            attributeTypeAsString = "Teeth";
        }
        
        return string(abi.encodePacked('{"trait_type":"', attributeTypeAsString, '", "value":"', attributeAsString, '"}'));
    }
}