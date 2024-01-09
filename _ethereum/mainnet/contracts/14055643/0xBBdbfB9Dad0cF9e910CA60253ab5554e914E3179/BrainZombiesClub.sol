// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";

contract BrainZombiesClub is ERC721("Brain Zombies Club", "BZC") {

  string public baseURI;
  bool public isSaleActive;
  uint256 public circulatingSupply;
  address public owner = msg.sender;
  uint256 public itemPrice = 0.010 ether;
  uint256 public constant totalSupply = 3_333;

  //Purchasing tokens
  function mintTokens(uint256 _amount)
    external
    payable
    tokensAvailable(_amount)
  {
    require(
        isSaleActive,
        "Sale not started"
    );
    require(_amount > 0 && _amount <= 10, "Mint min 1, max 10");
    require(msg.value >= _amount * itemPrice, "Try to send more ETH");

    for (uint256 i = 0; i < _amount; i++)
        _mint(msg.sender, ++circulatingSupply);
  }
  function claim(uint256 _amount) external payable tokensAvailable(_amount) {
        require(
          isSaleActive,
          "Sale not started"
        );
        require(circulatingSupply + _amount <= 1111, "Free claiming ended.");
        require(_amount > 0 && _amount <= 10, "Mint min 1, max 10");
        require(balanceOf(msg.sender) + _amount <= 10, "You can claim only 10 free tokens");

        for (uint256 i = 0; i < _amount; i++)
        _mint(msg.sender, ++circulatingSupply);
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
  function balanceOfAddress(address _adr) public view returns (uint256) {
    return balanceOf(_adr);
  }
  //CONTRACT OWNER
  function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
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
    require(owner == msg.sender, "Ownable: Caller is not the owner");
    _;
  }
}