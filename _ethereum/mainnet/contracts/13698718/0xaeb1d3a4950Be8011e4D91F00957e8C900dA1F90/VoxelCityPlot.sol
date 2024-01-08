// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "Ownable.sol";
import "ERC721Enumerable.sol";

// @author: Voxel City
/*
/  |   /  |                              /  |       /      \ /  |  /  |              
VV |   VV |  ______   __    __   ______  LL |      /CCCCCC  |II/  _TT |_    __    __ 
VV |   VV | /      \ /  \  /  | /      \ LL |      CC |  CC/ /  |/ TT   |  /  |  /  |
VV  \ /VV/ /OOOOOO  |XX  \/XX/ /EEEEEE  |LL |      CC |      II |TOBIAS/   YY |  YY |
 VV  /VV/  OO |  OO | XX  XX<  EE    EE |LL |      CC |   __ II |  TT | __ YY |  YY |
  VV VV/   OO \__OO | /XXXX  \ EEPEAREE/ LL |      CC \__/  |II |  TT |/  |YY \__YY |
   VVV/    OO    OO/ /XX/ XX  |EE       |LL |      CC    CC/ II |  TT  TT/ YY    YY |
    V/      OROOTO/  XX/   XX/  EEIKKEE/ LL/        CCCCCC/  II/    TTTT/   YYYYYYY |
                                                                           /  \__YY |
                                                                           YY    YY/ 
                                                                            YYYYYY/  
*/

