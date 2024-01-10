//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./ERC721A.sol";

// Developed by Poyo.eth & Zizibizi.eth

contract Strangers is ERC721A, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  Counters.Counter private _tokenId;
  struct Stranger {
    string background;
    string headColor;
    string bodyColor;
    string hairColor;
    uint256 hairLength;
    string armsColor;
    string handsColor;
    string legsColor;
    string footColor;
    string skirtColor;
    string personality;
  }

  string[] private personalities = ["Architect","Logician","Commander","Debater","Advocate","Mediator","Protagonist","Campaigner", "Logistician", "Defender", "Executive", "Consul", "Virtuoso", "Adventurer", "Entrepreneur", "Entertainer"];
  string[] private background = ["#FFDFC8","#C8EFFF","#E3FFC8","#F4FFC8","#C8E4FF","#FFF0C8","#C8FFEB"];
  string[] private fill = ["#F45800","#26C7AA","#FF9A9A","#FFC700","#7479FF","#2666C7","#FF7474"];
  uint256[] private hairLength = [25, 30, 35];

  bool public paused = true;
  uint256 public supply = 1600;
  uint256 public price = 0.04 ether;
  mapping (string => string) private traitNames;
  mapping(uint256 => uint256) private strangers;

  constructor() ERC721A("Strangers", "STRG") {
    //FILLS
    traitNames["#F45800"] = 'Red';
    traitNames["#26C7AA"] = 'Teal';
    traitNames["#FF9A9A"] = 'Pink';
    traitNames["#FFC700"] = 'Yellow';
    traitNames["#7479FF"] = 'Purple';
    traitNames["#2666C7"] = 'Dark Blue';
    traitNames["#FF7474"] = 'Dark Pink';
    //BACKGROUND
    traitNames["#FFDFC8"] = 'Red';
    traitNames["#C8EFFF"] = 'Blue';
    traitNames["#E3FFC8"] = 'Green';
    traitNames["#F4FFC8"] = 'Yellow';
    traitNames["#C8E4FF"] = 'Purple';
    traitNames["#FFF0C8"] = 'Orange';
    traitNames["#C8FFEB"] = 'Aquamarine';
    //HAIR LENGTH
    traitNames[Strings.toString(25)] = 'Short';
    traitNames[Strings.toString(30)] = 'Medium';
    traitNames[Strings.toString(35)] = 'Long';
  }

  function setPrice(uint128 _price) external onlyOwner {
      price  = _price;
  }

  function setSupply(uint128 _supply) external onlyOwner {
      supply  = _supply;
  }

  function getStrangerAttr(uint256 token) internal view returns (Stranger memory) {
    uint256 dna = strangers[token];
    uint256[11] memory dnaDigits;
    for (uint256 index = 0; index < 11; index++) 
      dnaDigits[index] = (dna / 10**((index + 1) * 2)) % 10**2; 
    
    string[] memory fills = fill;
    Stranger memory stranger;
      stranger.background = background[dnaDigits[0] % background.length];
      stranger.headColor = fills[dnaDigits[1] % fills.length];
      stranger.bodyColor = exclude(fills, stranger.headColor)[dnaDigits[2] % exclude(fills, stranger.headColor).length];
      string[] memory armsColors = exclude(fills, stranger.bodyColor);
      stranger.armsColor = armsColors[dnaDigits[4] % armsColors.length];
      stranger.handsColor = exclude(armsColors, stranger.armsColor)[dnaDigits[5] % exclude(armsColors, stranger.armsColor).length];
      string[] memory legsColors = exclude(fills, stranger.bodyColor);
      stranger.legsColor = legsColors[dnaDigits[6] % legsColors.length];
      stranger.footColor = exclude(fills, stranger.legsColor)[
        (dnaDigits[7] % exclude(fills, stranger.legsColor).length)
      ];
      stranger.hairLength = hairLength[dnaDigits[8] % hairLength.length];
      stranger.hairColor= dnaDigits[3] < 70
        ? exclude(fills, stranger.headColor)[dnaDigits[3] % exclude(fills, stranger.headColor).length]
        : '';
      stranger.skirtColor = dnaDigits[9] < 25 
        ? fills[dnaDigits[9] % fills.length]
        : '';
      stranger.personality = personalities[dnaDigits[10] % personalities.length];

    return stranger;
  }

  function image(uint256 token) internal view returns (string memory) {
    Stranger memory stranger = getStrangerAttr(token);

    string memory output = string(abi.encodePacked(
      '<svg width="600" height="600" xmlns="http://www.w3.org/2000/svg"><rect fill="',stranger.background,'" width="600" height="600" /><rect fill="',stranger.bodyColor,'" x="280" y="262.5" width="40" height="75"/><rect opacity="', bytes(stranger.hairColor).length != 0 ? '1' : '0' ,'" fill="',stranger.hairColor,'" x="287.5" y="',stranger.hairLength == 30 ? Strings.toString(262 - stranger.hairLength) : Strings.toString(257 - stranger.hairLength),'" width="25" height="',Strings.toString(stranger.hairLength),'"/><rect fill="',stranger.headColor,'" x="290.625" y="237.5" width="18.75" height="25"/>'));

    output = string(abi.encodePacked(output,'<rect fill="',stranger.armsColor,'" x="268.75" y="262.5" width="11.25" height="55"/><rect fill="',stranger.armsColor,'" x="320" y="262.5" width="11.25" height="55"/><rect fill="',stranger.handsColor,'" x="268.75" y="317.5" width="11.25" height="7.5"/><rect fill="',stranger.handsColor,'" x="320" y="317.5" width="11.25" height="7.5"/>'));

    output = string(abi.encodePacked(output,'<rect fill="',stranger.legsColor,'" x="282.5" y="337.5" width="13.75" height="42.5"/><rect fill="',stranger.legsColor,'" x="303.75" y="337.5" width="13.75" height="42.5"/><rect fill="',stranger.footColor,'" x="282.5" y="380" width="13.75" height="10"/><rect fill="',stranger.footColor,'" x="303.75" y="380" width="13.75" height="10"/><rect opacity="', bytes(stranger.skirtColor).length != 0 ? '1' : '0' ,'" fill="',stranger.skirtColor,'" x="280" y="312.5" width="40" height="50"/></svg>'));
    return output;
  }

  function attributes(uint256 token) internal view returns (string memory) {
    Stranger memory stranger = getStrangerAttr(token);

    bool hasHair = bytes(stranger.hairColor).length != 0;
    string memory hairlengthTrait = hasHair ? string(abi.encodePacked('{"trait_type": "Hair Length", "value":"',traitNames[Strings.toString(stranger.hairLength)],'"},')) : '';
    string memory hairColorTrait = hasHair ? string(abi.encodePacked('{"trait_type": "Hair", "value":"',traitNames[stranger.hairColor],'"},')) : '';
    string memory skirtColorTrait = bytes(stranger.skirtColor).length != 0 ? string(abi.encodePacked('{"trait_type": "Skirt", "value":"',traitNames[stranger.skirtColor],'"},')) : '';
    return string(abi.encodePacked(
      '"attributes": [{"trait_type": "Background", "value":"',traitNames[stranger.background],'"},{"trait_type": "Head", "value":"',traitNames[stranger.headColor],'"},{"trait_type": "Body", "value":"',traitNames[stranger.bodyColor],'"},{"trait_type": "Arms", "value":"',traitNames[stranger.armsColor],'"},', hairlengthTrait, hairColorTrait, skirtColorTrait, '{"trait_type": "Hands", "value":"',traitNames[stranger.handsColor],'"},{"trait_type": "Legs", "value":"',traitNames[stranger.legsColor],'"},{"trait_type": "Foot", "value":"',traitNames[stranger.footColor],'"},{"trait_type": "Personality", "value":"',stranger.personality,'"}]'));
  }

  function tokenURI(uint256 token) public view virtual override returns (string memory) {
    require(_exists(token), "NE");
    return string(abi.encodePacked(
      "data:application/json;base64,",
      Base64.encode(bytes(
        string(abi.encodePacked('{"name": "Stranger #',Strings.toString(token),'", "description": "Strangers is a beautifully simple on-chain generative project of colorful and abstract people living on a blockchain.", "image": "data:image/svg+xml;base64,',Base64.encode(bytes(image(token))),'",',attributes(token), '}'
        ))
      ))
    ));
  }

  function exclude(string[] memory _array, string memory _color) internal pure returns (string[] memory) {
    string[] memory array = new string[](_array.length - 1); uint256 j;
    for (uint256 i = 0; i < _array.length; i++) {
      if (keccak256(bytes(_array[i])) != keccak256(bytes(_color))) { array[j] = _array[i]; j++;}
    }
    return array;
  }

  function mint(uint256 _amount) external payable {
    require(!paused, "CP");
    require(msg.value >= price.mul(_amount), "NEE");
    require(supply >= _tokenId.current().add(_amount),"NES");

    for (uint256 index = 0; index < _amount; index++) {
      uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId.current(), msg.sender)));
      strangers[_tokenId.current()] = dna;
      _tokenId.increment();
    }

    _safeMint(msg.sender, _amount);
  }

  function teamMint(uint256 _amount) external onlyOwner{
    require(supply >= _tokenId.current().add(_amount),"NES");

    for (uint256 index = 0; index < _amount; index++) {
      uint256 dna = uint256(keccak256(abi.encodePacked(block.timestamp, _tokenId.current(), msg.sender)));
      strangers[_tokenId.current()] = dna;
      _tokenId.increment();
    }

    _safeMint(msg.sender, _amount);
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }

  function emergencyFundsWithdrawal(address _receiver, uint256 _amount) external onlyOwner {
    payable(_receiver).transfer(_amount);
  }
}
