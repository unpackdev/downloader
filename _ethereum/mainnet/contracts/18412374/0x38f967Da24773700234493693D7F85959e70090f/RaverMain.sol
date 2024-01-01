// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
 
contract NFT is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _itemIds;
  Counters.Counter private _itemSold;
  Counters.Counter private _refferalNumber;
  Counters.Counter private _specialSeriesId;
  Counters.Counter public _nextFreeToken;



  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 30000000 gwei;
  uint256 public maxSupply = 1800;
  uint256 public maxMintAmount = 1800;
  bool public paused = false;
  address _contractOwner;
  // uint256 public specialSeriesStart = 3000;
  mapping(address => bool) public whitelisted;
  mapping(address => bool) public refferals;

  mapping(address => bool) public freeTokenHolders;
  mapping(address => bool) public zeroTwoTokenHolders;
  mapping(address => bool) public twoFiveTokenHolders;

    constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    refferals[0x0BC2dF33054e461D8A2Ba4c84ACa624c88fBbFfb] = true;
    _contractOwner = msg.sender;
    _itemIds.increment();
  }

      struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) public idToMarketItem;

  // internal
  //https://bafybeigbamnof2fol2ao6k2parzs7yevmcrgiw7b257hmyjqanomfrbx7e.ipfs.w3s.link/
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  // public
  function mint(address _to, uint256 _Ids, address refferal) public payable  {

    require(_Ids == 1 ||_Ids == 5 ||_Ids == 15, "Wrong numbers");
    uint256 price = 0;
    uint256 devPart = 0;
    uint256 refferalPart = 0;

        if(_Ids == 5){
      price = 24000000 gwei;
      devPart = 360000 gwei;
      refferalPart = 10000000 gwei;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return; 
    }

            if(_Ids == 15){
      price = 22000000 gwei;
      devPart = 330000 gwei;
      refferalPart = 10000000 gwei;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return; 
    }

///// free tokens

    if(freeTokenHolders[_to] == true){
      price = 0;
      devPart = 0;
      refferalPart = 0;
      freeTokenHolders[_to] = false;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return; 
    }

//////// 0.02 zone

    if(zeroTwoTokenHolders[_to] == true){
      price = 20000000 gwei;
      devPart = 300000 gwei;
      refferalPart = 10000000 gwei;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return; 
    }

//////// 0.025 zone
    if(twoFiveTokenHolders[_to] == true){
      price = 25000000 gwei;
      devPart = 375000 gwei;
      refferalPart = 10000000 gwei;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return; 
    } else {
      price = 30000000 gwei;
      devPart = 450000 gwei;
      refferalPart = 10000000 gwei;
      deepMint(_to, _Ids, refferal, price, devPart, refferalPart);
      return;
    }
   
  }


  function setTierOneHolders(address[] memory arr) public {
    require(msg.sender == _contractOwner ||msg.sender == 0xcb4cF0D59914ac00336A39754d3214f9F14F7623, "You cant");
    for (uint256 i =0; i < arr.length; i++) 
    {
      freeTokenHolders[arr[i]] = true;
    }
  }

    function setTierTwoHolders(address[] memory arr) public {
    require(msg.sender == _contractOwner ||msg.sender == 0xcb4cF0D59914ac00336A39754d3214f9F14F7623, "You cant");
    for (uint256 i =0; i < arr.length; i++) 
    {
      zeroTwoTokenHolders[arr[i]] = true;
    }
  }

    function setTierThreeTokenHolders(address[] memory arr) public {
    require(msg.sender == _contractOwner ||msg.sender == 0xcb4cF0D59914ac00336A39754d3214f9F14F7623, "You cant");
    for (uint256 i =0; i < arr.length; i++) 
    {
      twoFiveTokenHolders[arr[i]] = true;
    }
  }



  function deepMint(address _to, uint256 _Ids, address refferal, uint256 price, uint256 devPart, uint256 refferalPart) private {
    uint256 mainPrice = price;
    uint256 zathenaPart = devPart;
    uint256 refPart = refferalPart;

    uint256 current = _itemIds.current();
    require(current <= maxMintAmount, "minting is finished");
    require(msg.value >= mainPrice * _Ids, "Not enought $$");
          
      if(_itemIds.current() < 1000){
    refferals[msg.sender] = true;
    _refferalNumber.increment();
    } 

    for (uint256 i = 1; i <= _Ids; i++) {
      
      _safeMint(_to, _itemIds.current());
      
            if(refferals[refferal] = true){
        payable(refferal).transfer(refferalPart); // change to actual fee
      }

      if(mainPrice != 0){
        payable(0xcb4cF0D59914ac00336A39754d3214f9F14F7623).transfer(zathenaPart);
      payable(0x77f70fc5e4a77d0e29E8bD611Da40a9C898488e1).transfer(zathenaPart);

      payable(0x0BC2dF33054e461D8A2Ba4c84ACa624c88fBbFfb).transfer(mainPrice -zathenaPart - zathenaPart - refPart);
      }

            idToMarketItem[ _itemIds.current()] = MarketItem(
             _itemIds.current(),
            address(this),
            _itemIds.current(),
            payable(msg.sender),
            payable(msg.sender),
            cost,
            false
        ); 
        _itemIds.increment(); 
    }
  }



  function buyNFT(uint256 tokenID) public payable {
    require(idToMarketItem[tokenID].price > 0, "NFTMarket: nft not listed for sale");
    require(msg.value >= idToMarketItem[tokenID].price, "NFTMarket: wrong price");
    require(idToMarketItem[tokenID].sold == false, "NFTMarket: nft already sold");

    uint commissionNumerator = 15;
    uint commissionDenominator = 1000;

    uint256 devPart = (idToMarketItem[tokenID].price*commissionNumerator)/commissionDenominator;

    ERC721(address(this)).transferFrom(idToMarketItem[tokenID].seller, msg.sender, tokenID);
    idToMarketItem[tokenID].sold = true;
    idToMarketItem[tokenID].owner = msg.sender;
    idToMarketItem[tokenID].seller = msg.sender;
    payable(0xcb4cF0D59914ac00336A39754d3214f9F14F7623).transfer(devPart);
    payable(0x77f70fc5e4a77d0e29E8bD611Da40a9C898488e1).transfer(devPart);
    payable(0x0BC2dF33054e461D8A2Ba4c84ACa624c88fBbFfb).transfer(idToMarketItem[tokenID].price - devPart - devPart);
  }

  function listNFT(uint256 tokenID, uint256 price) public {
    require(price > 0, "NFTMarket: price must be more than 0");
    require(idToMarketItem[tokenID].owner == msg.sender, "NFTMarket: st be this contract");

    idToMarketItem[tokenID].price = price;
    idToMarketItem[tokenID].sold = false;
    idToMarketItem[tokenID].seller = msg.sender;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }



  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function getBalance() public view returns(uint) {
    return address(this).balance;
  }

  function withdraw() public payable onlyOwner {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }
}