// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./SafeMath.sol";

contract MetaDroids is ERC721("Meta Droids", "MD") {
  using SafeMath for uint256;

  string public baseURI;
  bool public isSaleActive;
  uint256 public circulatingSupply;
  address public owner = msg.sender;
  uint256 public itemPrice = 0.004 ether;
  uint256 public constant _totalSupply = 8_888;

  //Purchasing tokens
  function mint(uint256 _amount)
    external
    payable
    tokensAvailable(_amount)
  {
    require(
        isSaleActive,
        "Sale not started"
    );
    require(_amount > 0 && _amount <= 20, "Mint min 1, max 20");
    require(msg.value >= _amount * itemPrice, "Try to send more ETH");
    require(balanceOf(msg.sender) + _amount <= 20, "Max 20");

    for (uint256 i = 0; i < _amount; i++)
        _mint(msg.sender, ++circulatingSupply);
  }
  function whitelistMint(uint256 _amount) external payable tokensAvailable(_amount) {
        require(circulatingSupply < 888, "Reached limit...");
        require(_amount <= 888, "Maximum 888");
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
    return _totalSupply - circulatingSupply;
  }
  function balanceOfAddress(address _adr) public view returns (uint256) {
    return balanceOf(_adr);
  }
  function totalSupply() public view returns (uint256) {
    return circulatingSupply;
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
