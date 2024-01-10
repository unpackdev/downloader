// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";

import "./Base64.sol";




contract NFTContract is ERC721, ERC721URIStorage, ERC721Enumerable, Ownable {
  using Counters for Counters.Counter;

  string private recipientID;
  uint256 public saleSize;

  uint256 public mintLimit;

  uint256 public mintingFees; 

  string private _baseTokenURI;
  bool public isWhiteListSaleActive  = false;

  bool public isPublicSaleActive = false;
  mapping(address => bool) public whiteList; 
  bool public paused;

  event NFTMintedEvent(address _from, uint tokenId);
  Counters.Counter private _tokenIds;

  modifier saleModifier {
    require(!paused,"paused");
    require(msg.value >= mintingFees, "check the fees");
    require(getBalanceOf() <=mintLimit, "cannot mint more");
    _;
  }



  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
  function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        super._burn(tokenId);
    }

  function baseTokenURI() view public returns (string memory) {
        return _baseTokenURI;
    }

  function tokenURI(uint256 _tokenId) override(ERC721URIStorage, ERC721) view public returns (string memory) {
        return super.tokenURI(_tokenId);
  }

  function totalSupply() override(ERC721Enumerable) public view returns (uint256) {
      return _tokenIds.current();
    }

  constructor(string memory _recipientID, uint256 _saleSize, uint256 _mintingLimit,uint256 _mintingFees, string memory _BaseTokenURI )
        ERC721("BADMANSKULLGANG", "BMSG")
    {
      recipientID = _recipientID;
      saleSize = _saleSize;
      mintLimit = _mintingLimit;
      mintingFees = _mintingFees;
      _baseTokenURI = _BaseTokenURI;
      paused = false;
    }

  function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



  function contractURI() public view returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                      '{"name": "BADMANSKULLGANG",', 
                      '"description": "A collection of 3,333 unique NFTs with over 100 unique features and characteristics bullying the Ethereum blockchain. The BADMANSKULLGANG has been indicted on unknown charges and the gang is awaiting trial in an Ethereum blockchain jail. Gang members are known to stay dangerous and are notorious #BlockchainBullies. The BADMANSKULLGANG has 3,333 known members. Free the entire gang and help them escape to the metaverse where they can live free. #FreeTheGang",', 
                      '"image": "",', 
                      '"external_link": "https://badmanskullgang.com",', 
                      ' "seller_fee_basis_points": 1000,',
                      ' "fee_recipient": "',
                        recipientID ,
                      '"',
                      '}'
                )
            )
        )
    )));
    }
    
  function getBalanceOf() public view returns (uint256) {
    return balanceOf(address(msg.sender));
  }

  function tokenOfMsgSenderByIndex(uint index) public view returns (uint256) {
    return tokenOfOwnerByIndex(address(msg.sender), index);
  }

  function isWhiteListed() public view returns (bool) {
    return whiteList[address(msg.sender)];
  }

  function setIsWhiteListSaleActive(bool _isWhiteListSaleActive) public onlyOwner {
    isWhiteListSaleActive = _isWhiteListSaleActive;
  }


  function setIsPublicSaleActive(bool _setIsPublicSaleActive) public onlyOwner {
    isPublicSaleActive = _setIsPublicSaleActive;
  }


  function setWhiteLists(address[] memory _whitelists) public onlyOwner {
    for(uint i =0;i<_whitelists.length;i++) {
      whiteList[_whitelists[i]] = true;
    }
  }

  function setPaused(bool _paused) public onlyOwner{
        paused = _paused;
  }

  function setBaseTokenURI(string memory _setBaseTokenURI) public onlyOwner {
    _baseTokenURI = _setBaseTokenURI;
  }

  function setMaxMintSize(uint256 _mintSize) public onlyOwner {
    mintLimit = _mintSize;
  }

  function setMintFees(uint256 _mintingFees) public onlyOwner {
    mintingFees = _mintingFees;
  } 

  function setSaleSize(uint256 _saleSize) public onlyOwner {
    saleSize =_saleSize;
  }

  function whiteListSale() public payable {
      require(isWhiteListSaleActive, "Whitelist sale off");
      require(isWhiteListed(), "not whitelisted");

      _mintToken();

  }

  function publicSale() public payable {
      require(isPublicSaleActive, "public sale off");

      _mintToken();

  }
function ownerMint() public onlyOwner {
    _mint();
  }

  function _mintToken() private saleModifier {    
    _mint();
  }

  function _mint() private {
    uint256 newItemId = _tokenIds.current();
    
  require(newItemId<=saleSize, "all NFT sold out");
    string memory finalTokenUri = string(
        abi.encodePacked(baseTokenURI(),Strings.toString(newItemId),".json") 
    );
    _safeMint(msg.sender, newItemId);
    _setTokenURI(newItemId, finalTokenUri);
    emit NFTMintedEvent(msg.sender, newItemId);
    _tokenIds.increment();
  }

  function withdrawAllMoney(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }

}