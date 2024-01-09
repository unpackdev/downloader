// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Arrays.sol";
import "./ReentrancyGuard.sol";

contract ppxxllss is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 10;

    uint256 private price = 50000000000000000; // 0.05 Ether

    constructor() ERC721("ppxxllss", "xx") Ownable() {}

    // Mint functionality

    function mint(uint256 _count) public nonReentrant payable {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));

        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensByOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    // Random function

    function random(string memory input) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Shuffle Yours String

    function shuffleYoursString(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["a", "3", "4", "1", "e", "7", "5", "9", "b", "d", "2", "8", "f", "0", "c", "6", "2", "8", "e", "3", "9", "6", "0", "b", "5", "d", "f", "4", "a", "1", "7", "c"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f9d20005acf7", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory j = string(abi.encodePacked(r[3],r[17],r[1],r[14],r[9],r[12]));

      return j;

    }

    // Shufffle Mine String

    function shuffleMineString(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["7", "4", "c", "5", "2", "b", "d", "6", "0", "f", "e", "3", "8", "a", "1", "9", "4", "0", "b", "f", "1", "e", "d", "a", "3", "7", "c", "9", "2", "6", "5", "8"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("9a2a23789155", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory j = string(abi.encodePacked(r[13],r[16],r[8],r[6],r[0],r[2]));

      return j;

    }

    // Shuffle Ours String

    function shuffleOursString(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["1", "6", "3", "9", "c", "4", "b", "d", "e", "8", "5", "0", "a", "f", "2", "7", "b", "7", "5", "1", "8", "d", "2", "a", "6", "c", "4", "f", "9", "0", "e", "3"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f09ceaa019e6", block.timestamp, block.difficulty, msg.sender, toString(tokenId))));
          i = v % l--;
          t = s[l];
          s[l] = s[i];
          s[i] = t;
      }

      r = s;

      string memory m = r[16];
      string memory f = "f";
      string memory o = "0";
      string memory j;

      if (keccak256(bytes(m)) == keccak256(bytes(f))) {
          j = "ffffff";
      } else if (keccak256(bytes(m)) == keccak256(bytes(o))) {
          j = "000000";
      } else {
          j = string(abi.encodePacked(r[5],r[11],r[7],r[4],r[10],r[15]));
      }

      return j;

    }

    // Make Attributes

    function makeAttributes(uint256 tokenId) private view returns (string memory) {
        string[3] memory traits;

        traits[0] = string(abi.encodePacked('{"trait_type":"you: #","value":"', shuffleYoursString(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"me: #","value":"', shuffleMineString(tokenId), '"}'));
        traits[2] = string(abi.encodePacked('{"trait_type":"us #:","value":"', shuffleOursString(tokenId), '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1], ',', traits[2]));

        return attributes;
    }

    // Token URI

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string[7] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 700 700"><rect width="700" height="700" fill="#';

        p[1] = shuffleOursString(tokenId);

        p[2] = '"></rect><rect x="340" y="340" width="10" height="10" fill="#';

        p[3] = shuffleYoursString(tokenId);

        p[4] = '"></rect><rect x="350" y="340" width="10" height="10" fill="#';

        p[5] = shuffleMineString(tokenId);

        p[6] = '"></rect></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "ppxxllss #', toString(tokenId), '", "description": "xx.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
        o = string(abi.encodePacked('data:application/json;base64,', json));

        return o;
    }

    // to String utility

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
