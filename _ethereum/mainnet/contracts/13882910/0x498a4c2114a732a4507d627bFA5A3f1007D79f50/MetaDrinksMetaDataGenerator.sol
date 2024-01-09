// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";
import "./MetaDrinksTypes.sol";

library MetaDrinksMetaDataGenerator {
    function genJsonTokenURI(MetaDrinksTypes.Drink memory _drink, string memory _drinkSvg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(abi.encodePacked(
                "{",
                '"name":"', string(abi.encodePacked(_drink.nameA, " ", _drink.nameB, " ", _drink.nameC)), '",',
                '"description": "The genesis collection of 7777 Metadrinks with two generatives within each of them. A singular mantra in the title which sends you to a headspace and a unique random how-to. Ownership and commercial usage rights are given to you, the Metadrinker, over your [%]. Feel free to use it any way you want. [metadrinks.io](https://metadrinks.io/)",',
                '"image":"', genSvgImageURI(_drinkSvg), '",',
                '"attributes":', genAttributes(_drink),
                "}"
            ))))));
    }

    function genSvgImageURI(string memory _svg) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(string(abi.encodePacked(_svg))))));
    }

    function genAttributes(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '[',
                genStrAttr("Alco Base", genStrValue(_drink.alcoBase, _drink.alcoBasePostfix), true),
                genStrAttr("Bittersweet Part", genStrValue(_drink.bitterSweet, "1 part"), true),
                genStrAttr("Sour Part", genStrValue(_drink.sourPart, "1 part"), true),
                _drink.hasFruitOrHerb ? genStrAttr("Fruit or Herb", genStrValue(_drink.fruitOrHerb, "muddle"), true) : "",
                genStrAttr("Dressing", genStrValue(_drink.dressing, _drink.dressingPostfix), true),
                !_drink.hasFruitOrHerb ? genStrAttr("Method", _drink.method, true) : "",
                genStrAttr("Glass", _drink.hasGlassPostfix ? genStrValue(_drink.glass, _drink.glassPostfix) : _drink.glass, true),
                _drink.hasTopUp ? genStrAttr("Top Up", genStrValue(_drink.topUp, "top up"), true) : "",
                genStrAttr("Symbol", _drink.symbol, false),
                ']'
            ));
    }

    function genStrAttr(string memory _type, string memory _value, bool withComma) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '{',
                '"trait_type":"', _type, '",',
                '"value":"', _value, '"',
                withComma ? '},' : '}'
            ));
    }

    function genStrValue(string memory _part1, string memory _part2) internal pure returns (string memory) {
        return string(abi.encodePacked(_part1, " ", _part2));
    }
}
