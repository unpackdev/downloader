//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

import "./Pausable.sol";

import "./Ownable.sol";

import "./VRFConsumerBase.sol";

import "./Counters.sol";

import "./InitDiceAttributes.sol";

import "./YoloInterfaces.sol";


contract AlphaDeed is 
  ERC721Enumerable, 
  ERC721URIStorage, 
  VRFConsumerBase, 
  Pausable, 
  Ownable
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;

  uint public constant MAX_SUPPLY = 5184;  // 72*72

  ERC721 public DiceTokens;
  IYoloChips public Chips;

  string public baseURI = "https://api.yolodice.xyz/deed/";

  uint public maxDeedsPerAddress = 20;

  uint public diceDeckMintFee = 0.0 ether; // free for dice holders to mint access-locked
  uint public diceWildcardMintFee = 0.036 ether;
  uint public generalWildcardMintFee = 0.072 ether;

  uint8 public salePhase = 0;

  uint16[] yieldRates;

  // track whether a given dice set has been used to buy a guaranteed deed
  mapping (uint => uint) public deedLookupByDiceId;
  mapping (uint => uint) public diceLookupByDeedId; 
  // IMPORTANT!!!!
  // Token IDs start at 0... but the default value for 
  // an int mapping in solidity is also 0. Therefore, to distinguish
  // between a token with ID 0 versus an inititialized mapping,
  // we use variables to explicitly track when dice set 0 
  // is expended on a deed, and when deed 0 is purchased with a dice set.
  uint dice0ExpendedOn = 2**256 - 1;
  uint deed0PurchasedWithDice = 2**256 - 1;
  // dice can also be expended on wildcards - we need to track these
  // purchases separately, so that during the reveal phase,
  // we know not to draw from the dice's guaranteed rarity deck,
  // but from the wildcard deck instead
  mapping (uint => bool) public wildcards;

  // CHAINLINK
  bytes32 public keyHash;
  uint public linkFee;
  
  // We're using this randomness as the seed for the card reveal 
  uint public randomNumber;

  constructor(
    address diceTokenContractAddress,
    address chipsTokenContractAddress,
    address vrfCoordinator,
    address linkToken,
    bytes32 _keyHash,
    uint _linkFee
  // mainnet addresses
  ) VRFConsumerBase(
    vrfCoordinator,
    linkToken
  ) ERC721 (
    "Yolo Land Deed",
    "DEED"
  ) {

    // mainnet:
    // 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
    keyHash =  _keyHash;
    // 2 * 10 ** 18;
    linkFee = _linkFee;

    DiceTokens = ERC721(diceTokenContractAddress);
    Chips = IYoloChips(chipsTokenContractAddress);
  }

  /*
    CORE API
  */

  // During Phase One, dice holders can purchase a deed with access
  // level matching that of their dice, or they can opt
  // to purchase a wildcard
  function purchaseAsDiceHolder(
    uint[] calldata deckMatchedDiceIds, uint[] calldata wildcardDiceIds
  ) external payable whenNotPaused{

    require(salePhase == 1, "Dice presale inactive");
    require((deckMatchedDiceIds.length + wildcardDiceIds.length) > 0, "Provide at lease one dice set");
    
    require(
      diceWildcardMintFee * wildcardDiceIds.length + diceDeckMintFee * deckMatchedDiceIds.length
      == msg.value,
      "Fee is incorrect"
    );

    // matched
    for (uint i=0; i < deckMatchedDiceIds.length; i++){
      uint diceId = deckMatchedDiceIds[i];
      _mintFromDice(diceId);
    }
    // wildcard
    for (uint i=0; i < wildcardDiceIds.length; i++){
      uint diceId = wildcardDiceIds[i];
      uint deedId =_mintFromDice(diceId);

      // need to separately track if this was a wildcard purchase,
      // so we know during reveal phase not to draw from the access decks
      wildcards[deedId] = true;      
    }
  }

  function _mintFromDice(uint diceId) internal returns (uint){

      require(DiceTokens.ownerOf(diceId) == msg.sender, "You do not own this dice set.");

      require(getDeedByDiceId(diceId) == -1, "Deed has already been claimed for this dice set.");

      uint deedId = _tokenIdCounter.current();

      deedLookupByDiceId[diceId] = deedId;
      if (deedId == 0) {
        deed0PurchasedWithDice = diceId;
      }

      diceLookupByDeedId[deedId] = diceId;
      if (diceId == 0) {
        dice0ExpendedOn = deedId;
      }

      _tokenIdCounter.increment();
      _safeMint(msg.sender, deedId);

      return deedId;
  }

  // During Phase Two, anyone can purchase a wildcard without the need for a dice set to expend. 
  function purchaseWildcardGeneralSale(uint numForPurchase) external payable whenNotPaused{
    require(salePhase == 2, "General sale inactive");

    require(msg.value == numForPurchase * generalWildcardMintFee, "Fee is incorrect");
    require(numForPurchase + totalSupply() <= MAX_SUPPLY, "Not enough tokens remaining");
    require(
      maxDeedsPerAddress
      >= (numForPurchase + this.balanceOf(msg.sender)
    ), "Max allowable deeds exceeded for this address");

    for (uint i=0; i < numForPurchase; i++){
      uint deedId = _tokenIdCounter.current();
      _tokenIdCounter.increment();
      wildcards[deedId] = true;  
      _safeMint(msg.sender, deedId);
    }
  }

  // step 1 (called by YOLO)
  // Initiates request for randomness
  function requestRandomNumber() external onlyOwner returns (bytes32 requestId) {
      require(LINK.balanceOf(address(this)) >= linkFee, "Not enough LINK");

      bytes32 req = requestRandomness(keyHash, linkFee);
      return req;
  }

  // step 2 (called by the coordinator)
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    randomNumber = randomness;
  }


  function beginDiceHolderSale() external onlyOwner {
    salePhase = 1;
  }

  function beginGeneralSale() external onlyOwner {
    salePhase = 2;
  }

  function withdraw() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Yolo Deed: Withdraw failed");
  }


  function yieldRate(uint256 tokenId) external view returns (uint256) {
    return yieldRates[tokenId];
  }

  /*
    GETTERS/SETTERS
  */

  function getDiceByDeedId(uint deedId) external view returns (int) {
    int diceId = int(diceLookupByDeedId[deedId]);
    if (diceId > 0 || dice0ExpendedOn == deedId) {
      return diceId;
    }
    return -1;
  }

  function getDeedByDiceId(uint diceId) public view returns (int) {
    int deedId = int(deedLookupByDiceId[diceId]);
    if (deedId > 0 || deed0PurchasedWithDice == diceId) {
      return deedId;
    }
    return -1;
  }

  function isWildcard(uint deedId) external view returns (bool) {
    return wildcards[deedId];
  }

  function setMaxDeedsPerAddress(uint n) external onlyOwner {
    maxDeedsPerAddress = n;
  }

  function setDiceDeckMintFee(uint _fee) external onlyOwner {
    diceDeckMintFee = _fee;
  } 

  function setDiceWildcardMintFee(uint _fee) external onlyOwner {
    diceWildcardMintFee = _fee;
  } 

  function setGeneralWildcardMintFee(uint _fee) external onlyOwner {
    generalWildcardMintFee = _fee;
  } 

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setLinkFee(uint _linkFee) external onlyOwner {
    linkFee = _linkFee;
  }

  function setChainlinkKeyHash(bytes32 _keyHash) external onlyOwner {    
    keyHash =  _keyHash;
  }

  // called after each reveal, in batches. Each addition to the array MUST 
  // be sequential. E.g.,
  // 1st Batch: Rates for tokens 0-2000
  // 2nd Batch: rates for tokens 2001 - 5184
  // A token's rate should not be added until after it has been revealed.
  function addYieldRates(uint16[] calldata _yieldRates) external onlyOwner {
    for (uint16 i; i < _yieldRates.length; i++) {
      yieldRates.push(_yieldRates[i]);
    }
  }

  // crude undo button in case we make a mistake loading yield rates
  function deleteYieldRates() external onlyOwner {
    delete yieldRates;
  }

  /*
    OVERRIDES
  */

  function _baseURI() internal override view returns (string memory) {
      return baseURI;
  }

  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
      internal
      override(ERC721, ERC721Enumerable)
  {
      // Inform the yield token ownership is changing.
      // We don't need to specify the token id because the
      // chips contract itself looks at all owned properties
      Chips.updateOwnership(from, to);
      super._beforeTokenTransfer(from, to, tokenId);
  }

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

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
  }
}
