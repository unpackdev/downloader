// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract SVGHelper {
    function extractSubstring(
        bytes memory data,
        uint256 start,
        uint256 end
    ) internal pure returns (bytes memory) {
        bytes memory result = new bytes(end - start);
        for (uint256 i = 0; i < (end - start); i++) {
            result[i] = data[i + start];
        }

        return result;
    }

    function getStyleParts(
        uint256 baseNumber
    ) public pure returns (string[7] memory styles) {
        string memory baseNumberHex = uint2hexstr42(baseNumber);
        for (uint i = 0; i < 7; i++) {
            bytes memory segment = extractSubstring(
                bytes(baseNumberHex),
                i * 6,
                (i + 1) * 6
            );
            styles[i] = string(segment);
        }
        return styles;
    }

    function getStyleString(
        uint256 baseNumber
    ) public pure returns (string memory) {
        // use getStyleParts
        string[7] memory styles = getStyleParts(baseNumber);
        return
            string(
                abi.encodePacked(
                    "#background{fill:#",
                    styles[0],
                    "} #mouth{fill:#",
                    styles[1],
                    "} #nose{fill:#",
                    styles[2],
                    "} #hair{fill:#",
                    styles[3],
                    "} #eyebrows{fill:#",
                    styles[4],
                    "} #dress{fill:#",
                    styles[5],
                    "} #eyes{fill:#",
                    styles[6],
                    "}"
                )
            );
    }

    function generateSVG(
        uint256 tokenId
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8" standalone="no"?><svg width="210mm" height="297mm" viewBox="0 0 210 297" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg"><style>',
                    getStyleString(tokenId),
                    '</style><path style="fill-opacity:1;stroke-width:1" d="M 0,0 H 210 V 297 H 0 Z" id="background"/><path style="fill:#fff;fill-rule:evenodd;stroke-width:.264583" d="M139.76 145.276c1.992.37 5.836-3.208 7.503-7.99-1.012-5.166-1.983-10.475-3.476-15.546.692 5.522 1.979 11.06 1.781 16.757l-1.788-6.13c-.95.806-1.577.917-1.652.804-.085-.125.844-1.265 1.397-1.612l-1.845-4.975-.186 1.468c-.477 5.938-.863 12.053-1.734 17.223z" id="path6"/><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M109.81 160.858c-.66.126-2.6.276-2.77.735-.174.464 3.322 1.78 3.285 1.607-.037-.173 1.98-2.34 2.495-2.72.515-.38-2.318.246-3.01.378z" id="mouth"/><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M104.579 145.441c-.555-.038-1.765 3.213-1.524 3.876.25.695 2.86 2.345 3.343 2.237.481-.107.633-2.152.562-2.606-.077-.487-1.858-3.47-2.381-3.507z" id="nose"/><path style="fill:#fff;fill-rule:evenodd;stroke-width:.264583" d="M63.263 132.692a184.097 184.097 0 0 0 5.495 11.23c1.54 2.884 2.612 6.017 4.237 8.579 2.942 4.636 7.801 10.32 10.616 11.632 5.608 2.611 15.581 7.277 26.974 7.62 3.467.105 7.033-1.32 10.682-2.88-4.424 2.83-8.892 5.337-13.84 4.27-7.863-1.058-16.18-2.89-27.08-9.126-4.95-4.57-10.017-10.8-15.395-21.36l-1.69-9.965z" id="path12"/><g id="hair" ><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M92.5 80.07c-.535 11.545-4.355 24.31-7.216 35.615 4.064-5.647 9.338-11.969 12.276-19.35l-2.112 10.141c4.68-8.832 7.757-18.791 10.467-28.969l.023-2.77c-2.067 8.267-4.374 16.553-7.93 24.937.469-2.318.815-4.612 1.204-6.914-3.146 6.254-6.441 11.76-9.896 16.458 2.623-8.487 4.555-17.233 5.143-26.483l-.335-8.42-2.339 5.517.715.24z" id="path4"/><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M105.51 76.919c12.784 14.03 23.668 29.345 30.894 45.73-.418 8.367-.707 12.087-1.956 17.48 1.59-2.414 2.563-4.477 3.478-6.507.818-5.471.852-10.787.448-16.015-4.624-8.009-9.352-15.981-15.61-23.416-5.764-6.813-11.496-13.557-16.828-19.456l-.426 2.183zM63.118 122.374c2.253-6.938 9.053-13.93 17.5-23.97 6.06-7.203 10.417-15.57 12.915-20.566l-.4-1.337c-3.28 7.009-6.413 13.917-19.413 27.586-6.914 7.354-9.872 13.236-10.602 18.287z" id="path14"/></g ><path style="fill:#fff;fill-rule:evenodd;stroke-width:.264583" d="M68.151 225.324c1.722-3.408 3.435-6.65 6.549-10.847-1.818 4.278-3.177 8.665-3.588 11.443zM80.513 189.547l.374 1.778c5.85-1.33 8.503-4.964 14.055-5.777l-1.871-1.94c-2.52 1.527-4.757 3.055-8.068 4.583zM71.186 191.127c-2.53.363-5.08.716-7.524 1.108l.421 2.29c2.77-.65 5.755-1.202 8.84-1.653zM59.66 192.938c-4.744.926-8.737 2.115-10.856 3.952a15.312 15.312 0 0 0-1.86 1.935c-.15 2.265-.169 4.378-.166 6.4.816-1.974 1.97-3.715 3.63-5.135 2.112-1.807 5.69-3.353 10.08-4.622zM45.24 201.371c-2.79 5.048-3.65 11.891-3.828 19.373l3.134.794c.253-5.387.332-10.68 1.761-15.032a212.475 212.475 0 0 1-1.067-5.134zM63.68 146.104c.531 3.775.935 5.74 1.418 8.111 1.786 1.525 2.736 2.17 4.93 3.457-2.8-4.475-3.44-5.723-6.347-11.568zM65.18 143.328c1.446 5.023 3.019 10 5.168 14.758 1.869 1.222 3.654 1.272 5.455 1.54-3.991-4.953-7.358-10.572-10.623-16.298z" id="path16"/><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M72.801 142.64c-.82-4.947-1.085-10.811 2.759-14.209 3.562-3.149 9.774-2.164 13.971.978l-.775-2.207c-3.584-3.459-7.568-3.306-11.527-3.378-4.6 1.223-6.267 5.388-7.786 9.703 1.09 3.093 1.684 7.093 3.358 9.112zM134.466 130.209c-1.156-5.788-3.288-11.004-8.386-12.364-7.89-2.103-11.07 2.51-13.129 8.268l.021-4.994c2.709-6.53 7.796-7.65 13.762-6.775 6.213 2.299 8.97 6.492 9.022 12.17z" id="eyebrows"/><path style="fill:#fff;fill-rule:evenodd;stroke-width:.264583" d="M41.505 218.033c-.82.298-1.852.563-1.918 1.356.393 1.085 1.248 1.193 1.941 1.426l-.023-2.782zm69.053-15.286c-.627-.264-1.719-.257-2.663-.023-.944.233-4.754 1.141-4.645 1.743.104.57 3.938.374 5.008.743 1.07.37 4.143 1.095 4.61.737.458-.35-.022-1.071-.339-1.725-.315-.648-1.362-1.22-1.97-1.475zm12.632-3.54c.403-.55 1.249-1.07 2.13-1.48.863-.404 2.903-1.198 3.081-.647.137.424-2.487 2.15-3.215 3.016-.729.867-1.445 3.03-1.82 2.974-.364-.054-.531-.93-.595-1.654-.063-.719.028-1.677.419-2.21zm-9.514-4.579c-.563.66 1.103 3.834 2.73 4.48 1.628.648 3.175-.962 4.147-2.233.973-1.27 1.061-5.965.454-6.446-.629-.498-2.304 5.648-3.769 5.925-1.464.278-3.025-2.358-3.562-1.726zm-57.156 1.796c1.395.759 2.76 5.192 4.023 7.53-.029-2.915.357-6.018-.188-8.887l-3.835 1.357zm8.231-2.244c1.488-.27 8.279 6.782 10.29 7.063-1.338-2.167-4.413-5.55-5.519-8.42l-4.77 1.357z" id="path20"/><path d="M85.746 222.083c-.262.235 1.203 3.038 2.024 4.03 1.075 1.298 3.439 3.095 3.598 2.883.149-.198-2.252-2.157-3.157-3.308-.763-.969-2.222-3.822-2.465-3.605z" fill="#fff" style="fill-rule:evenodd;stroke-width:.264583" id="path22"/><path style="fill:#fff;fill-rule:evenodd;stroke-width:.241419" d="M164.814 188.02c-.498-.292-.888-.603-1.673-.847l2.31 5.227c-.058-1.193-.315-2.73-.637-4.38zM170.946 203.723c-.846-2.775-2.138-6.01-3.613-8.276l.518-4.565c.465-.043.782.501 1.214 1.266 1.018 4.057 1.704 7.715 1.881 11.575zM163.86 199.36c-.846-2.774-1.367-5.811-2.842-8.077l-1.029-4.678c.465-.043.953-.048 1.6.208 1.018 4.057 2.094 8.687 2.272 12.547zM159.786 197.89c-1.557-2.288-2.878-4.953-4.889-6.513l.406-4.078c2.07 3.432 3.262 7.014 4.483 10.59zM55.698 213.32s.595 4.779 1.454 6.303c.978 1.736 3.042 3.345 4.053 3.967-.506-.55-1.953-3.016-2.86-4.583-.883-1.524-2.647-5.688-2.647-5.688z" id="path30"/><g id="dress"><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M74.898 226.515c2.353-5.777 1.559-12.222 1.257-18.455-.228-4.703-.546-9.227-1.125-13.229l.993.86 1.058 13.163c.618 6.698.78 12.98-.53 17.926z" id="path24"/><path style="fill-rule:evenodd;stroke-width:.264583;fill-opacity:1" d="M94.967 230.613c-5-3.868-8.44-9.118-10.197-15.855-1.478-4.88-2.084-9.76-2.712-14.64-.306-.164-.612-.34-.918-.528-.12-.073.171 2.9.64 6.067.542 3.674 1.344 6.763 1.109 7.655-.095.36-1.015-3.137-1.775-6.897-.756-3.737-1.353-7.735-1.473-7.82-1.19-.848-2.38-1.82-3.57-2.827.514 7.156 1.029 14.295 1.543 21.328.082 3.81-.117 7.237-1.029 9.682l18.382 3.835zM79.579 195.23s-.902-4.91-.07-4.91c.505-.001 1.232 5.29 1.45 6.337l.724.655-1.24-7.881c-.846-.337-1.733-.317-2.642-.094-.83.253-1.984.183-2.128 1.123l3.906 4.77z" id="path26"/><path d="m137.906 229.16 13.38-3.302c.161-6.475.41-13.939 1.047-13.91.638.03-.47 8.741.653 13.52l1.035-.2c-.91-2.676-.82-5.66-.854-8.607.183-6.03.593-12.149 1.377-18.409.316-4.393.617-8.768.572-12.73-.2-.296-.703-.54-1.927-.662-1.14.045-2.047.223-2.181.846-.267 9.299-1.738 16.66-3.549 23.473-1.83 7.513-4.891 14.25-9.553 19.982z" style="fill-rule:evenodd;stroke-width:.241419;fill-opacity:1" id="path28"/><path style="fill-rule:evenodd;stroke-width:.241419;fill-opacity:1" d="M135.954 229.903c3.956-4.9 7.031-10.88 9.241-17.596 2.968-9.022 4.248-17.814 5.5-26.595l.314-.006c-.06 6.012-.999 12.1-2.176 18.136-1.051 5.388-2.794 10.725-5.37 16.415-1.28 2.828-3.2 5.933-5.499 9.02l-2.01.627z" id="path32"/></g ><path d="m141.207 185.701 3.505 1.706.245-1.57c-1.248-.037-2.5-.093-3.75-.136zm8.281.112-1.138 3.36 2.007.976.531-4.433a32.8 32.8 0 0 1-1.4.097z" style="fill:#fff;fill-rule:evenodd;stroke-width:.241419" id="path34"/><g transform="rotate(-20.145)" style="fill-opacity:1" id="eyes" ><ellipse style="fill-opacity:1;stroke-width:1" cx="30.755" cy="156.868" rx="2.386" ry="3.449" id="ellipse36"/><ellipse style="fill-opacity:1;stroke-width:1" cx="71.501" cy="162.363" rx="2.386" ry="3.449" id="ellipse38"/></g></svg>'
                )
            );
    }

    function uint2hexstr42(uint256 num) public pure returns (string memory) {
        if (num == 0) {
            return "000000000000000000000000000000000000000000";
        }
        uint256 temp = num;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 4;
        }
        uint256 requiredLength = 42;
        bytes memory buffer = new bytes(requiredLength);
        for (uint256 i = requiredLength; i > requiredLength - length; --i) {
            buffer[i - 1] = bytes1(
                uint8(48 + (num % 16) + (num % 16 > 9 ? 39 : 0))
            );
            num >>= 4;
        }
        for (uint256 i = 0; i < requiredLength - length; ++i) {
            buffer[i] = "0";
        }
        return string(buffer);
    }

    function uint2String(uint256 value) public pure returns (string memory) {
        // If the value is 0, return "0" directly
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

    function toHexString(address addr) internal pure returns (string memory) {
        return uint2hexstr42(uint256(uint160(addr)));
    }

    function base64encode(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string
            memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
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
