// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721F.sol";
import "./SafeMath.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract CryptoBalloonerz is ERC721F, RoyaltiesV2Impl {
  using SafeMath for uint256;

  uint256 public tokenPrice = 0.03141 ether;
  uint256 public constant MAX_TOKENS = 3141;
  uint8 public constant MAX_RESERVE = 2;
  uint8 public constant MAX_RESERVE_FOR_OWNERS = 10;
  bool public saleIsActive = false;
  bool public preSaleIsActive = true;

  address private constant ONE = 0x4daf9FC427E7b1F38Ac447F291a474F44a4EA6c5;
  address private constant TWO = 0x2FadbE50e4499B546561c64E50799B378a46e073;
  address private constant THREE = 0xBDA48AEfA318FEf6599e5890D24356b22b0d753E;
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  mapping(address => uint8) private whitelist;
  
  event priceChange(address _by, uint256 price);
  
  constructor() ERC721F ("CryptoBalloonerz", "CBLZ") {
    setBaseUriToArweaveNet();
  }
  /**
  * If the owner wants to set another URI, then call setBaseTokenURI.
  */

  /**
  * Setter function: to Arweave base URI.
  */
  function setBaseUriToAr() public onlyOwner {
    setBaseTokenURI("ar://mgiiWMkGsmQcXtocwyR-TSyihyeuMxFwU66FPI6Gl-M/");
  }

  /**
  * Setter function: to ArweaveNet base URI.
  */
  function setBaseUriToArweaveNet() public onlyOwner {
    setBaseTokenURI("https://www.arweave.net/mgiiWMkGsmQcXtocwyR-TSyihyeuMxFwU66FPI6Gl-M/");
  }

  /**
  * Mint Tokens to a wallet.
  */
  function mintTokensToWallet(address to,uint numberOfTokens) public onlyOwner {    
    uint supply = totalSupply();
    require(supply.add(numberOfTokens) <= MAX_TOKENS, "Reserve would exceed max supply of Tokens");
    require(numberOfTokens <= MAX_RESERVE_FOR_OWNERS, "Can only mint 10 tokens at a time");
    for (uint i = 0; i < numberOfTokens; i++) {
      _safeMint(to, supply + i);
    }
  }

  /**
  * Mint Tokens to the owners reserve.
  */   
  function reserveTokens() external onlyOwner {    
    mintTokensToWallet(ONE, MAX_RESERVE_FOR_OWNERS);
    mintTokensToWallet(TWO, MAX_RESERVE_FOR_OWNERS);
    mintTokensToWallet(THREE, MAX_RESERVE_FOR_OWNERS);
  }

  /**
  * Pause sale if active, make active if paused
  */
  function flipSaleState() external onlyOwner {
    saleIsActive = !saleIsActive;
    if(saleIsActive){
      preSaleIsActive=false;
    }
  }

  /**
  * Pause sale if active, make active if paused
  */
  function flipPreSaleState() external onlyOwner {
    preSaleIsActive = !preSaleIsActive;
  }

  /**     
  * Set price 
  */
  function setPrice(uint256 price) external onlyOwner {
    tokenPrice = price;
    emit priceChange(msg.sender, tokenPrice);
  }

  /**
  * add an address to the WL
  */
  function addWL(address _address) public onlyOwner {
    whitelist[_address] = MAX_RESERVE;
  }

  /**
  * add an array of address to the WL
  */
  function addAdresses(address[] memory _address) external onlyOwner {
    for (uint i=0; i < _address.length; i++) {
      addWL(_address[i]);
    }
  }

  /**
  * remove an address from the WL
  */
  function removeWL(address _address) external onlyOwner {
    delete whitelist[_address];
  }

  /**
  * returns true if the wallet is Whitelisted.
  */
  function isWhitelisted(address _address) public view returns(bool) {
    return whitelist[_address] != 0;
  }

  /**
  * returns the number of free mints.
  */
  function numOfFreeMints(address _address) public view returns(uint8) {
    return whitelist[_address];
  }

  /**
  * minting function, based on minting amount
  */
  function mint(uint8 numberOfTokens) external payable{
    bool whiteListed = isWhitelisted(msg.sender);
    if(preSaleIsActive){
      require(whiteListed,"Sender is NOT Whitelisted.");
    }else{
      require(saleIsActive,"Sale NOT active yet");
    }
    
    require(numberOfTokens <= MAX_RESERVE, "Can only mint 2 tokens at a time");
    uint256 supply = totalSupply();
    require(supply.add(numberOfTokens) <= MAX_TOKENS, "Purchase would exceed max supply of Tokens");
    
    if (whiteListed){
      uint8 remainedFreeTokens = numOfFreeMints(msg.sender);
      require(numberOfTokens <= remainedFreeTokens, "Number of free mints not greater or equal to the requested amount");
      whitelist[msg.sender] -= numberOfTokens;
    } else {
      require(tokenPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
    }

    for(uint256 i; i < numberOfTokens; i++){
      _safeMint( msg.sender, supply + i );
    }
  }
  
  /**
  * withdrawal function based on percentages
  */
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    require(balance != 0, "Insufficent balance");
    _withdraw(ONE, (balance.mul(40)).div(100));
    _withdraw(TWO, (balance.mul(40)).div(100));
    _withdraw(THREE, (balance.mul(20)).div(100));
  }

  /**
  * private withdrawal function
  */  
  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Failed to widthdraw Ether");
  }

  /**
  * contract can recieve ether
  */    
  fallback() external payable { }
  receive() external payable { }

  /**
  * Configure royalties for Rariable
  */
  function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
    LibPart.Part[] memory _royalties = new LibPart.Part[](1);
    _royalties[0].value = _percentageBasisPoints;
    _royalties[0].account = _royaltiesRecipientAddress;
    _saveRoyalties(_tokenId, _royalties);
  }

  /**
  * Configure royalties for Mintable using the ERC2981 standard
  */
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    //use the same royalties that were saved for Rariable
    LibPart.Part[] memory _royalties = royalties[_tokenId];
    if(_royalties.length != 0) {
      return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
    }
    return (address(0), 0);
  }

  /**
  * Check interface
  */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
      return true;
    }
    if(interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }
}