contract VoxelCityPlots is ERC721Enumerable, Ownable {

  ////////////////////////////////////////////////////////////////////////
  //                             VARIABLES                              //
  ////////////////////////////////////////////////////////////////////////
  address private owner_;
  address private cityBank_;
  string public townSquareURI;

  struct Sale {
    string baseURI;
    uint256 tokenSupply;
    uint256 numTokens;
    uint256 id;
    uint256 state; 
    uint256 startWL;
    uint256 endWL;
    uint256 standardPrice;
    uint256 whitelistPrice;
    bytes32 merkleRoot;
  }

  mapping(uint256 => Sale) public saleIdToSale;
  uint256 public  numberOfSales;
  mapping(address => uint256) public mintPerWhitelist;

  mapping(uint256 => uint256) public tokenIdToSale;

  uint256 public activeSaleId;

  ////////////////////////////////////////////////////////////////////////
  //                               EVENTS                               //
  ////////////////////////////////////////////////////////////////////////
  event WhitelistMintEvent(uint numberMinted);
  event MintEvent(uint numberMinted);


  ////////////////////////////////////////////////////////////////////////
  //                          WRITE functions                           //
  ////////////////////////////////////////////////////////////////////////
  
  constructor(address _cityBank, string memory _townSquareURI) ERC721("Voxel City Plots", "VCP") {
      cityBank_ = _cityBank;
      townSquareURI = _townSquareURI;
      numberOfSales = 0;
      _safeMint(msg.sender, 0);
  }

  function setTownSquareURI(string memory _newURI) public onlyOwner {
      townSquareURI = _newURI;
  }

  function setCityBank(address _newBank) public onlyOwner {
      cityBank_ = _newBank;
  }

  // create new sale 
  function CreateSale(string memory _baseURI, uint256 _tokenSupply, bytes32 _merkleRoot, uint256 _maxPerWhitelist, uint256 _startWL, uint256 _standardPrice, uint256 _whitelistPrice) public onlyOwner{
    require(_tokenSupply>0,"Token supply must be a positive integer");
    Sale memory sale;
    // get number of sales 
    uint256 saleId = numberOfSales;
    sale.baseURI = _baseURI;
    sale.tokenSupply = _tokenSupply;
    sale.state = 0;
    sale.id = saleId;
    sale.merkleRoot = _merkleRoot;
    sale.endWL = _startWL+_maxPerWhitelist;
    sale.startWL = _startWL;
    sale.standardPrice = _standardPrice;
    sale.whitelistPrice = _whitelistPrice;
    sale.startWL = _startWL;
    saleIdToSale[saleId] = sale;
    numberOfSales = numberOfSales + 1;
  }

  function StartPresale(uint256 _saleId) public onlyOwner{
     require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
     require(saleIdToSale[_saleId].state != 2, "Sale is already in active");
     require(saleIdToSale[_saleId].state != 3, "Its already sold out");
     saleIdToSale[_saleId].state = 1;
  }

  function StartSale(uint256 _saleId) public onlyOwner{
     require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
     require(saleIdToSale[_saleId].state != 3 , "Its already sold out");
     saleIdToSale[_saleId].state = 2;
  }

  function EndSale(uint256 _saleId) public onlyOwner{
     require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
     require(saleIdToSale[_saleId].state != 3 , "Its already sold out");
     saleIdToSale[_saleId].state = 3;
  }

  function MintPlot( uint256 _saleId, uint256 _numberOfTokens) public payable {
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      require(saleIdToSale[_saleId].state == 2, "Sale is not active!");
      require(_numberOfTokens > 0, "Can't mint a non-positive number of tokens!");
      require(getNumLeft(_saleId) > 0, "No plots left to mint!");
      require(msg.value == (saleIdToSale[_saleId].standardPrice * (_numberOfTokens)), "Ether value sent is not correct");
      for(uint256 i = 0; i < _numberOfTokens; i++) {
          if (saleIdToSale[_saleId].numTokens < saleIdToSale[_saleId].tokenSupply) {
              uint256 tokenId = totalSupply();
              uint256 saleTokenId = saleIdToSale[_saleId].numTokens;
              _safeMint(msg.sender, tokenId);
              saleIdToSale[_saleId].numTokens = saleIdToSale[_saleId].numTokens + 1;
              tokenIdToSale[tokenId] =  _saleId<<64 | saleTokenId;
          } else {
              payable(cityBank_).transfer((i) * saleIdToSale[_saleId].standardPrice);
              payable(msg.sender).transfer((_numberOfTokens-i) * saleIdToSale[_saleId].standardPrice);
              emit MintEvent(i);
              return;
          }
      }
      payable(cityBank_).transfer(msg.value);
      emit MintEvent(_numberOfTokens);
  }

  function MintWhitelisted( uint256 _saleId, uint256 _numberOfTokens, bytes32[] calldata merkleProof,uint256 index) public payable {
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      require(saleIdToSale[_saleId].state == 1, "Presale is not active");
      require(_numberOfTokens > 0, "Can't mint a non-positive number of tokens");
      require(getNumLeft(_saleId) > 0, "No plots left to mint!");
      require(msg.value == (saleIdToSale[_saleId].whitelistPrice * (_numberOfTokens)), "Ether value sent is not correct");

      require(verify(merkleProof, saleIdToSale[_saleId].merkleRoot,  keccak256(abi.encodePacked(msg.sender)), index), "Invalid proof");

      uint256 startWL =saleIdToSale[_saleId].startWL; 

      if(mintPerWhitelist[msg.sender] > startWL){
        startWL = mintPerWhitelist[msg.sender];
      }
      require(startWL + _numberOfTokens <=saleIdToSale[_saleId].endWL, "The number of whitelisted mints is limited per wallet");

      for(uint256 i = 0; i < _numberOfTokens; i++) {
          if (saleIdToSale[_saleId].numTokens < saleIdToSale[_saleId].tokenSupply) {
              uint256 tokenId = totalSupply();
              uint256 saleTokenId = saleIdToSale[_saleId].numTokens;
              _safeMint(msg.sender, tokenId);
              saleIdToSale[_saleId].numTokens = saleIdToSale[_saleId].numTokens + 1;
              tokenIdToSale[tokenId] =  _saleId<<64 | saleTokenId;
          } else {
              payable(cityBank_).transfer(i * saleIdToSale[_saleId].whitelistPrice);
              payable(msg.sender).transfer((_numberOfTokens-i) * saleIdToSale[_saleId].whitelistPrice);
              emit WhitelistMintEvent(i);
              return;
          }
      }
      mintPerWhitelist[msg.sender] = startWL + _numberOfTokens;
      payable(cityBank_).transfer(msg.value);
      emit WhitelistMintEvent(_numberOfTokens);
  }

  function setSaleURI(uint256 _saleId, string memory _newURI) public onlyOwner {
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      saleIdToSale[_saleId].baseURI = _newURI;
  }


  ////////////////////////////////////////////////////////////////////////
  //                           READ functions                           //
  ////////////////////////////////////////////////////////////////////////

  function getNumLeft(uint256 _saleId) public view returns (uint256){
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      return saleIdToSale[_saleId].tokenSupply - saleIdToSale[_saleId].numTokens;
  }

  function getPrice(uint256 _saleId, uint256 _count) public view returns (uint256) {
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      return saleIdToSale[_saleId].standardPrice * _count;
  }

  function getWhitelistedPrice(uint256 _saleId, uint256 _count) public view returns (uint256) {
      require(saleIdToSale[_saleId].tokenSupply != 0, "Sale Id does not exist");
      return saleIdToSale[_saleId].whitelistPrice * _count; 
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
      if(tokenId == 0) return townSquareURI;
      uint256 saleId  = tokenIdToSale[tokenId]>>64;
      uint256 saleTokenId = tokenIdToSale[tokenId]&((1<<64)-1);
      Sale memory sale = saleIdToSale[saleId];
      return (bytes(sale.baseURI).length > 0 )? string(abi.encodePacked(sale.baseURI, uint2str(saleTokenId))) : "";
  }

  function uint2str(uint _i) public pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }

  function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint index) internal pure returns (bool) {
      bytes32 hash = leaf;

      for (uint i = 0; i < proof.length; i++) {
          bytes32 proofElement = proof[i];

          if (index % 2 == 0) {
              hash = keccak256(abi.encodePacked(hash, proofElement));
          } else {
              hash = keccak256(abi.encodePacked(proofElement, hash));
          }

          index = index / 2;
      }

      return hash == root;
  }
  function hashVal(string memory val) public pure returns(bytes32){
      return keccak256(abi.encodePacked(val));
  }

}
