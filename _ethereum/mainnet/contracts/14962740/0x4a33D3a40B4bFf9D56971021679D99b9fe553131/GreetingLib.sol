pragma solidity ^0.8.0;

import "./EnumerableSet.sol";
import "./Strings.sol";
import "./Base64.sol";

library GreetingLib {
    using EnumerableSet for EnumerableSet.AddressSet;

    string private constant HEADER =
        '<svg xmlns="http://www.w3.org/2000/svg" height="300" width="300" style="border:15px solid pink" shape-rendering="crispEdges"><svg x="10" y="10" ><g transform="scale(3)">'
        '<path stroke="#3c1432" d="M6 0h7M5 1h1m7 0h9M4 2h1m17 0h1M3 3h1m19 0h1M3 4h1m19 0h1M3 5h1m19 0h1M3 6h1m19 0h1M3 7h1m19 0h1M3 8h1m19 0h1M2 9h1m20 0h1M1 10h1m21 0h1M0 11h1m22 0h1M0 12h1m22 0h1M0 13h1m22 0h1M0 14h1m21 0h1M1 15h1m18 0h2M2 16h2m15 0h1M4 17h6m7 0h2m-9 1h7"/>'
        '<path stroke="#8e3076" d="M6 1h2M6 2h1m6 0h1M4 3h1m10 0h1m6 0h1M12 4h1m1 0h1m7 0h1M8 5h1m1 0h1m1 0h1m9 0h1M10 6h2m5 0h1m2 0h1m1 0h1M4 7h1m6 0h1m8 0h1M4 8h1m2 0h1m1 1h1m2 0h1m2 0h1m2 0h1m-5 1h1m7 0h1m-3 1h3m-4 1h4m-5 1h4M7 14h1m8 0h5M2 15h1m4 0h1m8 0h4M4 16h4m8 0h2m-7 1h2m3 0h1"/>'
        '<path stroke="#aa388c" d="M8 1h1m1 0h2M5 2h1m6 0h1m2 0h1m1 0h3M5 3h1m8 0h1M4 4h1m1 0h1m4 0h1m1 0h1M4 5h1m1 0h1m2 0h1m1 0h1m1 0h1M4 6h1m8 0h1m1 0h1m-1 1h1m2 0h1m-4 1h1m2 0h1M9 10h1m1 0h3m-6 1h2m8 0h1M8 12h1m8 0h1M1 13h2m4 0h1m8 0h1M1 14h6m1 0h2m-7 1h4m1 0h8m-7 1h7m-3 1h3"/>'
        '<path stroke="#b958a3" d="M9 1h1m2 0h1m1 1h1m1 0h1m3 0h1m-8 1h1m0 2h1m-1 1h1M3 9h6m-7 1h7m-8 1h7m2 0h8M1 12h7m1 0h8M3 13h1m4 0h8m-6 1h2m1 0h1"/>'
        '<path stroke="#71265d" d="M7 2h5m9 0h1M6 3h1m5 0h1m3 0h6M7 4h1m7 0h2m4 0h1m-7 1h1m5 0h1M12 6h1m6 0h1m1 0h1M10 7h1m1 0h1m6 0h1m1 0h2M10 8h3m6 0h4M10 9h2m7 0h4m-13 1h1m4 0h7m-3 1h1m-2 1h1m-2 1h1m4 0h1m-2 1h1m-4 2h1"/>'
        '<path stroke="#551c47" d="M7 3h5M8 4h3m6 0h4m-5 1h4"/>'
        '<path stroke="#bf5db1" d="M5 4h1M5 5h1m1 1h1M7 7h1"/>'
        '<path stroke="#c177b7" d="M7 5h1m12 0h1M6 6h1m1 0h1m7 0h1m1 0h1m-5 1h1m1 0h1M6 8h1m1 0h1m5 1h1m1 0h1M4 13h3m5 1h1m1 0h2"/>'
        '<path stroke="#d8c1d2" d="M5 6h1m3 0h1M5 7h2m1 0h2m3 0h1m3 0h1M5 8h1m3 0h1m3 0h2m1 0h2m-5 1h1m3 0h1"/><path stroke="#642253" d="M8 16h1m1 1h1"/></g>';

    string private constant signerPrefix =
        '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="12" id="svg_11" y="';

    string private constant signerSuffix =
        '" x="1" stroke-width="0" stroke="#000" fill="#000000">';

    string private constant signerEnd = "</text>";

    function tokenURI(EnumerableSet.AddressSet storage signers)
        public
        view
        returns (string memory)
    {
        uint256 signersLen = signers.length();
        uint256 offset = 0;
        bytes memory addresses = new bytes(300 * signersLen);

        for (uint256 i = 0; i < signersLen; ++i) {
            string memory adrStr = Strings.toHexString(
                uint256(uint160(signers.at(i))),
                20
            );

            bytes memory encoded = abi.encodePacked(
                signerPrefix,
                Strings.toString(90 + i * 15),
                signerSuffix,
                adrStr,
                signerEnd
            );

            for (uint256 j = 0; j < encoded.length; ++j) {
                addresses[offset + j] = encoded[j];
            }

            offset += encoded.length;
        }

        for (uint256 i = offset; i < addresses.length; ++i) {
            addresses[i] = 0x20;
        }

        string memory output = string(
            abi.encodePacked(HEADER, addresses, "</svg></svg>")
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Greeting Card #',
                        Strings.toString(1),
                        '", "description": "Greeting Card.", "image": "data:image/svg+xml;base64,',
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

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}
