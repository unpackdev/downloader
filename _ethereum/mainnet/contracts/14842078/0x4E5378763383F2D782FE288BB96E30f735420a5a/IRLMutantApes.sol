//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";

contract IRLMutantApes is ERC721A, Ownable {
  string private _baseTokenURI;

  uint256 public presaleTime = 1653487200;
  uint256 public publicTime = 1653494400;

  uint256 public presalePricePerToken = 0.067 ether;
  uint256 public publicPricePerToken = 0.08 ether;

  uint256 public maxQuantity = 5;

  uint256 public maxSupply = 444;

  mapping(address => uint256) public freeMintAllowance;

  /**
  * Payment distribution and addresses
  */
  uint256 internal totalShares = 100;
  uint256 internal totalReleased;
  mapping(address => uint256) internal released;
  mapping(address => uint256) internal shares;
  address internal project = 0x1D76c2ea5ec8beE284404D20D8f208EB80e936Dd;
  address internal shareHolder2 = 0xB594bc0BAC1D0eB63F4fDEabF3822431E549427d;
  address internal shareHolder3 = 0x83E5FB2ec197760da44d31a570d475a2d7d3cb16;
  address internal dev = 0x9C68f0C8004a1068Bf41Ce9f99fC4327B5555bbb;

  constructor() ERC721A("IrlMutantApes", "IRLMA") {
    shares[project] = 65;
    shares[shareHolder2] = 5;
    shares[shareHolder3] = 15;
    shares[dev] = 15;

    _baseTokenURI = "ipfs://QmNW56MB2qfC6RVPemNdhYNec9DTndJ6qave2GCWjZtqhR/";

    freeMintAllowance[project] = 20;
    
    transferOwnership(project);
  }

  // change presalePrice
  function setPresalePrice(uint256 newPriceInWei) external onlyOwner {
    presalePricePerToken = newPriceInWei;
  }

  // change publicPrice
  function setPublicPrice(uint256 newPriceInWei) external onlyOwner {
    publicPricePerToken = newPriceInWei;
  }

  /** 
  * reduce supply
  * Error messages:
  * - I0 : "Supply can not be increased"
  * - I1 : "Supply has to be greater than totalSupply"
  */
  function reduceMaxSupply(uint256 newSupply) external onlyOwner {
    require(newSupply < maxSupply, "I0");
    require(newSupply >= totalSupply(), "I1");

    maxSupply = newSupply;
  }

  /** 
  * change time of presale
  */
  function setTimePresale(uint256 newTime) external onlyOwner {
    presaleTime = newTime;
  }

  /** 
  * change time of public
  */
  function setTimePublic(uint256 newTime) external onlyOwner {
    publicTime = newTime;
  }

  /** 
  * Free mint
  * Error messages:
  * - I2 : "You are not eligible for this many freemints"
  * - I3 : "Collection is sold out"
  */
  function freeMint(uint256 quantity) external {
    require(freeMintAllowance[msg.sender] >= quantity, "I2");
    require(totalSupply() + quantity <= maxSupply, "I3");
    freeMintAllowance[msg.sender] -= quantity;
    _safeMint(msg.sender, quantity);
  }

  /** 
  * Give free mint
  */
  function giveFreeMint(address[] calldata addresses, uint256[] calldata quantities) external onlyOwner {
    for (uint256 index = 0; index < addresses.length; index++) {
      freeMintAllowance[addresses[index]] += quantities[index];
    }
  }

  /** 
  * Presale mint
  * Error messages:
  * - I3 : "Collection is sold out"
  * - I4 : "Presale has not started"
  * - I5 : "Presale is over"
  * - I6 : "Exceeding maximum quantity"
  * - I7 : "Wrong price"
  */
  function presaleMint(uint256 quantity) external payable {
    require(block.timestamp >= presaleTime, "I4");
    require(block.timestamp < publicTime, "I5");
    require(quantity < maxQuantity, "I6");

    require(msg.value == presalePricePerToken * quantity, "I7");
    require(totalSupply() + quantity <= maxSupply, "I3");

    _safeMint(msg.sender, quantity);
  }

  /** 
  * Presale mint
  * Error messages:
  * - I3 : "Collection is sold out"
  * - I6 : "Exceeding maximum quantity"
  * - I7 : "Wrong price"
  * - I8 : "Public sale has not started"
  */
  function publicMint(uint256 quantity) external payable {
    require(block.timestamp >= publicTime, "I8");
    require(quantity < maxQuantity, "I6");

    require(msg.value == publicPricePerToken * quantity, "I7");
    require(totalSupply() + quantity <= maxSupply, "I3");

    _safeMint(msg.sender, quantity);
  }

  /** 
  * BaseURI
  */
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  /** 
  * set baseURI
  */
  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  /** 
  * set start tokenId
  */
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /** 
  * Withdraw contract's funds
  * Error messages:
  * - I9 : "No shares for this account"
  * - I10 : "No remaining payment"
  */
  function withdraw(address account) external {
    require(shares[account] > 0, "I9");
    uint256 totalReceived = address(this).balance + totalReleased;
    uint256 payment = (totalReceived * shares[account]) / totalShares - released[account];
    require(payment > 0, "I10");
    released[account] = released[account] + payment;
    totalReleased = totalReleased + payment;
    payable(account).transfer(payment);
  }
}
