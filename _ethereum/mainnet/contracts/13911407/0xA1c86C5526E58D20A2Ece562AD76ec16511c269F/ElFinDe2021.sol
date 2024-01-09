// El Fin de 2021
// By @arithmetric (constellate.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";

import "./base64.sol";

contract ElFinDe2021 is ERC721 {
    mapping (uint256 => string) public messages;

    uint256 public maxSupply = 2021;

    uint256 public totalSupply;

    constructor() ERC721("El Fin de 2021", "2021") {
      totalSupply++;
      _mint(_msgSender(), totalSupply);
      messages[1] = "Happy New Year!";
      totalSupply++;
      _mint(_msgSender(), totalSupply);
      messages[2] = "It's been real 2021...";
      totalSupply++;
      _mint(_msgSender(), totalSupply);
      messages[3] = "Hello 2022!";
    }

    function gift(address to, string calldata message) public {
      require(_msgSender() != to, "Gift cannot be sent to sender");
      require(totalSupply <= maxSupply, "Mint limit has been reached");
      totalSupply++;
      _safeMint(to, totalSupply);
      messages[totalSupply] = message;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot get tokenURI for nonexistent token");

        string memory message = messages[tokenId];

        bytes32 mhash = keccak256(bytes(message));
        string memory mhashs = toHex(mhash);
        string memory p1 = Strings.toString(uint(uint8(mhash[4])) * 7);
        string memory p2 = Strings.toString(uint(uint8(mhash[6])) * 7);
        string memory c1 = getSlice(60, 62, mhashs);
        string memory c2 = getSlice(62, 64, mhashs);
        string memory c3 = getSlice(64, 66, mhashs);

        string memory output = Base64.encode(bytes(string(abi.encodePacked('<svg viewBox="0 0 2021 2021" xmlns="http://www.w3.org/2000/svg"><style>.t {font:bold 430px monospace;text-anchor:middle} .t.m {font-size:120px}</style><rect width="100%" height="100%" fill="#', c1, '"/><polygon points="0 0 0 2021 ', p1, ' 0" fill="#', c2, '"/><polygon points="2021 2021 2021 0 ', p2, ' 2021" fill="#', c3, '"/><text x="50%" y="30%" class="t m">el fin de <animate attributeName="y" values="30%;30%;30%;30%;30%;-1202%" dur="4.7" repeatCount="2021" /></text><text class="t" x="20%" y="50%">2 <animate attributeName="y" dur="4.7" repeatCount="2021" values="50%;50%;-1202%"/></text><text class="t" x="40%" y="50%">0 <animate attributeName="y" dur="4.7" repeatCount="2021" values="50%;50%;50%;1202%"/></text><text class="t" x="60%" y="50%">2 <animate attributeName="y" dur="4.7" repeatCount="2021" values="50%;50%;50%;50%;-1202%"/></text><text class="t" x="80%" y="50%">1 <animate attributeName="y" dur="4.7" repeatCount="2021" values="50%;50%;50%;50%;50%;1202%"/></text><text class="t m" x="50%" y="160%">', message, ' <animate attributeName="y" dur="4.7" repeatCount="2021" values="221%;221%;80%;80%"/></text></svg>'))));
        output = Base64.encode(bytes(string(abi.encodePacked('{"name": "#', Strings.toString(tokenId), ' - ', message, '", "image": "data:image/svg+xml;base64,', output, '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', output));
        return output;
    }

    function getSlice(uint256 begin, uint256 end, string memory text) internal pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = bytes(text)[i+begin-1];
        }
        return string(a);
    }

    function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
        result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
            (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
        result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
            (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
        result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
            (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
        result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
            (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
        result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
            (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
        result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
            uint256 (result) +
            (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
            0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
    }

    function toHex (bytes32 data) internal pure returns (string memory) {
        return string(abi.encodePacked("0x", toHex16(bytes16 (data)), toHex16(bytes16 (data << 128))));
    }
}
