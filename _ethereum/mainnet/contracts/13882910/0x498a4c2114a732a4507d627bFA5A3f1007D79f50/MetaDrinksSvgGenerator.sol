// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./MetaDrinksTypes.sol";
import "./MetaDrinksUtils.sol";

library MetaDrinksSvgGenerator {
    function genSvg(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<svg viewBox="0 0 800 800" preserveAspectRatio="xMinYMin meet" xmlns="http://www.w3.org/2000/svg" font-family="Courier New" font-size="71" fill="#FFF"><style>.t{font-size:42px;}.s{fill:#000;}</style><path fill="#000" d="M0 0h800v800H0z"/><g text-anchor="end" transform="translate(-30)">',
                genDrinkName(_drink),
                '<text x="100%" y="752">[', _drink.symbol, ']</text></g><g transform="translate(30 288)">',
                genDrinkComposition(_drink),
                '</g></svg>'
            ));
    }

    function genDrinkName(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory) {
        uint256 nameWidthA = MetaDrinksUtils.len(_drink.nameA) * 43;
        uint256 nameWidthB = MetaDrinksUtils.len(_drink.nameB) * 43;
        uint256 nameWidthC = MetaDrinksUtils.len(_drink.nameC) * 43;

        // all in one line
        if (nameWidthA + nameWidthB + nameWidthC + 43 * 2 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">',
                    MetaDrinksUtils.upper(_drink.nameA),
                    " ",
                    MetaDrinksUtils.upper(_drink.nameB),
                    " ",
                    MetaDrinksUtils.upper(_drink.nameC),
                    "</text>"
                ));
        }

        // first two in one line
        if (nameWidthA + nameWidthB + 43 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), " ", MetaDrinksUtils.upper(_drink.nameB), "</text>",
                    '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameC), "</text>"
                ));
        }

        // second two in one line
        if (nameWidthB + nameWidthC + 43 <= 740) {
            return string(abi.encodePacked(
                    '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), "</text>",
                    '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameB), " ", MetaDrinksUtils.upper(_drink.nameC), "</text>"
                ));
        }

        // only first two in two lines, third one dropped
        return string(abi.encodePacked(
                '<text x="100%" y="85">', MetaDrinksUtils.upper(_drink.nameA), "</text>",
                '<text x="100%" y="170">', MetaDrinksUtils.upper(_drink.nameB), "</text>"
            ));
    }

    function genDrinkComposition(MetaDrinksTypes.Drink memory _drink) internal pure returns (string memory result) {
        // first 3 items are always present
        uint8 index = 3;
        result = string(abi.encodePacked(
                genSvgHighlightedText(0, _drink.alcoBase, _drink.alcoBasePostfix),
                genSvgHighlightedText(1, _drink.bitterSweet, "1 part"),
                genSvgHighlightedText(2, _drink.sourPart, "1 part")
            ));

        // maybe add fruit or herb
        if (_drink.hasFruitOrHerb) {
            result = string(abi.encodePacked(result, genSvgHighlightedText(index++, _drink.fruitOrHerb, "muddle")));
        }

        // specie or appetizer is always present
        result = string(abi.encodePacked(result, genSvgHighlightedText(index++, _drink.dressing, _drink.dressingPostfix)));

        // maybe add method (depends on fruit or herb)
        if (!_drink.hasFruitOrHerb) {
            result = string(abi.encodePacked(result, genSvgText(index++, _drink.method)));
        }

        // glass is always present
        string memory glassText = _drink.hasGlassPostfix
        ? genSvgHighlightedText(index++, _drink.glass, _drink.glassPostfix)
        : genSvgText(index++, _drink.glass);
        result = string(abi.encodePacked(result, glassText));

        // maybe add top up
        if (_drink.hasTopUp) {
            result = string(abi.encodePacked(result, genSvgHighlightedText(index, _drink.topUp, "top up")));
        }
    }

    function genSvgText(uint256 _index, string memory _text) internal pure returns (string memory) {
        return string(abi.encodePacked('<text y="', MetaDrinksUtils.uint2str(_index * 58), '" class="t">', _text, "</text>"));
    }

    function genSvgHighlightedText(uint256 _index, string memory _text, string memory _highlightedText) internal pure returns (string memory) {
        return string(abi.encodePacked(
                '<rect y="', calcHighlightRectY(_index), '" x="', MetaDrinksUtils.uint2str(uint256((MetaDrinksUtils.len(_text) + 1) * 2522 / 100) - 10), '" width="', MetaDrinksUtils.uint2str(uint256(MetaDrinksUtils.len(_highlightedText) * 2522 / 100) + 20), '" height="48px"/>',
                '<text y="', MetaDrinksUtils.uint2str(_index * 58), '" class="t">', _text, ' <tspan class="t s">', _highlightedText, "</tspan></text>"
            ));
    }

    function calcHighlightRectY(uint256 _index) internal pure returns (string memory) {
        uint256 textY = _index * 58;
        return textY >= 36
        ? MetaDrinksUtils.uint2str(textY - 36)
        : string(abi.encodePacked("-", MetaDrinksUtils.uint2str(36 - textY)));
    }
}
