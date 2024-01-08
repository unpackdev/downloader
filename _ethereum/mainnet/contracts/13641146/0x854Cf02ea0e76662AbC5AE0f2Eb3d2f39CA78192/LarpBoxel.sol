//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721URIStorage.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract LarpBoxel is ERC721URIStorage, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  Counters.Counter private _tokenIds;
  string[] private _uris;
  IERC721 private _ethbot;
  IERC721 private _moloch;
  //active status
  bool private _deactivated = false;
  //prices
  uint256 private adminPrice = 0 ether;
  uint256 private ownerPrice = 0.025 ether;
  uint256 private regularPrice = 0.069 ether;

  constructor(string memory name, string memory symbol, address ethbotAddress, address molochAddress) ERC721(name, symbol) 
  {
    _ethbot = IERC721(ethbotAddress);
    _moloch = IERC721(molochAddress);
    _uris = [
      "1Defeat.json",
      "2GMfromtheQuadraticLands.json",
      "3DownfortheCount.json",
      "4Whiplash.json",
      "5Kneecapped!.json",
      "6AnonattheHelm.json",
      "7CallintheCavalry.json",
      "8Alert!.json",
      "9MolochianLurkers.json",
      "10QuadraticCity.json"
    ];
  }

  //uri functions
  function _baseURI() internal pure override returns (string memory) {
    return "https://gateway.pinata.cloud/ipfs/QmeyuWemePzx99f1adjRWAMN77jhs7QvEf6XAGmytUkait/";
  }

  function contractURI() public pure returns (string memory) {
    return "https://gateway.pinata.cloud/ipfs/QmeyuWemePzx99f1adjRWAMN77jhs7QvEf6XAGmytUkait/contract.json";
  }

  function baseURI() public pure returns (string memory) {
    return _baseURI();
  }

  function randomUri() private view returns (string memory) {
    uint randomHash = uint(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp, _tokenIds.current())));
    return _uris[randomHash % _uris.length];
  } 

  //price: 0 for owner (test only), 0.05 eth for Gitcoin owners, 0.1 eth for everyone else
  function calculatePrice(address minter) private view returns (uint256) {
    if(minter == owner()) {
      return adminPrice;
    }
    else if(_ethbot.balanceOf(minter) > 0 || _moloch.balanceOf(minter) > 0) {
      return ownerPrice;
    }
    else {
      return regularPrice;
    }
  }
  
  function getPrice() public view returns (uint256) {
    return calculatePrice(msg.sender);
  }

  //@dev mint token for user
  function mintToken() public payable returns(uint256) {
    require(_deactivated == false, "Token sale is deactivated");
    uint256 price = calculatePrice(msg.sender);
    require(msg.value >= price, "Insufficient ETH sent");

    //get token id
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();

    //get uri
    string memory uri = randomUri();

    //mint and set uri
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, uri);

    return tokenId;
  }

  //@dev mint multiple tokens for user
  function mintMultipleTokens(uint numberOfTokens) public payable {
    require(numberOfTokens <= 10, "You can only mint 10 tokens at a time");
    require(_deactivated == false, "Token sale is deactivated");
    uint256 price = calculatePrice(msg.sender).mul(numberOfTokens);
    require(msg.value >= price, "Insufficient ETH sent");

    for(uint index = 0; index < numberOfTokens; index++) {
      mintToken();
    }
  }
  
  /**
    Admin functions
   */
  function deactivate(bool status) public onlyOwner {
    _deactivated = status;
  }

  function isDeactivated() public view returns(bool) {
    return _deactivated;
  }

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
