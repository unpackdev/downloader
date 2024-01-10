// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkdolo0WMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOdolcc:::cll,:XMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNX0kxddxkKKl..cdxkkOOOOkl,xWMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWWWXklc:::::cc:::'.''oOkkkkkkkkd,:XMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMWWWWKkdllcccclc;;ldxkkkOOOOkkl''.:kkkkkkkkkkc,kMMMMMMMMMM
// MMMMMMMMMWWXKOkdolc:::::cldxxxxoclkOkkkkkkkkkkkk:..'okkkkkkkkkd,cXMMMMMMMMM
// MMMMMMW0olcc:::clodl:lxOOkOkkOkkkkkkkkkkkkkkkkkko'..;xkkkkkkkkx:,kMMMMMMMMM
// MMMMMNx..cxxkOOOOOOkkkkkkkkkkkkkkkkkxxxkkkkkkkkkx:..'okkxkkxxxxo'cNMMMMMMMM
// MMMMXo;:':kOOkkkkkkkkkkkkkkkkkkkkkd:..,okkkkkkkkko'..;xxxxxxxxxx:,kMMMMMMMM
// MMMKc;x0c'okkkkkkkkkkxoldkkkkkkkkkd,  .:xkkxxxxxxx;..'oxxxxxxxxxo'lNMMMMMMM
// MWO::OKKx':kkkkkkkkkkc. ,dkkkkkxxxxc.  'oxxxxxxxxxl...:xxxxxxxxxd;,OMMMMMMM
// MK:;OKKK0:'okkkkkkkkko. .lxxxxxxxxxd,  .:xxxxxxxxxd;..'lxxxddddddl'lNMMMMMM
// MXc;OKKKKd':xkkxxxxxxx;  ,dxxxxxxxxxc'. 'oxxxxxxxxxc...;ddddolc:;,.,0MMMMMM
// MMk,o0K00O;'oxxxxxxxxxl. .lxxxxxxxxxoc' .:dddddddddo,. .,,'.........oWMMMMM
// MMXc;k0000o':xxxxxxxxxd;  ,dxxxxxddddd:. 'ldddddddddc.  .',;:cllooo,,0MMMMM
// MMWx,o0000k;'oxxxxxxxxxl. .lxdddddddddo' .;dddddddddo' .'lddddoooooc'oWMMMM
// MMMX:;kOOOOl.:dxdddddddd,  ,ddddddddddd;. 'ldddddddoo:...;oooooooool';0MMMM
// MMMWx,oOOOOx,'odddddddddc. .lddddddddddl. .;oddooooool'..'looooolc:;..xWMMM
// MMMMK:;xOOOkc.:dddddddddo,  ;oddddddoodo;. 'looooooooo;...';,'........:KMMM
// MMMMWd,lkkkkd''lddddddddd:. .cooooooooooc. .;oooooooool'.....'',;:ccl;'dWMM
// MMMMMK;;xkkkx:.:oddooooool'  ;ooooooooll:. .'loooooooolc::cllllllllllc';KMM
// MMMMMWd'lkxkxo''looooooooo:. .::;;,,',''..;,.;ollollllllllllllllllllll;'dWM
// MMMMMM0;;dxxxx:.:ooollc:;,'. .'',,;;:c:'.:xo''cllllllllllllllllllllcc:,.cNM
// MMMMMMWo'lxxxx:..,,,'''''. .,cllllll:;''cxxl..;lllllllllllcc:;;,'''''..;OWM
// MMMMMMM0;;dddc..,;;:clll,..;lllllll;. .cddl',;'';::::;,,'''''',,;::c;'lXMMM
// MMMMMMMWo'lo;.,cllllllc'..:cc:;,,;;:;,';o:':kOxl:;'..',,;:cclllllll,'dNMMMM
// MMMMMMMM0,',.;lllllc:;...,::cloxk0KNX0c.''ckOOOOkd,.:llllllllllllc',kWMMMMM
// MMMMMMMMNl..';,,;;:clox00KXNWMMMMMMMMWk..lkkkkkxl''clllllc:;;,,;;:l0WMMMMMM
// MMMMMMMMMKl:lodk0KNWMMMMMMMMMMMMMMMMMMNl':odxdd:..;;;,,;::cldxO0XNWMMMMMMMM
// MMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMNkl:::;;',:lodkOKXWWMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kxk0XWMMMMMMMMMMMMMMMMMMMMMMM69

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";

// import "./console.sol";

