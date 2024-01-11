// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Strings.sol";
import "./Base64.sol";

contract TreasureMetadata {
    using Strings for uint256;

    mapping(string => Item) private _items;
    struct Item {
        string[] title;
        uint32[] weight;
        uint8[][] extra;
        uint8[][] material;
    }
    struct Trait {
        string title;
        string attributeStr;
    }

    uint16 internal _canvasSize = 700;
    bool internal _canvasLocked = false;

    uint32[] private _numItemWts = [
        50747683,
        182949180,
        472256061,
        991823020,
        1714634502,
        2537383120,
        3260194602,
        3779761561,
        4069068442,
        4201269939,
        4252017622
    ];
    uint32[] private _numModWts = [
        1308313,
        107608754,
        851711838,
        3187704904,
        4252017622
    ];
    uint32[] private _itemCatWts = [
        285240819,
        646615385,
        1644697520,
        2322600746,
        3918280648,
        4185270226,
        4252017621
    ];

    constructor(
        Item memory __head,
        Item memory __torso,
        Item memory __footwear,
        Item memory __bottoms,
        Item memory __weapon,
        Item memory __shield,
        Item memory __amulet,
        Item memory __possessive,
        Item memory __extra,
        Item memory __material,
        Item memory __tail
    ) {
        _verifyItem(__head);
        _verifyItem(__torso);
        _verifyItem(__footwear);
        _verifyItem(__bottoms);
        _verifyItem(__weapon);
        _verifyItem(__shield);
        _verifyItem(__amulet);
        _verifyItem(__possessive);
        _verifyItem(__extra);
        _verifyItem(__material);
        _verifyItem(__tail);

        _items["HEAD"] = __head;
        _items["TORSO"] = __torso;
        _items["FOOTWEAR"] = __footwear;
        _items["BOTTOMS"] = __bottoms;
        _items["WEAPON"] = __weapon;
        _items["SHIELD"] = __shield;
        _items["AMULET"] = __amulet;
        _items["POSSESSIVE"] = __possessive;
        _items["EXTRA"] = __extra;
        _items["MATERIAL"] = __material;
        _items["TAIL"] = __tail;
    }

    function buildURI(uint256 tokenId) internal view returns (string memory) {
        Trait[] memory traits = _buildTraits(tokenId);
        string[] memory parts = new string[](traits.length * 2 + 1);
        parts[0] = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ',
                (uint256(_canvasSize)).toString(),
                " ",
                (uint256(_canvasSize)).toString(),
                '"><style>.base { fill: black; font-family: aleo; font-size: 19px; }</style><style>.title { fill: black; font-family: aleo; font-size: 28px; font-style: bold; }</style><rect width="100%" height="100%" fill="#FF8F00" /><text x="34" y="34" class="base">'
            )
        );
        for (uint256 i = 1; i < traits.length; i++) {
            parts[i * 2 - 1] = traits[i - 1].title;
            parts[i * 2] = string(
                abi.encodePacked(
                    '</text><text x="34" y="',
                    uint256(34 + i * 34).toString(),
                    '" class="base">'
                )
            );
        }
        parts[parts.length - 2] = traits[traits.length - 1].title;
        parts[parts.length - 1] = string(
            abi.encodePacked(
                '</text><text x="',
                (uint256(_canvasSize - 330)).toString(),
                '" y="',
                (uint256(_canvasSize - 30)).toString(),
                '" class="title">Treasure. (For Warriors)</text></svg>'
            )
        );
        string memory output = "";
        for (uint256 i = 0; i < parts.length; i++) {
            output = string(abi.encodePacked(output, parts[i]));
        }
        string memory attributes = "[";
        for (uint256 i = 0; i < traits.length - 1; i++) {
            attributes = string(
                abi.encodePacked(attributes, traits[i].attributeStr, ",")
            );
        }
        attributes = string(
            abi.encodePacked(attributes, traits[traits.length - 1].attributeStr)
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Chest #',
                        tokenId.toString(),
                        '", "attributes": ',
                        attributes,
                        '], "description": "Treasure is randomized battle gear generated and stored on chain. Each treasure chest contains a variety of gear that warriors will use in battle. Ranging from armour, to weapons and survival gear. Feel free to use your treasure in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function _buildTraits(uint256 tokenId)
        private
        view
        returns (Trait[] memory)
    {
        uint256 numItems = _weightedRandom(
            _numItemWts,
            random(0, "ITEMS", tokenId),
            0
        ) + 8;
        uint256[] memory mains = getMains(tokenId, numItems);

        require(mains.length == numItems, "Main items mismatch");
        Trait[] memory traits = new Trait[](numItems);
        for (uint256 i = 0; i < numItems; i++) {
            if (mains[i] == 0) {
                traits[i] = _buildTrait(getHead(tokenId, i), "Head");
            } else if (mains[i] == 1) {
                traits[i] = _buildTrait(getTorso(tokenId, i), "Torso");
            } else if (mains[i] == 2) {
                traits[i] = _buildTrait(getFootwear(tokenId, i), "Footwear");
            } else if (mains[i] == 3) {
                traits[i] = _buildTrait(getBottoms(tokenId, i), "Bottoms");
            } else if (mains[i] == 4) {
                traits[i] = _buildTrait(getWeapon(tokenId, i), "Weapon");
            } else if (mains[i] == 5) {
                traits[i] = _buildTrait(getShield(tokenId, i), "Shield");
            } else {
                traits[i] = _buildTrait(getAmulet(tokenId, i), "Amulet");
            }
        }
        return traits;
    }

    function getHead(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "HEAD");
    }

    function getTorso(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "TORSO");
    }

    function getBottoms(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "BOTTOMS");
    }

    function getFootwear(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "FOOTWEAR");
    }

    function getWeapon(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "WEAPON");
    }

    function getShield(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "SHIELD");
    }

    function getAmulet(uint256 tokenId, uint256 index)
        private
        view
        returns (string memory)
    {
        return compileMods(tokenId, index, "AMULET");
    }

    function compileMods(
        uint256 tokenId,
        uint256 index,
        string memory category
    ) private view returns (string memory) {
        uint256 numItems = _weightedRandom(
            _numItemWts,
            random(0, "ITEMS", tokenId),
            0
        ) + 8;
        uint256 mainSeed = random(index, category, tokenId);
        uint256 possSeed = random(index, "POSSESSIVE", tokenId);
        uint256 extraSeed = random(index, "EXTRA", tokenId);
        uint256 matSeed = random(index, "MATERIAL", tokenId);
        uint256 tailSeed = random(index, "TAIL", tokenId);
        uint256 mainId = _weightedRandom(
            _items[category].weight,
            mainSeed,
            numItems
        );
        string memory mainItem = _items[category].title[mainId];
        uint256[] memory mods = getMods(category, tokenId, index);
        if (mods.length == 0) {
            return mainItem;
        }

        string[] memory parts = new string[](5);
        parts[3] = mainItem;

        for (uint256 i = 0; i < mods.length; i++) {
            if (mods[i] == 7) {
                parts[0] = string(
                    abi.encodePacked(
                        (
                            _items["POSSESSIVE"].title[
                                (
                                    _weightedRandom(
                                        _items["POSSESSIVE"].weight,
                                        possSeed,
                                        numItems
                                    )
                                )
                            ]
                        ),
                        " "
                    )
                );
            } else if (mods[i] == 8) {
                Item memory temp = getSelective(category, "EXTRA", mainId);
                parts[1] = string(
                    abi.encodePacked(
                        (
                            temp.title[
                                (
                                    _weightedRandom(
                                        cumWts(temp.weight),
                                        extraSeed,
                                        numItems
                                    )
                                )
                            ]
                        ),
                        " "
                    )
                );
            } else if (mods[i] == 9) {
                Item memory temp = getSelective(category, "MATERIAL", mainId);
                parts[2] = string(
                    abi.encodePacked(
                        (
                            temp.title[
                                (
                                    _weightedRandom(
                                        cumWts(temp.weight),
                                        matSeed,
                                        numItems
                                    )
                                )
                            ]
                        ),
                        " "
                    )
                );
            } else if (mods[i] == 10) {
                parts[4] = string(
                    abi.encodePacked(
                        " ",
                        (
                            _items["TAIL"].title[
                                (
                                    _weightedRandom(
                                        _items["TAIL"].weight,
                                        tailSeed,
                                        numItems
                                    )
                                )
                            ]
                        )
                    )
                );
            }
        }

        string memory fin = "";
        for (uint256 i = 0; i < parts.length; i++) {
            if (bytes(parts[i]).length > 0) {
                fin = string(abi.encodePacked(fin, parts[i]));
            }
        }
        return fin;
    }

    function getSelective(
        string memory category,
        string memory select,
        uint256 index
    ) private view returns (Item memory) {
        uint8[] memory indices = eqStr(select, "EXTRA")
            ? _items[category].extra[index]
            : _items[category].material[index];
        Item memory item = Item({
            title: new string[](indices.length),
            weight: new uint32[](indices.length),
            extra: new uint8[][](0),
            material: new uint8[][](0)
        });
        for (uint256 i = 0; i < indices.length; i++) {
            uint8 id = indices[i];
            item.title[i] = _items[select].title[id];
            item.weight[i] = _items[select].weight[id];
        }
        return item;
    }

    function getMods(
        string memory category,
        uint256 tokenId,
        uint256 index
    ) private view returns (uint256[] memory) {
        uint256 numMods = _weightedRandom(
            _numModWts,
            random(index, "MODS", tokenId),
            0
        );

        uint256[] memory mods = new uint256[](numMods);
        uint32[] memory temp = new uint32[](4);
        temp[0] = uint32(_items["POSSESSIVE"].weight.length * (10**6));
        temp[1] = uint32(_items[category].extra.length * (10**6));
        temp[2] = uint32(_items[category].material.length * (10**6));
        temp[3] = uint32(_items["TAIL"].weight.length * (10**6));

        for (uint256 i = 0; i < numMods; i++) {
            uint256 s = random(i + 1, "MODIFIER", tokenId);
            uint256 chosen = _weightedRandom(cumWts(temp), s, 0);

            mods[i] = (chosen + 7);
            delete temp[chosen];
        }

        return mods;
    }

    function getMains(uint256 tokenId, uint256 numItems)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory mains = new uint256[](numItems);
        for (uint256 i = 0; i < numItems; i++) {
            uint256 chosen = _weightedRandom(
                _itemCatWts,
                random(i + 1, "MAINS", tokenId),
                0
            );
            mains[i] = chosen;
        }
        return mains;
    }

    function _buildTrait(string memory itemTitle, string memory traitType)
        private
        pure
        returns (Trait memory)
    {
        string memory attrStr = string(
            abi.encodePacked(
                '{"trait_type": "',
                traitType,
                '","value": "',
                itemTitle,
                '"}'
            )
        );
        return Trait({title: itemTitle, attributeStr: attrStr});
    }

    function random(
        uint256 index,
        string memory prefix,
        uint256 tokenId
    ) private pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        string(
                            abi.encodePacked(
                                index.toString(),
                                prefix,
                                tokenId.toString()
                            )
                        )
                    )
                )
            );
    }

    function _weightedRandom(
        uint32[] memory weights,
        uint256 seed,
        uint256 _n
    ) private pure returns (uint256) {
        _n = (_n > 18 || _n < 8) ? 18 : _n;

        for (uint256 i = 0; i < weights.length; i++) {}

        uint256 cumWt = weights[weights.length - 1];
        uint256 toAdd = ((cumWt / 13**2) * ((18 - _n)**2)) >> 15;
        uint256 target = seed % (cumWt + toAdd * weights.length);
        for (uint256 i = 0; i < weights.length; i++) {
            if (target < (weights[i] + (toAdd * (i + 1)))) {
                return i;
            }
        }
        require(false, "ERROR");
    }

    function eqStr(string memory str1, string memory str2)
        private
        pure
        returns (bool)
    {
        return (
            (keccak256(abi.encodePacked((str1))) ==
                keccak256(abi.encodePacked((str2))))
        );
    }

    function _verifyItem(Item memory _item) private pure {
        require(
            _item.title.length > 0 &&
                _item.title.length == _item.weight.length &&
                ((_item.extra.length == _item.title.length &&
                    _item.material.length == _item.title.length) ||
                    (_item.extra.length == 0 && _item.material.length == 0))
        );
    }

    function cumWts(uint32[] memory arr)
        private
        pure
        returns (uint32[] memory)
    {
        uint32 total = 0;
        uint32[] memory cums = new uint32[](arr.length);
        for (uint256 i = 0; i < arr.length; i++) {
            require(total + arr[i] < type(uint32).max, "Too Big");
            total += arr[i];
            cums[i] = total;
        }
        return cums;
    }
}
