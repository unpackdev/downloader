// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./base64.sol";

contract Render {
    bytes16 private constant _ALPHABET = "0123456789abcdef";
    string[] backgroundz;
    string[] barz;

    struct Traits {
        string bg;
        string br;
        string ex;
        string ld;
        string sh;
    }

    constructor() {
        // backgrounds
        backgroundz.push("#8298b1");
        backgroundz.push("#ceb0b8");
        backgroundz.push("#a4c9a7");
        backgroundz.push("#cccccb");
        backgroundz.push("#9fb9c9");

        // bars
        barz.push("#51647e");
        barz.push("#9d5f70");
        barz.push("#5e9861");
        barz.push("#2b3087");
        barz.push("#588098");
    }

    function traitGen(uint256 trait)
        public
        view
        returns (
            string memory,
            string memory,
            string memory,
            string memory,
            string memory
        )
    {
        return (
            string(abi.encodePacked("<rect fill='", backgroundz[trait], "' height='136.91' width='317.45' y='0.01'/>")),
            string(abi.encodePacked("<rect fill='", barz[trait], "' height='14' width='313.32' x='2.11' y='2.39' />")),
            string(
                abi.encodePacked(
                    "<rect fill='",
                    backgroundz[trait],
                    "' height='8.95' width='10.23' x='301.78' y='4.59' />"
                )
            ),
            string(
                abi.encodePacked("<rect fill='", barz[trait], "' height='6.8' width='235.62' x='13.2' y='113.44' />")
            ),
            string(
                abi.encodePacked(
                    // borders
                    '<line stroke="#fff" stroke-width="0.75px" x1="0.97" y1="0.91" x2="1.01" y2="135.9"/>',
                    '<line stroke="#999" stroke-width="0.75px" x1="316.54" y1="137.5" x2="316.49" y2="0.91"/>',
                    '<line stroke="#999" x1="0.55" x2="316.81" y1="136.35" y2="137.21"/>',
                    '<line fill="#fff" stroke="#fff" x1="316.1" x2="0.8" y1="1.33" y2="1.33"/>',
                    // Close button
                    '<line stroke="#231f20" x1="303.91" x2="309.87" y1="6.06" y2="12.06"/>',
                    '<line stroke="#231f20" x1="309.87" x2="303.91" y1="6.06" y2="12.06"/>',
                    '<line stroke="#fff" x1="313.9" y1="3.84" x2="301.01" y2="3.84"/>',
                    '<line stroke="#fff" x1="301.01" y1="15.24" x2="301.01" y2="3.46"/>',
                    '<line stroke="#231f20" x1="313.52" y1="15.24" x2="313.53" y2="3.46"/>',
                    '<line stroke="#231f20" x1="313.9" y1="14.99" x2="300.57" y2="14.99"/>',
                    // Done button borders
                    '<line stroke="#999" stroke-width="0.75px" x1="256.52" y1="125.2" x2="256.52" y2="106.87"/>',
                    '<line stroke="#000" x1="305.14" x2="305.11" y1="126.01" y2="106.75"/>',
                    '<line stroke="#000" x1="305.51" x2="256.17" y1="125.63" y2="125.63"/>',
                    '<line stroke="#fff" x1="304.71" x2="256.18" y1="107.14" y2="107.14"/>'
                )
            )
        );
    }

    function bodyF(
        address nft_target,
        string memory _originalId,
        uint256 _vandalId,
        address hijacker,
        string memory tag,
        uint256 trait
    ) public view returns (string memory) {
        string memory vandalId = toString(_vandalId);
        Traits memory traits;
        (traits.bg, traits.br, traits.ex, traits.ld, traits.sh) = traitGen(trait);
        return (
            string(
                abi.encodePacked(
                    '<svg width="317.67" height="161.3" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">',
                    traits.bg,
                    '<line stroke="#999" x1="0.55" x2="316.81" y1="136.35" y2="137.21"/>',
                    '<line fill="#fff" stroke="#fff" x1="316.1" x2="0.8" y1="1.33" y2="1.33"/>',
                    traits.br,
                    traits.ex,
                    traits.sh,
                    '<line stroke="#999" stroke-width="0.75px" x1="256.52" y1="125.2" x2="256.52" y2="106.87"/>',
                    '<line stroke="#999" stroke-width="0.75px" x1="249.86" y1="112.31" x2="11.73" y2="112.34"/>',
                    '<line stroke="#fff" stroke-width="0.75px" x1="12.01" y1="112.1" x2="12.09" y2="121.45"/>',
                    '<line stroke="#fff" stroke-width="0.75px" x1="250.28" y1="111.91" x2="250.28" y2="121.82"/>',
                    '<line stroke="#fff" stroke-width="0.75px" x1="250.58" y1="121.43" x2="11.68" y2="121.43"/>',
                    '<text fill="#231f20" font-size="8.57px" font-family="monospace" transform="translate(12.26 72.4)">NFT:',
                    toHexString(uint160(nft_target), 20),
                    '<tspan x="0" y="10.28">ID:',
                    _originalId,
                    "</tspan>",
                    '<tspan x="0" y="20.28">PWND BY:',
                    toHexString(uint160(hijacker), 20),
                    "</tspan>",
                    '<tspan x="0" y="30.28">MSG:',
                    tag,
                    "</tspan>",
                    "</text>",
                    traits.ld,
                    '<rect fill="#efe752" height="11.96367" stroke="#231f20" transform="rotate(-15.1489, 33.1512, 52.9334)" width="19.54649" x="19.378" y="39.95154"/>',
                    '<rect fill="#efe752" height="1.3" stroke="#231f20" width="5.3" x="16.34834" y="39.79334"/>',
                    '<rect fill="#efe752" height="11.96367" stroke="#231f20" transform="rotate(2.71939, 40.2465, 49.6166)" width="19.54649" x="30.47325" y="43.63481"/>',
                    '<rect fill="#efe752" height="1.3" stroke="#231f20" width="5.3" x="45.0965" y="41.26665"/>',
                    '<line fill="none" stroke="#fcfcfc" transform="rotate(-178.386, 40.53, 44.5)" x1="31.33001" x2="49.73001" y1="44.1" y2="44.9"/>',
                    '<line fill="none" stroke="#fff" x1="17.24834" x2="35.04834" y1="44.76834" y2="39.86834"/>',
                    '<text fill="#231f20" font-size="10px" font-family="monospace" transform="translate(266.58 119.42) scale(0.9 1)">Cancel</text>',
                    '<text stroke="#fff" fill="#fff" stroke-width="0.4px" font-size="8.97px" font-family="monospace" transform="translate(4.6 12.09) scale(1.14 1)">#',
                    vandalId,
                    " Copying</text>",
                    "</svg>"
                )
            )
        );
    }

    function bodyB(
        address cleaner,
        uint256 _vandalId,
        string memory tag,
        uint256 trait,
        address nft,
        string memory tokenId
    ) public view returns (string memory) {
        string memory vandalId = toString(_vandalId);
        Traits memory traits;
        (traits.bg, traits.br, traits.ex, traits.ld, traits.sh) = traitGen(trait);
        return (
            string(
                abi.encodePacked(
                    '<svg width="317.67" height="161.3" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg">',
                    '<rect fill="#b7a163" height="136.91" width="317.45" y="0.01"/>', // golden color
                    '<line stroke="#999" x1="0.55" x2="316.81" y1="136.35" y2="137.21"/>',
                    '<line fill="#fff" stroke="#fff" x1="316.1" x2="0.8" y1="1.33" y2="1.33"/>',
                    traits.br,
                    traits.ex,
                    traits.sh,
                    '<text fill="#231f20" font-size="8.57px" font-family="monospace" transform="translate(22.26 72.4)">',
                    '<tspan x="0" y="10.28">BURN BY:',
                    toHexString(uint160(cleaner), 20),
                    "</tspan>",
                    '<tspan x="0" y="20.28">MSG:',
                    tag,
                    "</tspan>",
                    '<tspan x="0" y="30.28">NFT:',
                    toHexString(uint160(nft), 20),
                    "</tspan>",
                    '<tspan x="0" y="40.28">ID:',
                    tokenId,
                    "</tspan>",
                    "</text>",
                    '<circle cx="160.625" cy="48.875" fill="#7b7b7b" r="10" stroke="#7b7b7b" stroke-width="5"/>',
                    '<circle cx="158" cy="47" fill="#ff0000" r="13" stroke="#7b0000"/>',
                    '<path d="m149.89782,43.03296l3.93979,-3.75795l4.18517,3.99198l4.18517,-3.99198l3.93984,3.75795l-4.18519,3.99201l4.18519,3.99201l-3.93984,3.75799l-4.18517,-3.99201l-4.18517,3.99201l-3.93979,-3.75799l4.18514,-3.99201l-4.18514,-3.99201z" fill="#fff" stroke="#fff"/>',
                    '<text fill="#231f20" font-size="10px" font-family="monospace" transform="translate(270.58 119.42) scale(0.9 1)">Done</text>',
                    '<text stroke="#fff" fill="#fff" stroke-width="0.4px" font-size="8.97px" font-family="monospace" transform="translate(4.6 12.09) scale(1.14 1)">#',
                    vandalId,
                    " Removed</text>",
                    "</svg>"
                )
            )
        );
    }

    function toString(uint256 value) public pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "HEX_L");
        return string(buffer);
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) public pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}