contract Condoms is ERC721, Ownable {

  constructor() ERC721("Proof of Love Goodies", "LOVE") {}
  
  uint256 tokenCounter = 0;

  mapping(uint8 => uint256) mintWindows;
  mapping(uint8 => uint256) episodeSerialCounters;
  mapping(uint256 => uint8) episodeNumbers;
  mapping(uint256 => uint256) serialNumbers;
  mapping(uint256 => uint8) sizes;
  mapping(uint256 => bool) golden;

  string mediaBaseUrl = "https://mr-condoms.s3.amazonaws.com/";

  function setMediaBase(string calldata newUrl)
    onlyOwner
    public
  {
    mediaBaseUrl = newUrl;
  }

  function setMintWindow(uint8 newEpisodeNumber, uint256 startTime)
    onlyOwner
    public
  {
    mintWindows[newEpisodeNumber] = startTime;
  }

  function episodeNumber()
    private
    view
    returns(uint8)
  {
    uint8 i;

    for (i = 0; i < 6; i++) {
      if(mintWindows[i] > 0 && mintWindows[i] < block.timestamp + 10 && (mintWindows[i] + (5 * 60)) > block.timestamp + 10) {
        return i;
      }
    }

    return 0;
  }

  function mint()
    public
    returns (uint256)
  {
    uint8 episode = episodeNumber();

    // Must have enough ETH attached
    require(episode > 0, "You cannot mint at this time.");
    
    tokenCounter += 1;

    episodeSerialCounters[episode] += 1;

    episodeNumbers[tokenCounter] = episode;
    serialNumbers[tokenCounter] = episodeSerialCounters[episode];

    golden[tokenCounter] = (uint(keccak256(abi.encodePacked(block.timestamp, tokenCounter, msg.sender))) % 15) + 1 == 10;

    _safeMint(msg.sender, tokenCounter);

    return tokenCounter;
  }

  function mintMultiple(uint8 mintCount)
    public
  {
    require(mintCount <= 20, "You can mint up to 20 at a time.");
    uint i;
    for(i = 0; i < mintCount; i++) {
      mint();
    }
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override
  {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function rollSize(uint256 tokenId) public {
    require(ownerOf(tokenId) == msg.sender, "It must be a condom in your wallet.");
    require(sizes[tokenId] == 0, "You can only roll for size once.");
    uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenCounter, tokenId))) % 5;
    randomNumber = randomNumber + 1;
    sizes[tokenId] = uint8(randomNumber);
  }

  function sizeString(uint8 size) private pure returns (string memory) {
    if(size == 1) {
      return "X-Small";
    } else if(size == 2) {
      return "Small";
    } else if(size == 3) {
      return "Average";
    } else if(size == 4) {
      return "Large";
    } else if(size == 5) {
      return "X-Large";
    }

    return "Legendary";
  }

  function colorString(uint8 episodeId, uint256 tokenId) private view returns (string memory) {
    if(uint256(episodeId) == serialNumbers[tokenId]) {
      return "Rainbow";
    } else if(golden[tokenId]) {
      return "Golden";
    } else {
      return "Silver";
    }
  }

  function tokenURI(uint256 tokenId) override(ERC721) public view returns (string memory) {

    string memory sizeTrait = "";
    string memory episodeId = Strings.toString(episodeNumbers[tokenId]);
    if(sizes[tokenId] > 0) {
      sizeTrait = string(abi.encodePacked('{"trait_type": "Size", "value": "', sizeString(sizes[tokenId]),'"},'));
    }

    string memory jsonText = string(abi.encodePacked(
      '{"name": "Episode ', episodeId,' - #', Strings.toString(serialNumbers[tokenId]), '",',
      '"description": "Episode ', episodeId,' of Proof of Love", ',
      '"external_url": "https://madrealities.xyz", ',
      '"image": "', mediaBaseUrl, colorString(episodeNumbers[tokenId], tokenId), '.gif",',
      '"animation_url": "', mediaBaseUrl, colorString(episodeNumbers[tokenId], tokenId), '.mp4", "attributes": [',
      '{"trait_type": "Serial", "value": ', Strings.toString(serialNumbers[tokenId]),'},',
      '{"trait_type": "Type", "value": "', colorString(episodeNumbers[tokenId], tokenId), '"},',
      sizeTrait,
      '{"trait_type": "Episode", "value": ', episodeId,'}]}'
    ));

    string memory json = Base64.encode(bytes(jsonText));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }
}