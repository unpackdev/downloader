pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./base64.sol";

/*
    Lifted from NateAlex's SquiggleWTF project.
    https://etherscan.io/address/0x36f379400de6c6bcdf4408b282f8b685c56adc60#code
*/
library Buffer {
    function hasCapacityFor(bytes memory buffer, uint256 needed) internal pure returns (bool) {
        uint256 size;
        uint256 used;
        assembly {
            size := mload(buffer)
            used := mload(add(buffer, 32))
        }
        return size >= 32 && used <= size - 32 && used + needed <= size - 32;
    }
    
    function toString(bytes memory buffer) internal pure returns (string memory) {
        require(hasCapacityFor(buffer, 0), "Buffer.toString: invalid buffer");
        string memory ret;
        assembly {
            ret := add(buffer, 32)
        }
        return ret;
    }
    
    function append(bytes memory buffer, string memory str) internal view {
        require(hasCapacityFor(buffer, bytes(str).length), "Buffer.append: no capacity");
        assembly {
            let len := mload(add(buffer, 32))
            pop(staticcall(gas(), 0x4, add(str, 32), mload(str), add(len, add(buffer, 64)), mload(str)))
            mstore(add(buffer, 32), add(len, mload(str)))
        }
    }
}

/*
    OpenZeppelin source.
    https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
*/
library HexString {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
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
}

contract GM is ERC721Enumerable {
    
    mapping (uint => uint) public gmsSaidBack;
    
    constructor() ERC721("Good morning", "GM") {}
    
    function sayGM() public {
        _safeMint(msg.sender, totalSupply());
    }
    
    function sayGMBack(uint256 tokenId) public {
        _safeMint(msg.sender, totalSupply());
        gmsSaidBack[tokenId] += 1;
    }
    
    function getColor(uint256 tokenId) public view returns (string memory) {
        uint a = uint256(keccak256(abi.encodePacked(tokenId)));
        uint value = uint256(a%uint256(15728640))+uint(1048576);
        return HexString.toHexString(value, 6);
    }
    
    function generateGM(uint256 tokenId) public view returns (string memory) {
        string memory color = getColor(tokenId);
        bytes memory buffer = new bytes(1000);
        Buffer.append(buffer, '<svg width="800" height="600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 800 600"><g>');
        Buffer.append(buffer, '<text style="cursor: move;" xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" ');
        Buffer.append(buffer, 'font-size="24" id="svg_2" y="40" x="21" stroke-width="0" stroke="#000" fill="#000000">gms said back :</text>');
        Buffer.append(buffer, '<text xml:space="preserve" text-anchor="start" font-family="Noto Sans JP" font-size="24" id="svg_3" y="41" x="180" ');
        Buffer.append(buffer, 'stroke-width="0" stroke="#000" fill="#000000">');
        Buffer.append(buffer, HexString.toString(gmsSaidBack[tokenId]));
        Buffer.append(buffer, '</text>');
        Buffer.append(buffer, '<text transform="matrix(2.1102, 0, 0, 2.68, -1069.82, -1177.68)" xml:space="preserve" text-anchor="start" ');
        Buffer.append(buffer, 'font-family="Noto Sans JP" font-size="100" stroke-width="0" id="svg_1" y="578.61194" x="617.27681" stroke="#000" fill="#');
        Buffer.append(buffer, color);
        Buffer.append(buffer, '">GM</text></g></svg>');
        return Buffer.toString(buffer);
    }
    
    function base64gm(uint256 tokenId) public view returns (string memory) {
        return Base64.encode(bytes(generateGM(tokenId)));
    }
    
    function tokenURI(uint256 tokenId) public override(ERC721) view returns (string memory) {
        return string(
            abi.encodePacked(
                'data:application/json;base64,', Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"gm #',
                            HexString.toString(tokenId),
                            '",'
                            '"description":"good morning! say it back please",',
                            '"attributes" : [{"trait_type":"gms said back", "value":',
                            HexString.toString(gmsSaidBack[tokenId]),
                            '}],'
                            '"image": "data:image/svg+xml;base64,',
                            base64gm(tokenId),
                            '"}'
                        )
                    )
                )
            )
        );
    }
}