// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Strings.sol";
import "./Attempt.sol";
import "./Miner.sol";
import "./PackedVars.sol";
import "./AssetRenderer1.sol";
import "./AssetRenderer2.sol";
import "./AssetRenderer3.sol";
import "./AssetRenderer4.sol";
import "./AssetRenderer5.sol";
import "./Calcs.sol";
import "./LgSVG.sol";
import "./SmSVG.sol";

library Metadata {
    using Strings for *;

    /**
    * @notice build metadata strings for a miner
    * @param attempt the attempt struct for this miner
    * @param minerIn the miner struct to ingest
    * @param chambers an array of chamber hashes
    * @return array of strings (first json metadata, second image data)
    */
    function build(Attempt memory attempt, Miner memory minerIn, bytes32[47] memory chambers)
        external
        pure
        returns(string memory,string memory)
    {
        // Define a PackedVars struct to efficiently assign/reassign values during calculation
        PackedVars memory packedData;

        // Check if an attempt has started yet
        if(attempt.startTokenId == 0){
            // Attempt has not started - generate miner
            (Miner memory miner, string memory metaAttributes) = _initCodeGen(
                minerIn,
                packedData
            );

            // Set svgBody to large miner render
            string memory svgBody = _lgRender(miner);

            // Return the metadata and image data
            return (
                metaAttributes,
                LgSVG.render(
                    Calcs.ctString(attempt.hash),
                    svgBody,
                    1,
                    7
                )
            );
        } else {
            (Miner memory miner, string memory svgBody, string memory metaAttributes) = _codeGen(
                minerIn,
                chambers,
                packedData
            );

            if(miner.health <= 0 || miner.currentChamber == 46){
                // Miner is dead or won!

                // Set svgBody to large miner render
                svgBody = _lgRender(miner);
                if(miner.currentChamber == 46){
                    // Winner winner, chicken dinner!

                    // Set background value to 2
                    packedData.var_uint8_2 = 2;

                    // Set frame value to 6
                    packedData.var_uint8_1 = 6;
                } else {
                    // Miner es muerto;

                    // Set frame value to current floor
                    packedData.var_uint8_1 = (miner.currentChamber / 8);
                }
                // Return the metadata and image data
                return (
                    metaAttributes,
                    LgSVG.render(
                        Calcs.ctString(attempt.hash),
                        svgBody,
                        packedData.var_uint8_2,
                        packedData.var_uint8_1
                    )
                );
            } else {
                // Miner is alive!
                // Define string var for bottom stats attributes based on attempt stats
                string memory minerStats;

                // Loop through all gear types to generate style tags for miner
                for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 5; packedData.var_uint8_1++){
                    // Generate and append color defs to the minerStats var
                    if(packedData.var_uint8_1 == 0){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer1.cssSkinVar(miner.skintoneId)
                        ));
                    } else if(packedData.var_uint8_1 == 1){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.armorId])
                            AssetRenderer1.cssVar(miner.armorId)
                        ));
                    } else if(packedData.var_uint8_1 == 2){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.pantsId])
                            AssetRenderer1.cssVar(miner.pantsId)
                        ));
                    } else if(packedData.var_uint8_1 == 3){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.footwearId])
                            AssetRenderer1.cssVar(miner.footwearId)
                        ));
                    } else if(packedData.var_uint8_1 == 4){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            // AssetRenderer1.cssVar(GEAR[miner.weaponId])
                            AssetRenderer1.cssVar(miner.weaponId)
                        ));
                    }
                }
                for(packedData.var_uint8_2 = 0; packedData.var_uint8_2 < 7; packedData.var_uint8_2++){
                    // Generate and append avatar image data to the minerStats var
                    if(packedData.var_uint8_2 == 0){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderCape(uint16(Calcs.armorStats(miner.armorId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 1){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderPants(uint16(Calcs.pantsStats(miner.pantsId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 2){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderFootwear(uint16(Calcs.footwearStats(miner.footwearId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 3){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderArmor(uint16(Calcs.armorStats(miner.armorId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 4){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            '%253Cg fill=\'var(--dms)\'%253E%253Cpath d=\'M8,4h5v5h-5z\'/%253E%253Cpath d=\'M4,14h3v3h-3zM16,14h3v3h-3z\'/%253E%253C/g%253E'
                        ));
                    } else if(packedData.var_uint8_2 == 5){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer4.renderHeadgear(uint16(Calcs.headgearStats(miner.headgearId)[4]))
                        ));
                    } else if(packedData.var_uint8_2 == 6){
                        minerStats = string(abi.encodePacked(
                            minerStats,
                            AssetRenderer1.weapon(uint16(Calcs.weaponStats(miner.weaponId)[4])),
                            '%253C/g%253E'
                        ));
                    }
                }

                // Loop through all miner stats to generate image data for bottom stats bar
                for(packedData.var_uint8_3 = 0; packedData.var_uint8_3 < 6; packedData.var_uint8_3++){
                    // Generate and append miner stats image data to the minerStats var
                    minerStats = string(abi.encodePacked(
                        minerStats,
                        AssetRenderer1.smMinerStat(packedData.var_uint8_3,miner)
                    ));
                }

                // Return the metadata and image data
                return (
                    metaAttributes,
                    SmSVG.render(
                        svgBody,
                        minerStats
                    )
                );
            }
        }
    }

    /**
    * @notice render a miner portrait
    * @param miner the miner struct
    * @return string of miner portrait image data
    */
    function _lgRender(Miner memory miner)
        internal
        pure
        returns(string memory)
    {
        PackedVars memory packedData;
        string memory svgBody;

        // Loop through all gear types to generate style tags for miner
        for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 11; packedData.var_uint8_1++){
            // Generate and append color defs to the svgBody var
            if(packedData.var_uint8_1 == 0){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssSkinVar(miner.skintoneId)
                ));
            } else if(packedData.var_uint8_1 == 1){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssHairVar(miner.hairColorId)
                ));
            } else if(packedData.var_uint8_1 == 2){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.cssEyeVar(miner.eyeColorId)
                ));
            } else if(packedData.var_uint8_1 == 3){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    LgSVG.renderBase(miner.genderId,miner.classId,miner.eyeTypeId,miner.mouthId)
                ));
            } else if(packedData.var_uint8_1 == 4){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer3.renderArmor(uint16(Calcs.armorStats(miner.armorId)[5]))
                ));
            } else if(packedData.var_uint8_1 == 5){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer2.renderHairDefs(uint16(Calcs.headgearStats(miner.headgearId)[5]),miner.hairTypeId,miner.genderId)
                ));
            } else if(packedData.var_uint8_1 == 6){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    // AssetRenderer3.renderHair(miner.hairTypeId,GEAR[miner.headgearId].lgAssetId)
                    AssetRenderer3.renderHair(miner.hairTypeId,uint16(Calcs.headgearStats(miner.headgearId)[5]))
                ));
            } else if(packedData.var_uint8_1 == 7){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    LgSVG.renderMod((miner.genderId * 4) + miner.classId)
                ));
            } else if(packedData.var_uint8_1 == 8){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    // AssetRenderer2.renderHeadgear(GEAR[miner.headgearId].lgAssetId,miner.genderId)
                    AssetRenderer2.renderHeadgear(uint16(Calcs.headgearStats(miner.headgearId)[5]),miner.genderId)
                ));
            } else if(packedData.var_uint8_1 == 9 && miner.classId == 2){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer2.renderEarMod(miner.headgearId)
                ));
            } else if(packedData.var_uint8_1 == 10){
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer5.renderWeapon(uint16(Calcs.weaponStats(miner.weaponId)[5]))
                ));
            }
        }
        return svgBody;
    }

    /**
    * @notice return the name of a gear item
    * @param gearId the gear id of the gear item
    * @return string of quotation mark-wrapped gear item
    */
    function _gearName(uint8 gearId)
        internal
        pure
        returns(string memory)
    {
        if(gearId < 17){
            // Headgear
            return ['"None"','"Bandana"','"Leather Hat"','"Rusty Helm"','"Feathered Cap"','"Enchanted Crown"','"Bronze Helm"','"Assassin\'s Mask"','"Iron Helm"','"Skull Helm"','"Charmed Headband"','"Ranger Cap"','"Misty Hood"','"Phoenix Helm"','"Ancient Mask"','"Genesis Helm"','"Soul Shroud"'][gearId];
        } else if(gearId < 34){
            // Armor - 17
            return ['"Cotton Shirt"','"Thick Vest"','"Leather Chestplate"','"Rusty Chainmail"','"Longcoat"','"Chainmail"','"Bronze Chestplate"','"Blessed Armor"','"Iron Chestplate"','"Skull Armor"','"Cape of Deception"','"Mystic Cloak"','"Shimmering Cloak"','"Phoenix Chestplate"','"Ancient Robe"','"Genesis Cloak"','"Soul Cloak"'][gearId - 17];
        } else if(gearId < 51){
            // Pants - 34
            return ['"Cotton Pants"','"Thick Pants"','"Leather Greaves"','"Rusty Chainmail Pants"','"Reliable Leggings"','"Padded Leggings"','"Bronze Greaves"','"Enchanted Pants"','"Iron Greaves"','"Skull Greaves"','"Swift Leggings"','"Forest Greaves"','"Silent Leggings"','"Phoenix Greaves"','"Ancient Greaves"','"Genesis Greaves"','"Soul Greaves"'][gearId - 34];
        } else if(gearId < 68){
            // Footwear - 51
            return ['"None"','"Sturdy Cleats"','"Leather Boots"','"Rusty Boots"','"Lightweight Shoes"','"Bandit\'s Shoes"','"Bronze Boots"','"Heavy Boots"','"Iron Boots"','"Skull Boots"','"Enchanted Boots"','"Jaguarpaw Boots"','"Lightfoot Boots"','"Phoenix Boots"','"Ancient Boots"','"Genesis Boots"','"Soul Boots"'][gearId - 51];
        } else {
            // Weapons - 68
            return ['"Fists"','"Rusty Sword"','"Wooden Club"','"Pickaxe"','"Brass Knuckles"','"Weathered Greataxe"','"Polished Scepter"','"Poisoned Spear"','"Kusarigama"','"Bronze Sword"','"Bronze Staff"','"Bronze Shortsword"','"Bronze Daggers"','"Dusty Scmitar"','"Silver Wand"','"Dual Handaxes"','"Dual Shortswords"','"Holy Sword"','"Holy Staff"','"Holy Bow"','"Holy Daggers"','"Soulcutter"','"Shadow Staff"','"Shadow Bow"','"Shadowblades"','"Phoenix Blade"','"Ancient Scepter"','"Genesis Bow"','"Soul Daggers"'][gearId - 68];
        }
    }

    /**
    * @notice calculate the result of an escape attempt and return miner, metadata and image data
    * @param minerIn the miner struct to ingest
    * @param chambers an array of chamber hashes
    * @param packedData a packed struct of variables
    * @return array of miner struct, metadata string and image data string
    */
    function _codeGen(Miner memory minerIn, bytes32[47] memory chambers, PackedVars memory packedData)
        internal
        pure
        returns (Miner memory, string memory, string memory)
    {
        // Define string var for all chambers image data starting with the initial chamber
        Miner memory miner = minerIn;

        // Define string var for all chambers image data starting with the initial chamber
        string memory svgBody = string(abi.encodePacked(
            AssetRenderer1.smChamber(
                'a',
                Calcs.ctString(chambers[0]),
                'x',
                0
            )
        ));

        // Loop through all chambers and calculate attempt data
        for(packedData.var_uint8_1 = 1; packedData.var_uint8_1 < 47; packedData.var_uint8_1++){
            // Check if the miner is alive
            if(miner.health > 0){
                // The miner lives! Do chambery shit

                // Check if the current chamber has been mined yet
                if(chambers[packedData.var_uint8_1] != bytes32(0)){
                    // This chamber has been mined! Do more chambery shit

                    // Set the current chamber to current loop value
                    miner.currentChamber = packedData.var_uint8_1;

                    // Calculate and return the miner and stats after traversing this chamber
                    miner = Calcs.chamberStats(keccak256(abi.encodePacked(chambers[0],chambers[packedData.var_uint8_1])),miner);

                    // Generate and append chamber image data to the svgBody var
                    svgBody = string(abi.encodePacked(
                        svgBody,
                        AssetRenderer1.smChamber(
                            'a',
                            Calcs.ctString(chambers[packedData.var_uint8_1]),
                            Calcs.etString(keccak256(abi.encodePacked(chambers[0],chambers[packedData.var_uint8_1]))),
                            packedData.var_uint8_1
                        )
                    ));
                } else {
                    // This chamber hasn't been mined yet

                    // Generate and append pending chamber image data to the svgBody var
                    svgBody = string(abi.encodePacked(
                        svgBody,
                        chambers[packedData.var_uint8_1 - 1] != bytes32(0) ? AssetRenderer1.smNext(packedData.var_uint8_1) : '',
                        AssetRenderer1.smChamber('u','x','x',packedData.var_uint8_1)
                    ));
                }
            } else {
                // Break the loop
                break;
            }
        }

        // Append status elements to the svgBody var
        svgBody = string(abi.encodePacked(
            svgBody,
            '%253Cg class=\'se\' transform=\'translate(4,88)\'%253E'
        ));
        if(miner.buffTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm18)\'/%253E'
            ));
        }
        if(miner.debuffTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm6)\'/%253E'
            ));
        }
        if(miner.curseTurns > 0){
            // Add buff indicator
            svgBody = string(abi.encodePacked(
                svgBody,
                '%253Cpath d=\'M10,10h2v2h-2z\' fill=\'var(--dm3)\'/%253E'
            ));
        }
        svgBody = string(abi.encodePacked(
            svgBody,
            '%253C/g%253E'
        ));

        // Define string var for JSON attributes based on attempt stats
        string memory metaAttributes;

        // Check if miner is still alive after all chambers have been calculated
        if(miner.health > 0){
            // Still alive!

            // Check if the miner has reached the exit
            if(miner.currentChamber == 46){
                // Winner winner, chicken dinner!
                metaAttributes = '{"trait_type":"Miner Status","value":"Escaped"}';

            } else {
                // Attempt is in progress

                metaAttributes = '{"trait_type":"Miner Status","value":"Exploring"}';

                // Generate and append exit image data to the svgBody var
                svgBody = string(abi.encodePacked(
                    svgBody,
                    AssetRenderer1.smExit()
                ));
            }
        } else {
            metaAttributes = '{"trait_type":"Miner Status","value":"Dead"}';
        }

        // Loop through all miner attributes to be calculated for metadata
        for(packedData.var_uint8_1 = 0; packedData.var_uint8_1 < 21; packedData.var_uint8_1++){
            // Generate and append miner attribute data to the metaAttributes var
            metaAttributes = string(abi.encodePacked(
                metaAttributes,
                _minerAttribute(packedData.var_uint8_1,miner)
            ));
        }

        // Return miner, svg body and metadata
        return (miner, svgBody, metaAttributes);
    }

    /**
    * @notice calculate the initial status of an escape attempt and return miner and metadata
    * @param miner the miner struct
    * @param packedData a packed struct of variables
    * @return array of miner struct and metadata string
    */
    function _initCodeGen(Miner memory miner, PackedVars memory packedData)
        internal
        pure
        returns (Miner memory, string memory)
    {

        // Define string var for JSON attributes based on attempt stats
        string memory metaAttributes = '{"trait_type":"Miner Status","value":"In Village"}';

        // Loop through all miner attributes to be calculated for metadata
        for(packedData.var_uint8_2 = 0; packedData.var_uint8_2 < 19; packedData.var_uint8_2++){
            // Generate and append miner attribute data to the metaAttributes var
            metaAttributes = string(abi.encodePacked(
                metaAttributes,
                _minerAttribute(packedData.var_uint8_2,miner)
            ));
        }

        // Append blank values to end of metaAttributes
        metaAttributes = string(abi.encodePacked(
            metaAttributes,
            ',{"trait_type":"Chambers Cleared","value":0},{"trait_type":"Gold","value":0}'
        ));

        // Return miner and metadata
        return (miner,metaAttributes);
    }

    /**
    * @notice render the attributes for json metadata
    * @param index name of stat
    * @param miner number of string
    * @return string of a single attribute key/value pair in json object key/value format
    */
    function _minerAttribute(uint256 index, Miner memory miner)
        internal
        pure
        returns (string memory)
    {
        string memory stat;
        string memory value;

        if(index == 0){
            stat = 'Class';
            if(miner.classId == 0){
                value = '"Warrior"';
            } else if(miner.classId == 1){
                value = '"Mage"';
            } else if(miner.classId == 2){
                value = '"Ranger"';
            } else {
                value = '"Assassin"';
            }
        } else if(index == 1){
            stat = 'Gender';
            value = miner.genderId == 0 ? '"Male"' : '"Female"';
        } else if(index == 2){
            stat = 'HP';
            value = (miner.health < 0 ? 0 : uint16(miner.health)).toString();
        } else if(index == 3){
            stat = 'AP';
            value = (miner.armor < 0 ? 0 : uint16(miner.armor)).toString();
        } else if(index == 4){
            stat = 'Base HP';
            value = (miner.baseHealth < 0 ? 0 : uint16(miner.baseHealth)).toString();
        } else if(index == 5){
            stat = 'Base AP';
            value = (miner.baseArmor < 0 ? 0 : uint16(miner.baseArmor)).toString();
        } else if(index == 6){
            stat = 'Base ATK';
            value = (miner.attack < 0 ? 0 : uint16(miner.attack)).toString();
        } else if(index == 7){
            stat = 'Base SPD';
            value = (miner.speed < 0 ? 0 : uint16(miner.speed)).toString();
        } else if(index == 8){
            stat = 'Headgear';
            value = _gearName(miner.headgearId);
        } else if(index == 9){
            stat = 'Armor';
            value = _gearName(miner.armorId);
        } else if(index == 10){
            stat = 'Pants';
            value = _gearName(miner.pantsId);
        } else if(index == 11){
            stat = 'Footwear';
            value = _gearName(miner.footwearId);
        } else if(index == 12){
            stat = 'Weapon';
            value = _gearName(miner.weaponId);
        } else if(index == 13){
            stat = 'Skin Tone';
            value = AssetRenderer2.skintoneName(miner.skintoneId);
        } else if(index == 14){
            stat = 'Hair Type';
            value = AssetRenderer2.hairTypeName(miner.hairTypeId);
        } else if(index == 15){
            stat = 'Hair Color';
            value = AssetRenderer2.hairColorName(miner.hairColorId);
        } else if(index == 16){
            stat = 'Eye Type';
            value = AssetRenderer2.eyeTypeName(miner.eyeTypeId);
        } else if(index == 17){
            stat = 'Eye Color';
            value = AssetRenderer2.eyeColorName(miner.eyeColorId);
        } else if(index == 18){
            stat = 'Mouth Type';
            value = AssetRenderer2.mouthTypeName(miner.mouthId);
        } else if(index == 19){
            stat = 'Gold';
            value = miner.gold.toString();
        } else if(index == 20){
            stat = 'Chambers Cleared';
            value = miner.currentChamber.toString();
        }
        return string(abi.encodePacked(
            ',{"trait_type":"',
            stat,
            '","value":',
            value,
            '}'
        ));
    }
}
