// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

contract LastManAlive is ERC721("Last Man Alive", "LMA") {

  string public baseURI;
  bool public isSaleActive;
  uint256 public circulatingSupply;
  address public owner = msg.sender;
  uint256 public itemPrice = 0.025 ether;
  //CONSTANTS
  uint256 public constant totalSupply = 4_444;
  uint256 public totalFreeSupply = 1_444;
  uint256 public constant totalFreePerWallet = 15;
  uint256 public constant totalPaidPerWallet = 15;
  
  mapping(address => uint256) private freeMinters;
  mapping(address => uint256) private holdersCounter;

  //Purchasing and claiming tokens
  function buyToken(uint256 _amount)
    external
    payable
    tokensAvailable(_amount)
  {
    address minter = msg.sender;
    require( isSaleActive, "Sale not started" );
    require(msg.value >= _amount * itemPrice, "Try to send more ETH");
    require(holdersCounter[minter] + _amount <= totalPaidPerWallet, "Maximum mint amount is 15");

    for (uint256 i = 0; i < _amount; i++) {
        _mint(minter, ++circulatingSupply);
        ++holdersCounter[minter];
    }
  }
  function claimToken(uint256 _amount) external payable tokensAvailable(_amount) {
        address claimer = msg.sender;
        require( isSaleActive, "Sale not started" );
        require(circulatingSupply + _amount <= totalFreeSupply, "Free claiming ended.");
        require(freeMinters[claimer] + _amount <= totalFreePerWallet, "You can claim only 15 free tokens");

        for (uint256 i = 0; i < _amount; i++) {
          _mint(claimer, ++circulatingSupply);
          ++freeMinters[claimer];
        }
  }

  //QUERIES
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    return string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), ".json"));
  }
  function tokensRemaining() public view returns (uint256) {
    return totalSupply - circulatingSupply;
  }

  //CONTRACT OWNERS
  function setBaseURI(string memory __baseURI) external onlyOwner {
    baseURI = __baseURI;
  }
  
  //TO UPDATE MINTING PRICE
  function updatePrice(uint256 __price) external onlyOwner {
    itemPrice = __price;
  }
  function updateFreeAmount(uint256 __amount) external onlyOwner {
    totalFreeSupply = __amount;
  }
  function toggleSale() external onlyOwner {
    isSaleActive = !isSaleActive;
  }
  function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
  }
  //MODIFIERS
  modifier tokensAvailable(uint256 _amount) {
      require(_amount <= tokensRemaining(), "Try minting less tokens");
      _;
  }
  modifier onlyOwner() {
    require((owner == msg.sender), "Ownable: Caller is not the owner");
    _;
  }
}