// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./base64.sol";
import "./IBrawlerBearzRenderer.sol";
import "./IBrawlerBearzDynamicItems.sol";
import "./IBrawlerBearzErrors.sol";
import "./IBrawlerBearzConsumables.sol";
import "./Genes.sol";

/*******************************************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|(@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|,|@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@|,*|&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%,**%@@@@@@@@%|******%&@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##*****|||**,(%%%%%**|%@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@***,#%%%%**#&@@@@@#**,|@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*,(@@@@@@@@@@**,(&@@@@#**%@@@@@@||(%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%|,****&@((@&***&@@@@@@%||||||||#%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@&%#*****||||||**#%&@%%||||||||#@&%#(@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@&**,(&@@@@@%|||||*##&&&&##|||||(%@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@**,%@@@@@@@(|*|#%@@@@@@@@#||#%%@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@#||||#@@@@||*|%@@@@@@@@&|||%%&@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@#,,,,,,*|**||%|||||||###&@@@@@@@#|||#%@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@&#||*|||||%%%@%%%#|||%@@@@@@@@&(|(%&@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@&&%%(||||@@@@@@&|||||(%&((||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@%%(||||||||||#%#(|||||%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&%#######%%@@**||(#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%##%%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
********************************************************************************/

/**************************************************
 * @title BrawlerBearzRenderer
 * @author @scottybmitch
 **************************************************/

