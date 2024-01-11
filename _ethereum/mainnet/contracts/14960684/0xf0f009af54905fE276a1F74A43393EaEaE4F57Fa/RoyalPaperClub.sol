// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract RoyalPaperClub is ERC721A, Ownable, ReentrancyGuard {

  struct SaleConfig {
    uint64 maxSupply;
    bool isPublicSaleOpen;
    bool isRevealed;
    uint32 freeMintedAmount;
  }

  SaleConfig public saleConfig = SaleConfig(
    10000,
    false,
    false,
    0
  );

  string public unrevealedTokenURI;
  string public baseTokenURI;
  
  // This map will be used to keep track of minting during presale, sale and giveaway mints
  mapping(address => uint256) public freeMinted;

  constructor() ERC721A("RoyalPaperClub", "RPC") { }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "Caller is another contract");
    _;
  }

  /**
  * Public sale mint
  * Minting price during sale is 0.04 ether
  * The first 1000 NFTs are free, maximum 2 per wallet and you can request 1 at a time
  * The other 9000 will be at normal price
  */
  function mint(uint256 quantity) external payable callerIsUser nonReentrant {
    SaleConfig memory _saleConfig = saleConfig;
    require(_saleConfig.isPublicSaleOpen == true, "Sale not started yet");
    require(
      totalSupply() + quantity <= _saleConfig.maxSupply,
      "Quantity exceeds supply"
    );

    if (_saleConfig.freeMintedAmount < 100) {
      require(quantity == 1, "One free mint at a time");
      uint256 _freeMinted = freeMinted[msg.sender];
      require(_freeMinted <= 1, "You can only free mint twice");
      _safeMint(msg.sender, 1);
      freeMinted[msg.sender] = _freeMinted + 1;
      saleConfig.freeMintedAmount = _saleConfig.freeMintedAmount + 1;
    } else {
      require(msg.value == quantity * 0.04 ether, "Wrong ether sent");
      _safeMint(msg.sender, quantity);
    }
  }

  /**
  * Marketing, team, giveaways etc
  */
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= saleConfig.maxSupply,
      'Minting this will exceed supply'
    );
    _safeMint(msg.sender, quantity);
  }

  function togglePublicSale() external onlyOwner {
    saleConfig.isPublicSaleOpen = !saleConfig.isPublicSaleOpen;
  }

  /**
   * Reveal the NFTs
   */
  function reveal() external onlyOwner {
    saleConfig.isRevealed = true;
  }

  function _isRevealed() public view virtual override returns (bool) {
    return saleConfig.isRevealed;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed");
  }

  function withdrawPartOfEther(uint256 _value) external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: _value}("");
    require(success, "Transfer failed");
  }

  function setBaseTokenURI(string memory baseURI) external onlyOwner {
    baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

}
