// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2; // required to accept structs as function parameters

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./base64.sol";
import "./SportsMetadata.sol";

contract SportsCards is ERC721, ERC721URIStorage, Ownable {
  
  uint32[] private sportsLaunchTimes = [
    1633105800,
    1633710600,
    1634315400,
    1634920200,
    1635525000
  ];

  string ipns;
  string ipnsGateway;

  address metadataAddress;

  uint256[] _mintedTokens;

  mapping(address => uint) credits;

  constructor() 
    ERC721("Sports Cards", "CARD") 
  {}

  function tokenIdsForOwner(address ownerAddress)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(ownerAddress);

    if (tokenCount == 0) {
      // Return an empty array
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCards = _mintedTokens.length;
      uint256 resultIndex = 0;
      uint256 cardIndex;

      for (cardIndex = 0; cardIndex < totalCards; cardIndex++) {
        if (ownerOf(_mintedTokens[cardIndex]) == ownerAddress) {
          result[resultIndex] = _mintedTokens[cardIndex];
          resultIndex++;
        }
      }

      return result;
    }
  }

  function setMetadataAddress(address metadata) public onlyOwner {
    metadataAddress = metadata;
  }

  function setIPNS(string calldata ipnsCID) public onlyOwner {
    ipns = ipnsCID;
  }

  function setIPNSGateway(string calldata gatewayURL) public onlyOwner {
    ipnsGateway = gatewayURL;
  }

  function isGoldCard(uint256 tokenId) public pure returns (bool) {
    return(uint16(tokenId) == 0);
  }

  function isPremierCard(uint256 tokenId) public pure returns (bool) {
    return(uint16(tokenId) == 1);
  }

  function isCommonCard(uint256 tokenId) public pure returns (bool) {
    return(uint16(tokenId) > 1);
  }

  function sequenceNumber(uint256 tokenId) public pure returns (uint256) {
    return(uint256(uint16(tokenId)));
  }

  function cardNumber(uint256 tokenId) public pure returns (uint8) {
    return uint8(tokenId >> 16);
  }

  function sportId(uint256 tokenId) public pure returns(uint8) {
    return uint8(tokenId >> 24);
  }

  function cityId(uint256 tokenId) public pure returns(uint16) {
    return uint16(tokenId >> 32);
  }

  function premierCardTokenIdForCommonCard(uint256 commonCardTokenId)
    public
    pure
    returns(uint256)
  {
    uint256 tokenId = commonCardTokenId >> 16;
    return(tokenId << 16 | 1);
  }

  function premierCardOwner(uint256 commonCardTokenId)
    public
    view
    returns(address)
  {
    return ownerOf(premierCardTokenIdForCommonCard(commonCardTokenId));
  }

  function cardIsRedeemable(uint256 tokenId) public view returns(bool) {

    if(sequenceNumber(tokenId) == 0 && msg.sender != address(owner())) {
      return false;
    }

    if(cardNumber(tokenId) > 100 && msg.sender != address(owner())) {
      return false;
    }

    return true;
  }

  function sportIsRedeemable(uint8 redeemableSportId, uint256 timestamp) public view returns(bool) {

    if(msg.sender == address(owner())) {
      return(true);
    }

    if(redeemableSportId <= 4) {
      return(timestamp >= sportsLaunchTimes[redeemableSportId]);
    } else {
      return(true);
    }
  }

  function mint(uint256 tokenId)
    public
    payable
    returns (uint256)
  {
    // Token has already been minted
    require(!_exists(tokenId), "Token has already been minted.");

    // Card must be redeemable by caller
    require(cardIsRedeemable(tokenId), "You cannot mint that card");

    // Sport must be on sale
    require(sportIsRedeemable(sportId(tokenId), block.timestamp), "Sport not redeemable yet");

    // Must have enough ETH attached to redeem card
    require(msg.value >= costToMint(tokenId, block.timestamp), "Not enough ETH sent.");

    // if it's a common card and the premier card has been redeemed
    if(isCommonCard(tokenId) && _exists(premierCardTokenIdForCommonCard(tokenId))) {
      uint256 commission = (msg.value * 2) / 10;
      allowForPull(ownerOf(premierCardTokenIdForCommonCard(tokenId)), commission);
      allowForPull(address(owner()), msg.value - commission);
    } else {
      allowForPull(address(owner()), msg.value);
    }

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenURI(tokenId));
    _mintedTokens.push(tokenId);

    return tokenId;
  }

  function allowForPull(address receiver, uint amount) private {
    credits[receiver] += amount;
  }

  function withdrawCredits() public {
    uint amount = credits[msg.sender];

    require(amount != 0);
    require(address(this).balance >= amount);

    credits[msg.sender] = 0;

    payable(msg.sender).transfer(amount);
  }

  // Make it possible for admin to recover funds for holders who lose access
  function withdrawCreditsFor(address withdrawFor, address receiver) onlyOwner public {
    uint amount = credits[withdrawFor];

    require(amount != 0);
    require(address(this).balance >= amount);

    credits[withdrawFor] = 0;

    payable(receiver).transfer(amount);
  }

  function costToMint(uint256 tokenId, uint256 timestamp) public view returns(uint256) {
    uint32 sportLaunchTime;

    if(msg.sender == address(owner())) {
      return(0);
    }

    if(isPremierCard(tokenId)) {
      if(sportId(tokenId) <= 4) {
        sportLaunchTime = sportsLaunchTimes[sportId(tokenId)];
      } else {
        sportLaunchTime = 1634920200;
      }
      
      // Price decreases every half hour for three hours
      if(timestamp > sportLaunchTime) {

        // It's been more than three hours so just return 1 ether
        if(timestamp - sportLaunchTime > (60 * 60 * 3)) {
          return(1 ether);
        }

        uint256 timeElapsed = timestamp - sportLaunchTime;
        if(timeElapsed <= 60 * 30) {     // less than thirty minutes
          return(3 ether);
        } else if(timeElapsed <= 60 * 60)  {  // 30 minutes to 1 hour
          return(2.5 ether);
        } else if(timeElapsed <= 60 * 90)  {  // 1 hour to 1.5 hours
          return(2 ether);
        } else if(timeElapsed <= 60 * 120) {  // 1.5 hours to 2 hours
          return(1.5 ether);
        } else {
          return(1 ether);
        }
      } else {
        return(3 ether);
      }
    } else {
      if(sequenceNumber(tokenId) < 100) {
        return((1 ether / 1000) * sequenceNumber(tokenId));
      } else {
        return(1 ether / 10);
      }
    }
  }

  function _leftPadNumber(string memory number) private pure returns (string memory) {
    uint8 i;

    for(i = 0; bytes(number).length <= 5; i++) {
      number = string(abi.encodePacked('0', number));
    }

    return number;
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) override(ERC721, ERC721URIStorage) public view returns (string memory) {

    string[8] memory parts;

    parts[0] = string(abi.encodePacked('{"name": "', SportsMetadata(metadataAddress).cityName(tokenId), ' ', SportsMetadata(metadataAddress).sportName(tokenId),' #', Strings.toString(cardNumber(tokenId)), '",'));
    parts[1] = string(abi.encodePacked('"description": "', SportsMetadata(metadataAddress).cityName(tokenId), ' ', SportsMetadata(metadataAddress).sportName(tokenId),' #', Strings.toString(cardNumber(tokenId)), '\\nSN-', _leftPadNumber(Strings.toString(sequenceNumber(tokenId))), '", '));
    parts[2] = string(abi.encodePacked('"external_url": "https://sportsdao.gg/collectibles/', Strings.toString(tokenId), '", '));
    parts[3] = string(abi.encodePacked('"image": "', ipnsGateway, ipns, '/', Strings.toString(tokenId),'.png", "attributes": ['));
    parts[4] = string(abi.encodePacked('{"trait_type": "City", "value": "', SportsMetadata(metadataAddress).cityName(tokenId), '"},'));
    parts[5] = string(abi.encodePacked('{"trait_type": "Sport", "value": "', SportsMetadata(metadataAddress).sportName(tokenId),'"},'));
    parts[6] = string(abi.encodePacked('{"trait_type": "Number", "display_type": "number", "value": ', Strings.toString(cardNumber(tokenId)),'},'));
    parts[7] = string(abi.encodePacked('{"trait_type": "Serial Number", "display_type": "number", "value": ', Strings.toString(sequenceNumber(tokenId)),'}]}'));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }
}