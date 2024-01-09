// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract TheRebirth is ERC721Enumerable, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedURI;
  string public redeemedURI; 
  uint256 public cost = 0.2 ether;
  uint256 public immutable numberOfSeries = 8; // number of "spirits" or sub-series in the collection
  uint256 public immutable maxSupply = 4000; // collection max supply
  uint256 private immutable seriesLimit = 500; // maximum 500 NFT per "spirit" or sub-series
  uint256 public privateSaleAllocation = 111; // number of full sets allocated for the private sale
  uint256 public privateSaleCounter; // tracks the number of full sets minted during the private sale
  uint256 private immutable seriesPerAddressLimit = 2; // number of NFTs from a "spirit" or sub-series that can be minted by a single address
  uint256 private mintPerAddressLimit = 16; // max number of NFTs a single address can mint
  bool public paused; // indicates whether the contract has been paused
  bool public revealed; // indicates whether the collection has been revealed
  bool private reserveMinted; // counts the number of sets that has been minted during the private sale period
  bool public onlyWhitelisted = true; // indicates whether the private sale period is in effect

  mapping(uint256 => uint256) public seriesCounter; // trakcs the number of tokens minted for a particular "spirit" or sub-series
  mapping(uint256 => uint256) public seriesTokenId; // increments the tokenId for each "spirit" or sub-series as they are minted
  mapping(address => uint256) public addressMintedBalance; // tracks the number of NFTs minted by a given address
  mapping(address => uint256[8]) public seriesPerAddressCounter; // this tracks the number of NFTs minted by "spirit" or sub-series for each address
  mapping(address => bool) public whitelistedAddresses; // tracks whether a given address is allowed to bundlemint during the private sale
  mapping(uint256 => bool) public redeemedTokens; // tracks whether a particular NFT of tokenId has been redeemed

  constructor(
    string memory _name, 
    string memory _symbol, 
    string memory _initBaseURI, 
    string memory _initNotRevealedURI,
    string memory _initRedeemedURI 
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedURI);
    _setRedeemedURI(_initRedeemedURI);
    
    seriesTokenId[1] = 1;
    seriesTokenId[2] = 501;
    seriesTokenId[3] = 1001;
    seriesTokenId[4] = 1501;
    seriesTokenId[5] = 2001;
    seriesTokenId[6] = 2501;
    seriesTokenId[7] = 3001;
    seriesTokenId[8] = 3501;
  }

