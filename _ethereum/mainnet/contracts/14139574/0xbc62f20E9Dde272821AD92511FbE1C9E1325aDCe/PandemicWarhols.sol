// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Arrays.sol";
import "./ReentrancyGuard.sol";
import "./CryptopunksData.sol";
import "./BleachBackground.sol";

contract PandemicWarhols is ERC721, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public constant MAX_TOKENS = 10000;

    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;

    uint256 private price = 80000000000000000; // 0.08 Ether

    address public renderingContractAddress;
    address public backgroundContractAddress;

    constructor() ERC721("Pandemic Warhols", "PWAR") Ownable() {}

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function setBackgroundContractAddress(address _backgroundContractAddress) public onlyOwner {
        backgroundContractAddress = _backgroundContractAddress;
    }

    // Mint functionality

    function mint(uint256 _count) public payable nonReentrant {
        uint256 totalSupply = totalSupply();
        require(_count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1);
        require(totalSupply + _count < MAX_TOKENS + 1);
        require(msg.value >= price.mul(_count));
        for(uint256 i = 0; i < _count; i++){
            _safeMint(msg.sender, totalSupply + i);
        }
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        price = _newPrice;
    }

    function getPrice() public view returns (uint256){
        return price;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
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

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    // Random punk

    function randomPunk(uint256 tokenId) public view returns (uint16) {
        uint256 v = uint(keccak256(abi.encodePacked("a0867ed705a0", block.timestamp, block.difficulty, toString(tokenId)))) % 10000;
        uint16 original = uint16(v);
        return original;
    }

    // Background color

    function backgroundColor(uint256 tokenId) private view returns (string memory) {

      string[32] memory r;
      string[32] memory s = ["1", "6", "3", "9", "c", "4", "b", "d", "e", "8", "5", "0", "a", "f", "2", "7", "b", "7", "5", "1", "8", "d", "2", "a", "6", "c", "4", "f", "9", "0", "e", "3"];

      uint l = s.length;
      uint i;
      string memory t;

      while (l > 0) {
          uint256 v = random(string(abi.encodePacked("f09ceaa019e6", block.timestamp, block.difficulty, toString(tokenId))));
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

        string[2] memory traits;
        string memory originalPunk = toString(randomPunk(tokenId));

        traits[0] = string(abi.encodePacked('{"trait_type":"Background Color: #","value":"', backgroundColor(tokenId), '"}'));
        traits[1] = string(abi.encodePacked('{"trait_type":"Original Punk: #","value":"', originalPunk, '"}'));

        string memory attributes = string(abi.encodePacked(traits[0], ',', traits[1]));

        return attributes;
    }

    function replaceValue(string memory svg,uint256 position, string memory replace) internal pure returns (string memory) {
        string memory t = _stringReplace(svg,position,replace);
        return t;
    }

    function getBleach(uint256 tokenId) public view returns (string memory) {

        BleachBackground bleachBackground = BleachBackground(backgroundContractAddress);

        uint16 t = uint16(tokenId);

        string memory b = bleachBackground.getBleach(t);
        return b;
    }


    function getPlain(uint256 tokenId) public view returns (string memory) {

        CryptopunksData cryptopunksData = CryptopunksData(renderingContractAddress); // Running

        uint16 t = randomPunk(tokenId);

        string memory punkSvg = cryptopunksData.punkImageSvg(t); // Running

        // Add replacement values
        string[24] memory r = ["<","s","v","g",">","<","r","e","c","t",">","<","/","r","e","c","t",">","<","/","s","v","g",">"];

        string memory a = replaceValue(punkSvg,0,r[0]);
        a = replaceValue(a,1,r[1]);
        a = replaceValue(a,2,r[2]);
        a = replaceValue(a,3,r[3]);
        a = replaceValue(a,4,r[4]);
        a = replaceValue(a,5,r[5]);
        a = replaceValue(a,6,r[6]);
        a = replaceValue(a,7,r[7]);
        a = replaceValue(a,8,r[8]);
        a = replaceValue(a,9,r[9]);
        a = replaceValue(a,10,r[10]);
        a = replaceValue(a,11,r[11]);
        a = replaceValue(a,12,r[12]);
        a = replaceValue(a,13,r[13]);
        a = replaceValue(a,14,r[14]);
        a = replaceValue(a,15,r[15]);
        a = replaceValue(a,16,r[16]);
        a = replaceValue(a,17,r[17]);
        a = replaceValue(a,18,r[18]);
        a = replaceValue(a,19,r[19]);
        a = replaceValue(a,20,r[20]);
        a = replaceValue(a,21,r[21]);
        a = replaceValue(a,22,r[22]);
        a = replaceValue(a,23,r[23]);

        return a;

    }

    function getDescription(uint256 tokenId) public view returns (string memory) {

        string memory description;
        string memory a = "We create and perceive our world simultaneously. And our mind does this so well that we don't even know that it's happening.";
        string memory b = "You create the world of the dream. We bring the subject into that dream and they fill it with their subconcious.";
        string memory c = "Well, dreams they feel real while we're in them, right? It's only when we wake up that we realize something was actually strange?";
        string memory d = "You never really remember the beginning of a dream, do you? You always wind up right in the middle of what's going on.";

        uint256 v = uint(keccak256(abi.encodePacked("a70c1946af4f", block.timestamp, block.difficulty, toString(tokenId)))) % 4;

        if (v == 0) {
            description = a;
        } else if (v == 1) {
            description = b;
        } else if (v == 2) {
            description = c;
        } else {
            description = d;
        }

        return description;

    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {

        string[12] memory p;

        p[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.2" viewBox="0 0 600 600"><defs><pattern id="bleach" x="0" y="0" width="0.125" height="0.125"><image x="0" y="0" width="75" height="75" xlink:href="';
        
        p[1] = getBleach(tokenId);

        p[2] = '" /></pattern></defs><rect viewBox="0 0 600 600" width="600" height="600" fill="#';

        p[3] = backgroundColor(tokenId);

        p[4] = '" /><rect viewBox="0 0 600 600" width="600" height="600" fill="url(#bleach)" /><svg x="60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[5] = getPlain(tokenId);

        p[6] = '</svg>';

        p[7] = getPlain(tokenId);

        p[8] = '<svg x="-60" y="0" width="600" height="600" viewBox="0 0 600 600">';

        p[9] = getPlain(tokenId);

        p[10] = '</svg></svg>';

        string memory o = string(abi.encodePacked(p[0], p[1], p[2], p[3], p[4], p[5], p[6], p[7], p[8]));
        o = string(abi.encodePacked(o, p[9], p[10]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Pandemic Warhol #', toString(tokenId), '", "description": "', getDescription(tokenId), '", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(o)), '", "attributes": \x5B ', makeAttributes(tokenId), ' \x5D}'))));
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

    // Replace string utility

    function _stringReplace(string memory _string, uint256 _pos, string memory _letter) internal pure returns (string memory) {
        bytes memory _stringBytes = bytes(_string);
        bytes memory result = new bytes(_stringBytes.length);

        for(uint i = 0; i < _stringBytes.length; i++) {
                result[i] = _stringBytes[i];
                if(i==_pos)
                result[i]=bytes(_letter)[0];
            }
            return  string(result);
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