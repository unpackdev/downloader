// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./VRFConsumerBase.sol";

contract BillionaireBunnyClub is ERC721Enumerable, Ownable, VRFConsumerBase {
  using SafeMath for uint256;

  string _baseTokenURI;
  uint256 private _maxMint = 20;
  uint256 private _presalemaxMint = 9;
  uint256 private _price = 8 * 10**16; //0.0800 ETH;
  bool public _saleActive = false;
  bool public _preSaleActive = false;
  uint public _presaleMaxEntries = 1112;
  uint public constant MAX_ENTRIES = 10000;
  uint public constant RESERVED = 100;
  uint256 private _devShare = 32;

  mapping(address => bool) public _presaleAllowList;
  address public constant creatorAddress = 0x40C8430a7C54b58D2AbC53AC79fEFb1aF4405242;
  address public constant devAddress = 0x7D09adF8251E9591abB3E0E4baE7EBdB5c482fA0;

  // Chainlink VRF based Airdrops
  bytes32 internal keyHash;
  uint256 internal fee;
  uint256 public randomResult;

  constructor(string memory baseURI, address vrfCoordinator, address linkTokenAddress, bytes32 _keyHash) ERC721("Billionaire Bunny Club", "BillionaireBunnyClub") VRFConsumerBase(vrfCoordinator, linkTokenAddress)  {
    setBaseURI(baseURI);

    keyHash = _keyHash;
    fee = 2 * 10**18;
  }

  function presale(uint256 num) public payable {
    uint256 supply = totalSupply();

    if(msg.sender != owner()) {
      require(_preSaleActive, "PreSale not Active");
      require(_presaleAllowList[msg.sender] == true, "Your address is not in AllowList");
      require((balanceOf(msg.sender) +  num) < (_presalemaxMint+1), "You can have a total of 7 Bunnies");
      require( msg.value >= _price * num,"Ether sent is not correct" );
    }

    require( supply + num < (_presaleMaxEntries+1), "Exceeds maximum supply" );

    for(uint256 i; i < num; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  function mint(address _to, uint256 num) public payable {
    uint256 supply = totalSupply();

    if(msg.sender != owner()) {
      require(_saleActive, "Sale not Active");
      require( num < (_maxMint+1),"You can mint a maximum of 20 Bunnies" );
      require( msg.value >= _price * num, "Ether sent is not correct" );
      require( supply + num < (MAX_ENTRIES - RESERVED + 1), "Exceeds maximum supply" );
    } else {
      require( supply + num < (MAX_ENTRIES+1), "Exceeds maximum supply" );
    }

    for(uint256 i; i < num; i++){
      _safeMint( _to, supply + i );
    }
  }

  function walletOfOwner(address _owner) public view returns(uint256[] memory) {
      uint256 tokenCount = balanceOf(_owner);

      uint256[] memory tokensId = new uint256[](tokenCount);
      for(uint256 i; i < tokenCount; i++){
          tokensId[i] = tokenOfOwnerByIndex(_owner, i);
      }
      return tokensId;
  }

  function getPrice() public view returns (uint256){
      if(msg.sender == owner()) {
          return 0;
      }
      return _price;
  }

  function setPrice(uint256 _newPrice) public onlyOwner() {
      _price = _newPrice;
  }

  function getMaxMint() public view returns (uint256){
      return _maxMint;
  }

  function setMaxMint(uint256 _newMaxMint) public onlyOwner() {
      _maxMint = _newMaxMint;
  }

  function getPresaleMaxMint() public view returns (uint256){
      return _presalemaxMint;
  }

  function setPresaleMaxMint(uint256 _newPresaleMaxMint) public onlyOwner() {
      _presalemaxMint = _newPresaleMaxMint;
  }

  function getPresaleMaxEntries() public view returns (uint256){
      return _presaleMaxEntries;
  }

  function setPresaleMaxEntries(uint256 _newPresaleMaxEntries) public onlyOwner() {
      _presaleMaxEntries = _newPresaleMaxEntries;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
      _baseTokenURI = baseURI;
  }

  function setsaleBool(bool val) public onlyOwner {
      _saleActive = val;
  }

  function setpresaleBool(bool val) public onlyOwner {
      _preSaleActive = val;
  }

  function withdrawAll() public payable onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0);
    require(payable(devAddress).send(balance.mul(_devShare).div(100)), "Transfer to dev failed");
    require(payable(creatorAddress).send(address(this).balance), "Transfer to creator failed");
  }

  function _isAllowed(address _inputAddress) public view returns(bool) {
    return _presaleAllowList[_inputAddress];
  }

  function updateAllowlist(address[] memory _addresses, bool _flag) public onlyOwner {
    for(uint256 i; i < _addresses.length ; i++){
      _presaleAllowList[_addresses[i]] = _flag;
    }
  }

  // ## VRF based Airdrop
  function getRandomNumber() public onlyOwner returns (bytes32 requestId){
    require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    return requestRandomness(keyHash, fee);
  }

  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    randomResult = randomness;
  }

  // n ids from 0-1999 to consider for airdrops
  function expand(uint256 n, uint256 entry_limit) public view onlyOwner returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomResult, i))) % entry_limit;
    }
    return expandedValues;
  }

  function airdrop(uint256 n, uint256 entry_limit) public onlyOwner {
    uint256[] memory raffle_winners = expand(n, entry_limit);
    uint256 supply = totalSupply();

    for (uint256 i; i < n; i++) {
      _safeMint(ownerOf(raffle_winners[i]), supply + i );
    }
  }
}