/****** public *******/

  // single mint
  function mint(uint256 _seriesType) public payable nonReentrant{
    require(!paused, "the contract is paused");
    require(_seriesType > 0 && _seriesType <= numberOfSeries, "incorrect series identifier, value should be an integer between 1 and 8 ");
    require(seriesCounter[_seriesType] < seriesLimit, "this series type has been sold out");

    uint256 supply = totalSupply();
    require(supply < maxSupply, "max NFT limit exceeded"); // total supply must not exceed 4000

    if (msg.sender != owner()) {
        require(onlyWhitelisted == false, "the public sale is not currently active");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender]; 
        require(ownerMintedCount < mintPerAddressLimit, "max NFT per address exceeded");
        require(seriesPerAddressCounter[msg.sender][_seriesType-1] < seriesPerAddressLimit , "this address has minted the maximum allowable number of tokens for this series");  
        require(msg.value >= cost, "insufficient funds");
        if ( msg.value > cost ){
          address payable refund = payable(msg.sender);
          refund.transfer(msg.value - cost);
        }
    }

    // mint single NFT of sub-series type _seriesType
    uint256 tokenId = seriesTokenId[_seriesType]; // tokenId to be assigned to the NFT being safe minted
    seriesTokenId[_seriesType]++; // sub-series tokenId is incremented
    seriesCounter[_seriesType]++; // sub-series mint count is incremented 
    seriesPerAddressCounter[msg.sender][_seriesType-1]++; // number of NFTs in the sub-series minted by the msg.sender is incremented
    addressMintedBalance[msg.sender]++; // number of NFTs minted by the msg.sender is incremente
    _safeMint(msg.sender, tokenId); 
  }

  // bundle mint 
  function bundleMint() public payable nonReentrant{
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(supply + numberOfSeries <= maxSupply, "max NFT limit exceeded");

    for (uint256 i = 1; i <= numberOfSeries; i++){
        // prohibit batch mint if any of the sub-series has been sold out
        require(seriesCounter[i] < seriesLimit, "one or more series sold out, bundle mint no longer available");
        
        if (msg.sender != owner()) {
          // prohibit batch mint if address holds the maximum allowable number of tokens for any given sub-series
          require(seriesPerAddressCounter[msg.sender][i-1] < seriesPerAddressLimit , "this address has minted the maximum allowable number of tokens for a given series");
        }
    }
    
    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted, or max minting allowance for private sale exceeded");
            require(privateSaleCounter < privateSaleAllocation, "private sale allocation has been sold out");
        }
        // check whitelist logic
        uint256 ownerMintedCount = addressMintedBalance[msg.sender]; 
        require(ownerMintedCount + numberOfSeries <= mintPerAddressLimit, "max NFT per address exceeded, consider minting single NFT"); 
        require(msg.value >= (cost * numberOfSeries), "insufficient funds");
        if ( msg.value > (cost * numberOfSeries)){
          address payable refund = payable(msg.sender);
          refund.transfer(msg.value - (cost * numberOfSeries));
        }
    }

    // update all counters prior to safe minting NFTs
    addressMintedBalance[msg.sender] += numberOfSeries;
    uint256[8] memory tokenId;
    for (uint256 i = 1; i <= numberOfSeries; i++) {
      tokenId[i-1] = seriesTokenId[i]; // tokenId for each "spirit" or sub-series is stored in tokenId array
      seriesTokenId[i]++; // the tokenId of each "spirit" or sub-series is incremented
      seriesCounter[i]++; // the mint count of each "spirit" or sub-series is incremented
      seriesPerAddressCounter[msg.sender][i-1]++; // the mint count of each "spirit" or sub-series for a particular address is incremented
    }

    // mint one NFT for each of the eight sub-series
    for (uint256 i = 1; i <= numberOfSeries; i++) {
      _safeMint(msg.sender, tokenId[i-1]); // mint the tokens according to the Ids stored in the tokenId array
    }

    // remove address from whitelist following private sale minting
    if( (onlyWhitelisted == true) && (msg.sender != owner()) ) {
      whitelistedAddresses[msg.sender] = false;
      privateSaleCounter++;  
    }
  }  
  
  // indicates whether a paticular address is on the whitelist
  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  // returns the tokenId of NFTs belonging to the particular address
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
    
    // not revealed URI
    if(revealed == false) {
      return bytes(notRevealedURI).length > 0
          ? string(abi.encodePacked(notRevealedURI, tokenId.toString(), baseExtension))
          : "";
    }

    // redemption URI
    if (redeemedTokens[tokenId]) {
      return bytes(redeemedURI).length > 0
          ? string(abi.encodePacked(redeemedURI, tokenId.toString(), baseExtension))
          : "";      
    }

    // base URI
    string memory currentBaseURI = baseURI;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

/****** onlyOwner *******/

  function mintReserve() public onlyOwner nonReentrant{
    require(!reserveMinted,"the reserve can only be minted once");
    for (uint256 bundle = 1; bundle <= 14; bundle++){
      for (uint256 i = 1; i <= numberOfSeries; i++) {
        addressMintedBalance[msg.sender]++;
        uint256 tokenId = seriesTokenId[i];
        seriesTokenId[i]++;
        seriesCounter[i]++;
        _safeMint(msg.sender, tokenId); 
      }
    }
    reserveMinted = true;
  }

  function reveal() public onlyOwner {
      revealed = true;
  }

  function initiatePublicSale() public onlyOwner {
      onlyWhitelisted = false;
  }
  
  function setPrivateSaleAllocation(uint256 _bundleLimit) public onlyOwner {
    privateSaleAllocation = _bundleLimit;
  }

  function setMintPerAddressLimit(uint256 _limit) public onlyOwner {
    mintPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedURI = _notRevealedURI;
  }

  function _setRedeemedURI(string memory _initRedeemedURI) private {
    redeemedURI = _initRedeemedURI;
  }

  // onlyOwner call for changing redemption status of token and updates the redeemed token URI
  function setRedemptionStatus(uint256 _tokenId, bool _state, string memory _redeemedURI) public onlyOwner {
    require(_state == true || _state == false, "_state must be true or false");
    redeemedTokens[_tokenId] = _state;
    _setRedeemedURI(_redeemedURI);
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      whitelistedAddresses[_users[i]] = true;
    }
  }
 
  function removeFromWhitelist(address[] calldata _users) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      whitelistedAddresses[_users[i]] = false;
    }
  }

  function withdraw(address _address) public payable onlyOwner {
    (bool os, ) = payable(_address).call{value: address(this).balance}("");
    require(os);
  }
}