// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract GuardiansOfLuck04 is ERC721, ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    uint256 public salePrice;
    string public constant totalSupply = "10000";
    Counters.Counter private _tokenIdCounter;

    constructor(uint256 _salePrice) ERC721("Guardians of Luck", "GOLG") {
        salePrice = _salePrice;
    }

    function mint() public payable returns (bool) {
        _tokenIdCounter.increment();
        uint256 tokenId= _tokenIdCounter.current();
        require(tokenId > 0 && tokenId < 9001, "Token ID invalid");
        require(msg.value >= salePrice, 'value sent needs to be atleast sale price');
        _safeMint(_msgSender(), tokenId);
        return true;
    }

    function ownerMint(uint256 tokenId) public onlyOwner {
        require(tokenId > 9000 && tokenId < 10001, "Token ID invalid");
        _safeMint(owner(), tokenId);
    }

    function withdraw(address payable owner) public onlyOwner returns(bool) {
        owner.transfer(address(this).balance);
        return true;
    }

    function setPrice(uint256 price) public onlyOwner returns (bool) {
        salePrice = price;
        return true;
    }

    function getBalanceContract() public view returns(uint){
        return address(this).balance;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public pure override(ERC721, ERC721URIStorage) returns (string memory) {
        string[3] memory parts;
        parts[0] = 'ipfs://QmZtVC4oVQTTzw96moscwVCrYbRbcRSD7CvhhzzJ6g4n1m/';
        parts[1] = Strings.toString(tokenId);
        parts[2] = '.json';
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));
        return output;
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);
        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;
        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}
