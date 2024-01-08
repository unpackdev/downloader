//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Base64.sol";
import "./console.sol";

contract Tree is ERC721Enumerable, ReentrancyGuard, Ownable {
  uint256 public treeCount = 0;

  mapping(address => bool) beenGifted;
  mapping(uint256 => uint256) treeGiftedFrom;
  mapping(uint256 => uint256) treeSprouts;

  uint256 public maxViewLevel = 11;
  uint256 maxCountLevel = 17;

  uint256 public price = 0.001 ether;

  function setMaxViewLevel(uint256 _maxViewLevel) public onlyOwner {
    maxViewLevel = _maxViewLevel;
  }

  function setPrice(uint256 newPrice) public onlyOwner {
    price = newPrice;
  }

  function plant() public payable {
    require(msg.value >= price, 'PRICE_NOT_MET');
    treeCount += 1;
    _safeMint(msg.sender, treeCount);
  }

  function gift(address friend) public payable {
    require(beenGifted[friend] == false, 'first gift');
    require(msg.sender != friend, 'cannot gift to yourself');
    require(msg.value >= price, 'PRICE_NOT_MET');
    treeCount += 1;
    beenGifted[friend] = true;
    _safeMint(friend, treeCount);

    uint256 giftId = tokenOfOwnerByIndex(msg.sender, 0);

    if (giftId != 0) {
      treeGiftedFrom[treeCount] = giftId;
    }

    uint256 parentId = giftId;
    for (uint8 i = 0; i < maxCountLevel; i++) {
      if (parentId != 0) {
        treeSprouts[parentId] += 1;
        parentId = treeGiftedFrom[parentId];
      }
    }
  }

  function withdrawAll() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  function getTreeLevel(uint256 tokenId) public view returns (uint256) {
    return treeSprouts[tokenId];
  }

  string[][] colors = [
    ['28FFD5', '27DAFF', 'FFD2FA', 'FC00B4', '2600FC'],
    ['D92B6B', '410759', '238C82', 'F29E38', 'F25C05'],
    ['FA0C97', 'D30BDE', 'AF18F5', '630BDE', '2C0CFA'],
    ['FF9B8C', 'FFF7AB', 'ACEBBA', 'B2E1FF', 'DBC0FF'],
    ['0BBCD6', '0FD9BE', '17C37B', 'FF9966', 'E6625E'],
    ['1593E8', '16ADE1', '79D91A', 'C0F551', '40EEFC'],
    ['BF0426', '37848C', 'F2AE30', 'F24405', 'A62103']
  ];

  function randomToken(uint256 tokenId) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(tokenId)));
  }

  function levelXml(uint256 tokenId, uint256 level)
    public
    view
    returns (string memory)
  {
    uint256 random = randomToken(tokenId);
    uint256 offset = randomToken(tokenId) % 5;
    string[] memory curColors = colors[random % colors.length];

    uint256 left = 45;
    uint256 right = 22;
    if (random % 2 == 0) {
      left = 22;
      right = 45;
    }

    return
      string(
        abi.encodePacked(
          "<g id='l",
          toString(level),
          "'><use xlink:href='#l",
          toString(level - 1),
          "' transform='translate(0, -1) rotate(-",
          toString(left),
          ") scale(.7)'></use><use xlink:href='#l",
          toString(level - 1),
          "' transform='translate(0, -1) rotate(+",
          toString(right),
          ") scale(.7)'></use><use xlink:href='#stem' stroke='#",
          curColors[(level + offset) % curColors.length],
          "'></use><use xlink:href='#bubbles' fill='#",
          curColors[(level + offset) % curColors.length],
          "'></use></g>"
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    string memory output;
    string memory stringTokenId = toString(tokenId);

    uint256 sprout = treeSprouts[tokenId];
    uint256 level = 3;

    if (sprout > 2**14) {
      level = 11;
    } else if (sprout > 2**9) {
      level = 10;
    } else if (sprout > 2**6) {
      level = 9;
    } else if (sprout > 2**4) {
      level = 8;
    } else if (sprout > 2**3) {
      level = 7;
    } else if (sprout > 2**2) {
      level = 6;
    } else if (sprout > 2) {
      level = 5;
    } else if (sprout > 0) {
      level = 4;
    } else {
      level = 3;
    }

    if (maxViewLevel <= level) {
      level = maxViewLevel;
    }

    uint256 random = randomToken(tokenId);
    uint256 offset = randomToken(tokenId) % 5;
    string[] memory curColors = colors[random % colors.length];

    output = string(
      abi.encodePacked(
        "<g id='l0'><use xlink:href='#stem' stroke='#",
        curColors[offset],
        "'></use><use xlink:href='#bubbles' fill='#",
        curColors[offset],
        "'></use></g>"
      )
    );

    output = string(
      abi.encodePacked(
        output,
        levelXml(tokenId, 1),
        levelXml(tokenId, 2),
        levelXml(tokenId, 3),
        levelXml(tokenId, 4),
        levelXml(tokenId, 5)
      )
    );

    output = string(
      abi.encodePacked(
        output,
        levelXml(tokenId, 6),
        levelXml(tokenId, 7),
        levelXml(tokenId, 8),
        levelXml(tokenId, 9),
        levelXml(tokenId, 10),
        levelXml(tokenId, 11)
      )
    );

    output = string(
      abi.encodePacked(
        "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='1000' height='1000'><rect width='1000' height='1000' style='fill:black'></rect><defs><g id='stem'><line x1='0' y1='0' x2='0' y2='-0.7' stroke-width='0.1'></line></g><g id='bubbles'><circle cx='0' cy='-0.7' r='0.05'></circle><circle cx='0' cy='0' r='0.05'></circle></g>",
        output,
        "</defs><g transform='translate(500, 820) scale(200)'><use xlink:href='#l",
        toString(level),
        "'></use></g><text x='10' y='990' fill='white' font-family='Arial, Helvetica, sans-serif'>",
        toString(sprout),
        '</text></svg>'
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Friend Tree #',
            stringTokenId,
            '", "description": "Friend Tree is a tree that grows as you give it away.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );

    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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

  constructor() ERC721('Tree', 'TREE') Ownable() {}
}
