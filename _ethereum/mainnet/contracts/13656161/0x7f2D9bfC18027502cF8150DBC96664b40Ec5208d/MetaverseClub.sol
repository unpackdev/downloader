// SPDX-License-Identifier: MIT

/*

  Metaverse Club (MCLUB)
  mclub.eth
  @metaverseclub
  https://metaverseclub.io

*/

pragma solidity 0.8.7;

import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";

contract MetaverseClub is ERC721Enumerable, ReentrancyGuard, Ownable {

  // tokenId coounter
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  // room base url
  string public _roomBaseUrl = "https://metaverseclub.io/";

  // room-specific announcement
  mapping(uint256 => string) private _roomMessage;

  // price per mint and update room message
  uint256 public _price = 0.1 ether;

  // max supply
  uint256 public _maxSupply = 10000;

  // flag for public sale
  bool public _publicSale = false;

  // error msg
  string private tokenIdInvalid = "tokenId invalid";

  // set room message
  function setRoomMessage(uint256 tokenId, string memory newRoomMessage) external payable {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);
    require( msg.sender == ownerOf(tokenId), "token owner only");
    require( msg.value >= _price, "incorrect ETH sent" );
    _roomMessage[tokenId] = newRoomMessage;
  }

  // get room message
  function getRoomMessage(uint256 tokenId) public view returns (string memory) {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);
    bytes memory tempEmptyStringTest = bytes(_roomMessage[tokenId]);
    if (tempEmptyStringTest.length == 0) {
      uint256 randMsg = random("nft", tokenId);
      if (randMsg % 17 == 3)
        return "LFG!";
      else if (randMsg % 7 == 3)
        return "WAGMI!";
      else
        return "gm!";
    } else {
      return _roomMessage[tokenId];
    }
  }

  // set new price
  function setPrice(uint256 newPrice) external onlyOwner {
    _price = newPrice;
  }

  // set new room url
  function setRoomBaseUrl(string memory newUrl) external onlyOwner {
    _roomBaseUrl = newUrl;
  }

  // toggle public sale
  function publicSale(bool val) external onlyOwner {
    _publicSale = val;
  }

  // withdraw funds to owner's wallet
  function withdraw() external payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

  // mint num of keycards
  function mint(uint256 num) external payable nonReentrant {
    require( _publicSale, "public sale paused" );
    require( num <= 10, "max 10 per TX" );
    require( _tokenIdCounter.current() + num <= _maxSupply, "max supply reached" );
    require( msg.value >= _price * num, "incorrect ETH sent" );

    for( uint i = 0; i < num; i++ ) {
      _safeMint(_msgSender(), _tokenIdCounter.current() + 1);
      _tokenIdCounter.increment();
    }
  }

  // owner's mint to creator's address
  function mintToCreator(address creatorAddress) external nonReentrant onlyOwner {
    require( _tokenIdCounter.current() + 1 <= _maxSupply, "max supply reached" );
    _safeMint(creatorAddress, _tokenIdCounter.current() + 1);
    _tokenIdCounter.increment();
  }

  // owner to claim keycards
  function ownerClaim(uint256 num) external nonReentrant onlyOwner {
    require( _tokenIdCounter.current() + num <= _maxSupply, "max supply reached" );
    for (uint i = 0; i < num; i++) {
      _safeMint(owner(), _tokenIdCounter.current() + 1);
      _tokenIdCounter.increment();
    }
  }

  // room types
  string[] private assetRoomType = [
    "Camp",
    "Verse",
    "Vault",
    "Plaza",
    "Theater",
    "State",
    "Gallery",
    "Room",
    "Base",
    "Cafe",
    "Yacht",
    "School",
    "Keep",
    "Lab",
    "Home",
    "Factory",
    "Place",
    "Market",
    "Dream",
    "Bank",
    "City",
    "Class",
    "Kingdom",
    "Hall",
    "World",
    "Museum",
    "Game",
    "Dungeon",
    "Pit",
    "Hideout",
    "Planet",
    "Party",
    "Workshop",
    "Country",
    "Nation",
    "Maze",
    "Club",
    "Land",
    "Garden",
    "Asylum",
    "Heaven",
    "Salon",
    "Station",
    "Study",
    "Zone",
    "Arena",
    "Mansion",
    "Matrix",
    "Pub",
    "Space"
  ];

  // room themes
  string[] private assetRoomTheme = [
    "Gothic",
    "Bitcoin",
    "Sci-Fi",
    "Fugazi",
    "Open",
    "VR",
    "Mindful",
    "Meta",
    "Magical",
    "Doge",
    "Haunted",
    "YOLO",
    "DeFi",
    "Flow",
    "Logical",
    "Lion",
    "Doom",
    "Web3",
    "AI",
    "Mega",
    "Orc",
    "Bored",
    "Ethereum",
    "Toad",
    "Hidden",
    "Techno",
    "WAGMI",
    "Mutant",
    "3D",
    "Ape",
    "Network",
    "Skull",
    "Unicorn",
    "Satoshi",
    "Zombie",
    "Moon",
    "Robotic",
    "Crypto",
    "Cyber",
    "Cat",
    "Degen",
    "GM",
    "NFT",
    "Mad",
    "FOMO",
    "Punk",
    "Bear",
    "Coin"
  ];

  // get a random int from a string + tokenId
  function random(string memory input, uint256 tokenId) private pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input, toString(tokenId + 420001))));
  }

  // get a random element from an array
  function pluck(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) private pure returns (string memory) {
    return sourceArray[random(keyPrefix, tokenId) % sourceArray.length];
  }

  // get a room theme from tokenId
  function getRoomTheme(uint256 tokenId) public view returns (string memory) {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);
    return string(abi.encodePacked(pluck(tokenId, "theme", assetRoomTheme)));
  }

  // get a room type from tokenId
  function getRoomType(uint256 tokenId) public view returns (string memory) {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);
    return string(abi.encodePacked(pluck(tokenId, "type", assetRoomType)));
  }

  // get a room url from tokenId
  function getRoomURL(uint256 tokenId) public view returns (string memory) {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);
    return string(abi.encodePacked(_roomBaseUrl, toString(tokenId)));
  }

  // get a linked keycard from tokenId
  function getAssetLink1(uint256 tokenId) private pure returns (uint256) {
    if (tokenId > 1) {
      uint256 rand = random("link1", tokenId);
      if (rand % 99 < 70)
        return rand % (tokenId - 1) + 1;
      else
        return 0;
    } else {
      return 0;
    }
  }

  // get a 2nd linked keycard from tokenId
  function getAssetLink2(uint256 tokenId) private pure returns (uint256) {
    uint256 rand = random("link2", tokenId);
    uint256 link2Id = rand % (tokenId - 1) + 1;
    if (link2Id == getAssetLink1(tokenId)){
      return 0;
    } else {
      if (rand % 99 < 50)
        return link2Id;
      else
        return 0;
    }
  }

  // generate metadata for links
  function getAssetLinks(uint256 tokenId) private pure returns (string memory) {
    string memory traitTypeJson = ', {"trait_type": "Linked", "value": "';
    if (getAssetLink1(tokenId) < 1)
      return '';
    if (getAssetLink2(tokenId) > 0) {
      return string(abi.encodePacked(traitTypeJson, '2 Rooms"}'));
    } else {
      return string(abi.encodePacked(traitTypeJson, '1 Room"}'));
    }
  }

  // generate metadata for stars
  function haveStar(uint256 tokenId) private pure returns (string memory) {
    uint256 starSeed = random("star", tokenId);
    string memory traitTypeJson = ', {"trait_type": "Star", "value": "';
    if (starSeed % 47 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Sirius"}'));
    if (starSeed % 11 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Vega"}'));
    return '';
  }

  // render stars in SVG
  function renderStar(uint256 tokenId) private pure returns (string memory) {
    string memory starFirstPart = '<defs><linearGradient id="star" x1="100%" y1="100%"><stop offset="0%" stop-color="black" stop-opacity=".5"><animate attributeName="stop-color" values="black;black;black;black;gray;';
    string memory starLastPart = ';gray;black;black;black;black" dur="3s" repeatCount="indefinite" /></stop></linearGradient></defs><g style="transform:translate(130px,244px)"><g style="transform:scale(0.1,0.1)"><path fill="url(#star)" d="M189.413,84c-36.913,0-37.328,38.157-37.328,38.157c0-33.181-36.498-38.157-36.498-38.157  c37.328,0,36.498-38.157,36.498-38.157C152.085,84,189.413,84,189.413,84z" /></g></g>';
    uint256 starSeed = random("star", tokenId);
    if (starSeed % 47 == 1)
      return string(abi.encodePacked(starFirstPart, 'aqua', starLastPart));
    if (starSeed % 11 == 1)
      return string(abi.encodePacked(starFirstPart, 'white', starLastPart));
    return '';
  }

  // generate metadata for keys
  function haveKey(uint256 tokenId) private pure returns (string memory) {
    uint256 keySeed = random("key", tokenId);
    string memory traitTypeJson = ', {"trait_type": "Key", "value": "';
    if (keySeed % 301 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Rainbow Key"}'));
    if (keySeed % 161 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Crystal Key"}')); //afcfff
    if (keySeed % 59 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Gold Key"}')); //ffff33
    if (keySeed % 31 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Silver Key"}')); //dddddd
    if (keySeed % 11 == 1)
      return string(abi.encodePacked(traitTypeJson, 'Jade Key"}')); // 66ff66
    return string(abi.encodePacked(traitTypeJson, 'Copper Key"}')); // 995500
  }

  // render keys in SVG
  function renderKey(uint256 tokenId) private pure returns (string memory) {
    string memory keyFirstPart = '<g transform="translate(267,63) scale(0.02,-0.02) rotate(135)" fill="';
    string memory keyLastPart = '" stroke="none"><path d="M832 1024q0 80-56 136t-136 56q-80 0-136-56t-56-136q0-42 19-83-41 19-83 19-80 0-136-56t-56-136q0-80 56-136t136-56q80 0 136 56t56 136q0 42-19 83 41-19 83-19 80 0 136 56t56 136zm851-704q0-17-49-66t-66-49q-9 0-28.5 16t-36.5 33q-17 17-38.5 40t-24.5 26l-96-96L1564 4q28-28 28-68 0-42-39-81t-81-39q-40 0-68 28L733 515Q557 384 368 384q-163 0-265.5 102.5T0 752q0 160 95 313t248 248q153 95 313 95 163 0 265.5-102.5T1024 1040q0-189-131-365l355-355 96 96q-3 3-26 24.5t-40 38.5q-17 17-33 36.5t-16 28.5q0 17 49 66t66 49q13 0 23-10 6-6 46-44.5t82-79.5q42-41 86.5-86t73-78q28.5-33 28.5-41z"/></g>';
    uint256 keySeed = random("key", tokenId);
    if (keySeed % 301 == 1)
      return string(abi.encodePacked('<defs><linearGradient id="rainbow" x1="100%" y1="100%"><stop offset="0%" stop-color="white" stop-opacity=".9"><animate attributeName="stop-color" values="white;red;orange;yellow;green;lightblue;lightpurple;white;" dur="7s" repeatCount="indefinite" /></stop></linearGradient></defs>', keyFirstPart, 'url(#rainbow)', keyLastPart));
    if (keySeed % 161 == 1)
      return string(abi.encodePacked(keyFirstPart, '#afcfff', keyLastPart));
    if (keySeed % 59 == 1)
      return string(abi.encodePacked(keyFirstPart, '#ffff33', keyLastPart));
    if (keySeed % 31 == 1)
      return string(abi.encodePacked(keyFirstPart, '#dddddd', keyLastPart));
    if (keySeed % 11 == 1)
      return string(abi.encodePacked(keyFirstPart, '#66ff66', keyLastPart));
    return string(abi.encodePacked(keyFirstPart, '#995500', keyLastPart));
  }

  // generate metadata for description
  function getDescription(uint256 tokenId) private view returns (string memory) {
    string memory description0 = string(abi.encodePacked('This is a keycard to launch [#', toString(tokenId), ' ', getRoomTheme(tokenId), ' ', getRoomType(tokenId),'](', string(abi.encodePacked(_roomBaseUrl, toString(tokenId))), ') with one click.'));
    string memory description1 = ' And check the linked ';
    uint256 link1Id = getAssetLink1(tokenId);
      if (link1Id > 0) {
        string memory link1description = string(abi.encodePacked('[#', toString(link1Id), ' ', getRoomTheme(link1Id), ' ', getRoomType(link1Id), '](', string(abi.encodePacked(_roomBaseUrl, toString(link1Id))) ,')'));
        uint256 link2Id = getAssetLink2(tokenId);
        if (link2Id > 0) {
          string memory link2description = string(abi.encodePacked('[#', toString(link2Id), ' ', getRoomTheme(link2Id), ' ', getRoomType(link2Id), '](', string(abi.encodePacked(_roomBaseUrl, toString(link2Id))) ,')'));
          if (link2Id > link1Id)
            return string(abi.encodePacked(description0, description1, link1description,' and ',link2description, '.'));
          else
            return string(abi.encodePacked(description0, description1, link2description,' and ',link1description, '.'));
        } else {
          return string(abi.encodePacked(description0, description1, link1description,'.'));
        }
      } else {
        return description0;
      }
    }

  // get a random gradient color from tokenId
  function getBackgrounGradient(uint256 tokenId) private pure returns (string memory) {
    uint256 colorSeed = random("color", tokenId);
    if ( colorSeed % 7 == 3)
      return "black;red;gray;red;purple;black;";
    if ( colorSeed % 7 == 2)
      return "black;green;black;";
    if ( colorSeed % 7 == 1)
      return "black;blue;black;";
    if ( colorSeed % 7 == 4)
      return "black;lightblue;black;";
    if ( colorSeed % 7 == 5)
      return "black;red;purple;blue;black;";
    if ( colorSeed % 7 == 6)
      return "black;blue;purple;blue;black;";
    return "black;gray;red;purple;black;";
  }

  // generate metadata for lasers
  function haveLaser(uint256 tokenId) private pure returns (string memory) {
    uint256 laserSeed = random("laser", tokenId);
    string memory traitTypeJson = ', {"trait_type": "Laser", "value": "';
    if (laserSeed % 251 == 2)
      return string(abi.encodePacked(traitTypeJson, 'Dual Green Lasers"}'));
    if (laserSeed % 167 == 2)
      return string(abi.encodePacked(traitTypeJson, 'Dual Red Lasers"}'));
    if (laserSeed % 71 == 2)
      return string(abi.encodePacked(traitTypeJson, 'Green Laser"}'));
    if (laserSeed % 31 == 2)
      return string(abi.encodePacked(traitTypeJson, 'Red Laser"}'));
    return '';
  }

  // render keycard in SVG
  function renderBackground(uint256 tokenId) private pure returns (string memory) {
    uint256 laserSeed = random("laser", tokenId);
    string memory attribPyramidLasers = '';
    bool dualLasers = false;
    bool singleLaser = false;
    string memory laserColor = 'red';

    if (laserSeed % 31 == 2) { 
      singleLaser = true;
      dualLasers = false;
      laserColor = 'red';
    }

    if (laserSeed % 71 == 2) { 
      singleLaser = true;
      laserColor = 'green';
    }

    if (laserSeed % 167 == 2) { 
      singleLaser = false;
      dualLasers = true;
      laserColor = 'red';
    }

    if (laserSeed % 251 == 2) { 
      singleLaser = false;
      dualLasers = true;
      laserColor = 'green';
    }

    string memory attribPyramidLasersFirstPart = string(abi.encodePacked('<g transform="translate(-154.5,-36)"><line x1="0" y1="0" x2="300" y2="300" stroke="', laserColor, '" stroke-width="1.5" stroke-opacity="1.0"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 300 300" to="360 300 300" dur="20s" repeatCount="indefinite" /></line>'));
    string memory attribPyramidLasersDoublePart = string(abi.encodePacked('<line x1="0" y1="0" x2="300" y2="300" stroke="', laserColor, '" stroke-width="1.5" stroke-opacity="1.0"><animateTransform attributeName="transform" attributeType="XML" type="rotate" from="5 300 300" to="365 300 300" dur="20s" repeatCount="indefinite" /></line>'));
    string memory attribPyramidLasersEndingPart = '</g>';

    if (singleLaser)
      attribPyramidLasers = string(abi.encodePacked(attribPyramidLasersFirstPart, attribPyramidLasersEndingPart));

    if (dualLasers)
      attribPyramidLasers = string(abi.encodePacked(attribPyramidLasersFirstPart, attribPyramidLasersDoublePart, attribPyramidLasersEndingPart));

    return string(abi.encodePacked('<g clip-path="url(#b)"><path fill="000000" d="M0 0h290v500H0z" /><path fill="url(#backgroundGradient)" d="M0 0h290v500H0z" /><g style="filter:url(#d);transform:scale(2.9);transform-origin:center top"><path fill="none" d="M0 0h290v500H0z" /><ellipse cx="50%" rx="180" ry="120" opacity=".95" /></g>', string(abi.encodePacked('<g><filter id="dpf"><feTurbulence type="turbulence" baseFrequency="0.', toString(random("fq", tokenId) % 4), '2" numOctaves="2" result="turbulence" /><feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G" /></filter><circle cx="120" cy="-10" r="200" fill="url(#backgroundGradient)" opacity=".3" style="filter: url(#dpf)" /></g>')), '<g style="transform:translate(94px,264px)"><g style="transform:scale(.4,.4)" fill="url(#backgroundGradient)" stroke="rgba(255,255,255,1)"><path stroke-width="2.5" opacity=".5" d="m127.961 0-2.795 9.5v275.668l2.795 2.79 127.962-75.638z"/><path stroke-width="1.8" opacity=".85" d="M127.962 0 0 212.32l127.962 75.639V154.158z"/></g></g>', attribPyramidLasers, '</g>'));
  }

  // generate basic attributes in metadata
  function haveBasicAttributes(uint256 tokenId) private view returns (string memory) {
    string memory traitTypeJson = '{"trait_type": "';
    return string(abi.encodePacked(string(abi.encodePacked(traitTypeJson, 'Room Type", "value": "', getRoomType(tokenId), '"}, ')), string(abi.encodePacked(traitTypeJson, 'Room Theme", "value": "', getRoomTheme(tokenId), '"}')), getAssetLinks(tokenId)));
  }

  // generate tokenURI from tokenId
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    require(_tokenIdCounter.current() >= tokenId && tokenId > 0, tokenIdInvalid);

    // token info
    string memory tokenFullName = string(abi.encodePacked(getRoomTheme(tokenId), ' ', getRoomType(tokenId)));
    string memory cardInfo = string(abi.encodePacked('<g><text y="70" x="29" fill="#fff" font-family="monospace" font-weight="200" font-size="36">#',toString(tokenId),'</text><text y="115" x="28" fill="#fff" font-family="monospace" font-weight="200" font-size="22">',tokenFullName,'</text><text y="140" x="29" font-family="monospace" font-size="14" fill="#fff"><tspan fill="rgba(255,255,255,0.8)">Metaverse Club</tspan></text></g><g style="transform:translate(22px,444px)" clip-path="url(#e)"><rect width="247" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)" /><text x="9" y="17" font-family="monospace" font-size="14" fill="#fff"><tspan fill="rgba(255,255,255,0.6)">',tokenFullName,': </tspan>', getRoomMessage(tokenId),'<animate attributeType="XML" attributeName="x" values="300;-300" dur="15s" repeatCount="indefinite" /></text></g>'));
    string memory svgExtra = string(abi.encodePacked(renderKey(tokenId), renderStar(tokenId)));
    string memory renderDefs = string(abi.encodePacked('<defs><linearGradient id="backgroundGradient" x1="100%" y1="100%"><stop offset="0%" stop-color="black" stop-opacity=".5"><animate attributeName="stop-color" values="', getBackgrounGradient(tokenId),'" dur="20s" repeatCount="indefinite" /></stop></linearGradient></defs><defs><filter id="c"><feImage result="p0" xlink:href="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0nMjkwJyBoZWlnaHQ9JzUwMCcgdmlld0JveD0nMCAwIDI5MCA1MDAnIHhtbG5zPSdodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2Zyc+PHJlY3Qgd2lkdGg9JzI5MHB4JyBoZWlnaHQ9JzUwMHB4JyBmaWxsPScjZjY1YjVjJy8+PC9zdmc+" /></filter><filter id="d"><feGaussianBlur in="SourceGraphic" stdDeviation="', toString(random("sd", tokenId) % 50 + 10), '" /></filter><linearGradient id="a"><stop offset=".7" stop-color="#fff" /><stop offset=".95" stop-color="#fff" stop-opacity="0" /></linearGradient><clipPath id="b"><rect width="290" height="500" rx="42" ry="42" /></clipPath><clipPath id="e"><rect width="247" height="26" rx="8" ry="8"/></clipPath></defs>'));
    string memory outputSVG = string(abi.encodePacked('<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="290" height="500" viewBox="0 0 290 500">', renderDefs, renderBackground(tokenId), cardInfo, svgExtra, '</svg>'));

    // render attributes
    string memory attributes = string(abi.encodePacked('"attributes": [{"trait_type": "Room Name", "value": "', tokenFullName, '"}, ', haveBasicAttributes(tokenId), haveStar(tokenId), haveKey(tokenId), haveLaser(tokenId), ']'));

    // render output json
    string memory basicInfo = string(abi.encodePacked('"name": "#', toString(tokenId), ' ', tokenFullName, '", "description": "', getDescription(tokenId),'", "external_url": "', string(abi.encodePacked(_roomBaseUrl, toString(tokenId))), '", '));
    string memory output = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{', basicInfo, attributes,', "image": "data:image/svg+xml;base64,', Base64.encode(bytes(outputSVG)),'"}'))))));
    return output;
  }

  function toString(uint256 value) private pure returns (string memory) {
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

  constructor() ERC721("Metaverse Club", "MCLUB") Ownable() {}
}