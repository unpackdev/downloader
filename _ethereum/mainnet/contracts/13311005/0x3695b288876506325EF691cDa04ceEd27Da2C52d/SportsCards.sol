// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract SportsCards is ERC721, ERC721URIStorage, Ownable {

  uint32[] private sportsLaunchTimes = [
    1632501000,
    1633105800,
    1633710600,
    1634315400,
    1634920200
  ];

  uint256[] _mintedTokens;

  mapping(uint256 => string) private metadata;
  mapping(address => uint) credits;

  constructor() ERC721("Sports Cards", "CARD") {}

  function setMetadata(uint256 tokenId, string memory tokenURIKey)
    public
    onlyOwner
  {
    metadata[tokenId] = tokenURIKey;
  }
  
  function getMetadata(uint256 tokenId)
    public
    view
    returns(string memory)
  {
    return(metadata[tokenId]);
  }

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

  function isPremierCard(uint256 tokenId) public pure returns (bool) {
    return(uint16(tokenId) == 1);
  }

  function isCommonCard(uint256 tokenId) public pure returns (bool) {
    return(uint16(tokenId) != 1);
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

  function sportIsRedeemable(uint8 reddemableSportId, uint256 timestamp) public view returns(bool) {

    if(msg.sender == address(owner())) {
      return(true);
    }

    if(reddemableSportId <= 4) {
      return(timestamp >= sportsLaunchTimes[reddemableSportId]);
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

    // Sport must be on sale
    require(sportIsRedeemable(sportId(tokenId), block.timestamp), "Sport not redeemable yet");

    // Onwer has to have provided metadata for tokenId
    require(bytes(metadata[tokenId]).length > 0, "Metadata doesn't exist for token ID.");

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
    _setTokenURI(tokenId, metadata[tokenId]);
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
      return((1 ether / 1000) * sequenceNumber(tokenId));
    }
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }
}