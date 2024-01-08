// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./ERC721URIStorage.sol";

contract Geohashes is ERC721URIStorage, Ownable, Pausable {
    constructor() ERC721("Geohashes", "GEOH") {}

    function claim(uint256 tokenId) public payable whenNotPaused {
        require(tokenId > 0 && tokenId < 1048576, "Token ID invalid");
        require(
            msg.value >= 8888000000000000,
            "Not enough ETH sent; check prices!"
        );
        _safeMint(_msgSender(), tokenId);
    }

    function claimByGeohash(string calldata hash) public payable whenNotPaused {
        uint256 tokenId = geohashToIndex(hash);
        string memory message = concatenate(
            "Token ID invalid:",
            toString(tokenId)
        );
        require(tokenId > 0 && tokenId < 1048576, message);
        require(
            msg.value >= 8888000000000000,
            "Not enough ETH sent; check price!"
        );
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        pure
        override
        returns (string memory)
    {
        string memory geohash = indexToGeohash(tokenId, 4);
        string[7] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 512 512">';
        parts[1] = '<rect fill="#FFFFFF" width="512" height="512" />';
        parts[
            2
        ] = '<circle stroke="#202A88" fill="#FFFFFF" stroke-width="3" cx="258.5" cy="255.5" r="178" />';
        parts[
            3
        ] = '<text fill-rule="nonzero" x="50%" y="53%" text-anchor="middle" font-family="HelveticaNeue-Medium, Helvetica Neue" font-size="64" font-weight="400" fill="#212B88">';
        parts[4] = geohash;
        parts[5] = "</text>";
        parts[6] = "</svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );
        output = string(abi.encodePacked(output, parts[5], parts[6]));
        string memory json = encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Geohash: ',
                        geohash,
                        '", "description": "A geohash encodes a geographic location into a short string of letters and digits stored on chain. Images and places are intentionally omitted for others to interpret and incorporate.", "image": "data:image/svg+xml;base64,',
                        encode(bytes(output)),
                        '", "geohash": "',
                        geohash,
                        '" }'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function getTokenIdAsString(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        string memory output = toString(tokenId);
        return output;
    }

    bytes private constant chars = "0123456789bcdefghjkmnpqrstuvwxyz";

    function geohashToIndex(string calldata geohash)
        public
        pure
        returns (uint256)
    {
        uint256 index = 0;
        bytes memory geohashb = bytes(geohash);

        for (uint256 i = 0; i < geohashb.length; i++) {
            int256 arri = -1;
            for (uint256 j = 0; j < chars.length; j++) {
                if (geohashb[i] == chars[j]) {
                    arri = int256(j);
                    break;
                }
            }

            if (arri >= 0) {
                if (i < geohashb.length - 1) {
                    uint256 powx = geohashb.length - i - 1;
                    uint256 l = uint256(arri) * (chars.length**powx);
                    index += l;
                } else {
                    index += uint256(arri);
                }
            } else {
                index = 0;
                break;
            }
        }
        return index;
    }

    function indexToGeohash(uint256 tokenId, uint256 digits)
        public
        pure
        returns (string memory)
    {
        string memory hash = "";
        for (uint256 i = 0; i < digits; i++) {
            uint256 d = pow(32, digits - i - 1);
            uint256 x = tokenId / d;

            bytes1 c = chars[x];
            bytes memory ba = new bytes(1);
            ba[0] = c;

            hash = concatenate(hash, string(ba));

            uint256 sub = x * d;
            tokenId -= sub;
        }
        return hash;
    }

    function pow(uint256 base, uint256 exponent) public pure returns (uint256) {
        if (exponent == 0) {
            return 1;
        } else if (exponent == 1) {
            return base;
        } else if (base == 0 && exponent != 0) {
            return 0;
        } else {
            uint256 z = base;
            for (uint256 i = 1; i < exponent; i++) z = SafeMath.mul(z, base);
            return z;
        }
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(tokenId > 0 && tokenId <= 1048576, "Token ID invalid");
        _burn(tokenId);
    }

    function payout() public onlyOwner {
        uint256 balance = address(this).balance;
        address payable ownerp = payable(owner());
        ownerp.transfer(balance);
    }

    function pauseToken() public onlyOwner {
        require(!paused(), "Token already paused!");
        _pause();
    }

    function unpauseToken() public onlyOwner {
        require(paused(), "Token not paused!");
        _unpause();
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    // from Brecht Devos Base64, MIT
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
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

    function concatenate(string memory s1, string memory s2)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(s1, s2));
    }

    function compare(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}