contract BrawlerBearzRenderer is
    IBrawlerBearzRenderer,
    IBrawlerBearzErrors,
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    using StringsUpgradeable for uint256;
    using Genes for uint256;

    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");

    uint256 constant STR_BASIS = 100;
    uint256 constant END_BASIS = 100;
    uint256 constant INT_BASIS = 100;
    uint256 constant LCK_BASIS = 10;
    uint256 constant XP_BASIS = 2000;

    /// @notice Base URI for assets
    string public baseURI;

    /// @notice Animation URI for assets
    string public animationURI;

    /// @notice parent contract
    IERC721Upgradeable public parentContract;

    /// @notice Vendor contract
    IBrawlerBearzDynamicItems public vendorContract;

    /// @notice Consumables contract
    IBrawlerBearzConsumables public consumableContract;

    // ========================================
    // Modifiers
    // ========================================

    modifier isTokenOwner(uint256 tokenId) {
        if (parentContract.ownerOf(tokenId) != _msgSender()) {
            revert InvalidOwner();
        }
        _;
    }

    modifier isItemTokenOwner(uint256 itemTokenId) {
        if (vendorContract.balanceOf(_msgSender(), itemTokenId) == 0) {
            revert InvalidOwner();
        }
        _;
    }

    function initialize(
        string memory _baseURI,
        string memory _animationURI
    ) public initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(OWNER_ROLE, _msgSender());

        baseURI = _baseURI;
        animationURI = _animationURI;
    }

    function toJSONProperty(
        string memory key,
        string memory value
    ) public pure returns (string memory) {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function toJSONNumberAttribute(
        string memory key,
        string memory value
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '", "display_type": "number"',
                    "}"
                )
            );
    }

    function toJSONAttribute(
        string memory key,
        string memory value
    ) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{ "trait_type":"',
                    key,
                    '", "value": "',
                    value,
                    '"}'
                )
            );
    }

    function toJSONAttributeList(
        string[] memory attributes
    ) internal pure returns (string memory) {
        bytes memory attributeListBytes = "[";
        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }
        return string(attributeListBytes);
    }

    function gaussianTrait(
        uint256 seed,
        uint256 numSampling,
        uint256 samplingBits
    ) internal pure returns (uint256 trait) {
        uint256 samplingMask = (1 << samplingBits) - 1;
        unchecked {
            for (uint256 i = 0; i < numSampling; i++) {
                trait += (seed >> (i * samplingBits)) & samplingMask;
            }
        }
        return trait;
    }

    function factionIdToName(
        uint256 factionId
    ) internal pure returns (string memory) {
        if (factionId == 1) {
            return "IRONBEARZ";
        } else if (factionId == 2) {
            return "GEOSCAPEZ";
        } else if (factionId == 3) {
            return "PAWPUNKZ";
        } else if (factionId == 4) {
            return "TECHHEADZ";
        } else {
            return "NOMAD";
        }
    }

    function getHiddenProperties(
        uint256 tokenId
    ) internal view returns (Bear memory) {
        Traits memory traits;
        CustomMetadata memory dynamic;
        return
            Bear({
                name: string(
                    abi.encodePacked(
                        "Brawler #",
                        StringsUpgradeable.toString(tokenId)
                    )
                ),
                description: "Fight or die. This is the life of the brawlers...",
                dna: "hidden",
                renderingDna: "hidden",
                traits: traits,
                dynamic: dynamic
            });
    }

    function createRenderingDna(
        uint256 chromosome,
        CustomMetadata memory md
    ) internal view returns (uint256) {
        uint256 renderingChromosomes = 0;

        // Background
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getBackground(chromosome);

        // Skin
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getSkin(chromosome);

        // Head
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getHead(chromosome);

        // Eyes
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getEyes(chromosome);

        // Mouth
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getMouth(chromosome);

        // Outfit
        renderingChromosomes <<= 16;
        renderingChromosomes |= Genes.getOutfit(chromosome);

        // Set dynamic background
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.background > 0 ? md.background : 0;

        // Set dynamic weapon
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.weapon > 0 ? md.weapon : 0;

        // Set dynamic armor
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.armor > 0 ? md.armor : 0;

        // Set dynamic face armor
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.faceArmor > 0 ? md.faceArmor : 0;

        // Set dynamic eyewear
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.eyewear > 0 ? md.eyewear : 0;

        // Set dynamic misc
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.misc > 0 ? md.misc : 0;

        // Set dynamic head
        renderingChromosomes <<= 16;
        renderingChromosomes |= md.head > 0 ? md.head : 0;

        return renderingChromosomes;
    }

    function getProperties(
        uint256 tokenId,
        uint256 seed,
        CustomMetadata memory md
    ) internal view returns (Bear memory) {
        uint256 chromosome = Genes.seedToChromosome(seed);

        Traits memory traits;
        CustomMetadata memory dynamic;

        // Faction
        traits.faction = factionIdToName(md.faction);
        dynamic.faction = md.faction;

        // Evolving
        traits.level = 1 + (md.xp > 0 ? sqrt(md.xp / XP_BASIS) : 0);
        traits.locked = md.isUnlocked ? "FALSE" : "TRUE";

        traits.strength =
            traits.level *
            (STR_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("strength")))
                        )
                    ),
                    5,
                    5
                ));

        traits.endurance =
            traits.level *
            (END_BASIS +
                gaussianTrait(
                    (
                        uint256(
                            keccak256(abi.encode(seed, keccak256("endurance")))
                        )
                    ),
                    5,
                    5
                ));

        traits.intelligence = (INT_BASIS +
            gaussianTrait(
                (
                    uint256(
                        keccak256(abi.encode(seed, keccak256("intelligence")))
                    )
                ),
                5,
                5
            ));

        traits.luck =
            (LCK_BASIS +
                gaussianTrait(
                    (uint256(keccak256(abi.encode(seed, keccak256("luck"))))),
                    3,
                    3
                )) %
            100;

        traits.xp = md.xp;

        // Base traits
        traits.skin = Genes.getSkinValue(chromosome);
        traits.head = Genes.getHeadValue(chromosome);
        traits.eyes = Genes.getEyesValue(chromosome);
        traits.outfit = Genes.getOutfitValue(chromosome);
        traits.mouth = Genes.getMouthValue(chromosome);
        traits.background = Genes.getBackgroundValue(chromosome);

        // Dynamic traits
        dynamic.background = 0; // Has default + dynamic background

        traits.weapon = "NONE";
        dynamic.weapon = 0;

        traits.armor = "NONE";
        dynamic.armor = 0;

        traits.faceArmor = "NONE";
        dynamic.faceArmor = 0;

        traits.eyewear = "NONE";
        dynamic.eyewear = 0;

        traits.misc = "NONE";
        dynamic.misc = 0;

        // Set dynamic background
        if (md.background > 0) {
            traits.background = vendorContract.getItemName(md.background);
            dynamic.background = md.background;
        }

        // Set dynamic weapon
        if (md.weapon > 0) {
            traits.weapon = vendorContract.getItemName(md.weapon);
            dynamic.weapon = md.weapon;
        }

        // Set dynamic armor
        if (md.armor > 0) {
            traits.armor = vendorContract.getItemName(md.armor);
            dynamic.armor = md.armor;
        }

        // Set dynamic face armor
        if (md.faceArmor > 0) {
            traits.faceArmor = vendorContract.getItemName(md.faceArmor);
            dynamic.faceArmor = md.faceArmor;
        }

        // Set dynamic eyewear
        if (md.eyewear > 0) {
            traits.eyewear = vendorContract.getItemName(md.eyewear);
            dynamic.eyewear = md.eyewear;
        }

        // Set dynamic misc
        if (md.misc > 0) {
            traits.misc = vendorContract.getItemName(md.misc);
            dynamic.misc = md.misc;
        }

        // Set dynamic head
        if (md.head > 0) {
            traits.head = vendorContract.getItemName(md.head);
            dynamic.head = md.head;
        }

        return
            Bear({
                name: (bytes(md.name).length > 0)
                    ? md.name
                    : string(
                        abi.encodePacked(
                            "Brawler #",
                            StringsUpgradeable.toString(tokenId)
                        )
                    ),
                description: (bytes(md.lore).length > 0) ? md.lore : "",
                dna: StringsUpgradeable.toString(chromosome),
                renderingDna: StringsUpgradeable.toString(
                    createRenderingDna(chromosome, md)
                ),
                traits: traits,
                dynamic: dynamic
            });
    }

    // ========================================
    // NFT display helpers
    // ========================================

    /**
     * @notice Sets the base URI for the image asset
     * @param _baseURI A base uri
     */
    function setBaseURI(string memory _baseURI) external onlyRole(OWNER_ROLE) {
        baseURI = _baseURI;
    }

    /**
     * @notice Sets the animation URI for the image asset
     * @param _animationURI A base uri
     */
    function setAnimationURI(
        string memory _animationURI
    ) external onlyRole(OWNER_ROLE) {
        animationURI = _animationURI;
    }

    /**
     * @notice Returns a json list of dynamic properties
     * @param instance A bear instance
     */
    function toDynamicProperties(
        Bear memory instance
    ) internal view returns (string memory) {
        string[] memory dynamic = new string[](15);

        dynamic[0] = toJSONAttribute(
            "Background Id",
            StringsUpgradeable.toString(instance.dynamic.background)
        );

        dynamic[1] = toJSONAttribute(
            "Background Name",
            vendorContract.getItemName(instance.dynamic.background)
        );

        dynamic[2] = toJSONAttribute(
            "Weapon Id",
            StringsUpgradeable.toString(instance.dynamic.weapon)
        );

        dynamic[3] = toJSONAttribute(
            "Weapon Name",
            vendorContract.getItemName(instance.dynamic.weapon)
        );

        dynamic[4] = toJSONAttribute(
            "Face Armor Id",
            StringsUpgradeable.toString(instance.dynamic.faceArmor)
        );

        dynamic[5] = toJSONAttribute(
            "Face Armor Name",
            vendorContract.getItemName(instance.dynamic.faceArmor)
        );

        dynamic[6] = toJSONAttribute(
            "Armor Id",
            StringsUpgradeable.toString(instance.dynamic.armor)
        );

        dynamic[7] = toJSONAttribute(
            "Armor Name",
            vendorContract.getItemName(instance.dynamic.armor)
        );

        dynamic[8] = toJSONAttribute(
            "Eyewear Id",
            StringsUpgradeable.toString(instance.dynamic.eyewear)
        );

        dynamic[9] = toJSONAttribute(
            "Eyewear Name",
            vendorContract.getItemName(instance.dynamic.eyewear)
        );

        dynamic[10] = toJSONAttribute(
            "Misc Id",
            StringsUpgradeable.toString(instance.dynamic.misc)
        );

        dynamic[11] = toJSONAttribute(
            "Misc Name",
            vendorContract.getItemName(instance.dynamic.misc)
        );

        dynamic[12] = toJSONAttribute(
            "Faction Id",
            StringsUpgradeable.toString(instance.dynamic.faction)
        );

        dynamic[13] = toJSONAttribute(
            "Head Id",
            StringsUpgradeable.toString(instance.dynamic.head)
        );

        dynamic[14] = toJSONAttribute(
            "Head Name",
            vendorContract.getItemName(instance.dynamic.head)
        );

        return toJSONAttributeList(dynamic);
    }

    /**
     * @notice Sets the bearz consumables contract
     * @dev only owner call this function
     * @param _consumableContract The new contract address
     */
    function setConsumableContract(
        address _consumableContract
    ) public onlyRole(OWNER_ROLE) {
        consumableContract = IBrawlerBearzConsumables(_consumableContract);
    }

    /**
     * @notice Sets the bearz contract
     * @dev only owner call this function
     * @param _parentContractAddress The new contract address
     */
    function setParentContract(
        address _parentContractAddress
    ) public onlyRole(OWNER_ROLE) {
        parentContract = IERC721Upgradeable(_parentContractAddress);
    }

    /**
     * @notice Sets the bearz vendor item contract
     * @dev only owner call this function
     * @param _vendorContractAddress The new contract address
     */
    function setVendorContract(
        address _vendorContractAddress
    ) public onlyRole(OWNER_ROLE) {
        vendorContract = IBrawlerBearzDynamicItems(_vendorContractAddress);
    }

    /**
     * @notice Returns a json list of attribute properties
     * @param instance A bear instance
     */
    function toAttributesProperty(
        Bear memory instance
    ) internal pure returns (string memory) {
        string[] memory attributes = new string[](19);

        attributes[0] = toJSONAttribute("Head", instance.traits.head);

        attributes[1] = toJSONAttribute("Skin", instance.traits.skin);

        attributes[2] = toJSONAttribute("Eyes", instance.traits.eyes);

        attributes[3] = toJSONAttribute("Outfit", instance.traits.outfit);

        attributes[4] = toJSONAttribute("Mouth", instance.traits.mouth);

        attributes[5] = toJSONAttribute(
            "Background",
            instance.traits.background
        );

        attributes[6] = toJSONAttribute("Armor", instance.traits.armor);

        attributes[7] = toJSONAttribute(
            "Face Armor",
            instance.traits.faceArmor
        );

        attributes[8] = toJSONAttribute("Eyewear", instance.traits.eyewear);

        attributes[9] = toJSONAttribute("Weapon", instance.traits.weapon);

        attributes[10] = toJSONAttribute("Miscellaneous", instance.traits.misc);

        attributes[11] = toJSONNumberAttribute(
            "XP",
            StringsUpgradeable.toString(instance.traits.xp)
        );

        attributes[12] = toJSONNumberAttribute(
            "Level",
            StringsUpgradeable.toString(instance.traits.level)
        );

        attributes[13] = toJSONNumberAttribute(
            "Strength",
            StringsUpgradeable.toString(instance.traits.strength)
        );

        attributes[14] = toJSONNumberAttribute(
            "Endurance",
            StringsUpgradeable.toString(instance.traits.endurance)
        );

        attributes[15] = toJSONNumberAttribute(
            "Intelligence",
            StringsUpgradeable.toString(instance.traits.intelligence)
        );

        attributes[16] = toJSONNumberAttribute(
            "Luck",
            StringsUpgradeable.toString(instance.traits.luck)
        );

        attributes[17] = toJSONAttribute("Is Locked", instance.traits.locked);

        attributes[18] = toJSONAttribute("Faction", instance.traits.faction);

        return toJSONAttributeList(attributes);
    }

    /**
     * @notice Returns hidden base64 json metadata
     * @param _tokenId The bear token id
     */
    function hiddenURI(uint256 _tokenId) public view returns (string memory) {
        Bear memory instance = getHiddenProperties(_tokenId);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    string(
                                        abi.encodePacked(baseURI, instance.dna)
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            animationURI,
                                            instance.dna
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    StringsUpgradeable.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty("dna", instance.dna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    /// @notice Returns the dna for a given token, seed, and metadata
    function baseDna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
        return instance.dna;
    }

    /// @notice Returns the dna for a given token, seed, and metadata
    function dna(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);
        return instance.renderingDna;
    }

    function standardProperties(
        uint256 tokenId,
        Bear memory instance
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    toJSONProperty("name", instance.name),
                    ",",
                    toJSONProperty("description", instance.description),
                    ",",
                    toJSONProperty(
                        "image",
                        string(abi.encodePacked(baseURI, instance.renderingDna))
                    ),
                    ",",
                    toJSONProperty(
                        "animation_url",
                        string(
                            abi.encodePacked(
                                animationURI,
                                StringsUpgradeable.toString(tokenId)
                            )
                        )
                    ),
                    ",",
                    toJSONProperty(
                        "external_url",
                        string(
                            abi.encodePacked(
                                animationURI,
                                StringsUpgradeable.toString(tokenId)
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Returns a base64 json metadata
     * @param _tokenId The bear token id
     * @param _seed The generated seed
     * @param _md The custom metadata
     */
    function tokenURI(
        uint256 _tokenId,
        uint256 _seed,
        CustomMetadata memory _md
    ) public view returns (string memory) {
        Bear memory instance = getProperties(_tokenId, _seed, _md);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                standardProperties(_tokenId, instance),
                                ",",
                                abi.encodePacked(
                                    '"attributes": ',
                                    toAttributesProperty(instance)
                                ),
                                ",",
                                abi.encodePacked(
                                    '"consumables": ',
                                    consumableContract.toConsumableProperties(
                                        _tokenId
                                    )
                                ),
                                ",",
                                abi.encodePacked(
                                    '"equipped": ',
                                    toDynamicProperties(instance)
                                ),
                                ",",
                                toJSONProperty(
                                    "tokenId",
                                    StringsUpgradeable.toString(_tokenId)
                                ),
                                ",",
                                toJSONProperty(
                                    "seed",
                                    StringsUpgradeable.toString(_seed)
                                ),
                                ",",
                                toJSONProperty("base", instance.dna),
                                ",",
                                toJSONProperty("dna", instance.renderingDna),
                                "}"
                            )
                        )
                    )
                )
            );
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        } else z = 0;
    }
}
