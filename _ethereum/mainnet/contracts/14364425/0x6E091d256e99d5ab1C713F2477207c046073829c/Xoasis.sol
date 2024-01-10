// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./ECDSA.sol";

/* __   __            ____                _____   _____    _____ 
   \ \ / /           / __ \      /\      / ____| |_   _|  / ____|
    \ V /   ______  | |  | |    /  \    | (___     | |   | (___  
     > <   |______| | |  | |   / /\ \    \___ \    | |    \___ \ 
    / . \           | |__| |  / ____ \   ____) |  _| |_   ____) |
   /_/ \_\           \____/  /_/    \_\ |_____/  |_____| |_____/ 
*/

contract Xoasis is ERC721A, Ownable {
  using Strings for uint256;
  string public baseURI;

  bool public preSaleOpen = false;
  bool public publicSaleOpen = false;
  bool public revealed = false;

  uint256 public maxSupplyAmount = 11111;
  uint256 public preSalePrice = 0.18 ether;
  uint256 public publicSalePrice = 0.2 ether;

  uint8 public maxPreSaleMint = 1;
  uint8 public maxPublicSaleMint = 5;

  address public signer;

  //pre sale minted
  mapping (address => bool) private preSaleMinted;

  //public sale minted
  mapping (address => uint256) private publicSaleMinted;

  //LAUNCHPAD
  uint256 public LAUNCH_MAX_SUPPLY;    // max launch supply
  uint256 public LAUNCH_SUPPLY;        // current launch supply

  address public LAUNCHPAD;

  modifier onlyLaunchpad() {
      require(LAUNCHPAD != address(0), "launchpad address must set");
      require(msg.sender == LAUNCHPAD, "must call by launchpad");
      _;
  }

  function getMaxLaunchpadSupply() view public returns (uint256) {
      return LAUNCH_MAX_SUPPLY;
  }

  function getLaunchpadSupply() view public returns (uint256) {
      return LAUNCH_SUPPLY;
  }

  constructor(
    string memory baseURI_,
    address signer_, 
    address launchpad, 
    uint256 maxSupply
  ) ERC721A("Xoasis", "XOASIS", 500, 11111) {
    baseURI = baseURI_;
    signer = signer_;
    LAUNCHPAD = launchpad;
    LAUNCH_MAX_SUPPLY = maxSupply;
  }

  modifier contractVerify() {
    require(tx.origin == msg.sender, "THE CALLER CANT BE A CONTRACT");
    _;
  }

  //mint
  function preSaleMint(bytes memory signature) external payable contractVerify {
    require(preSaleOpen, "XOASIS PRE SALE HAS NOT OPEN YET");
    require(!isPreMinted(msg.sender), "SORRY, ONLY ONE CHANCE");
    require(totalSupply() + maxPreSaleMint <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
    require(signer == signatureWallet(msg.sender, signature), "NOT AUTHORIZED TO PRE SALE MINT");
    require(msg.value >= maxPreSaleMint * preSalePrice, "INSUFFICIENT ETH AMOUNT");
    if (msg.value > maxPreSaleMint * preSalePrice) {
      payable(msg.sender).transfer(msg.value - maxPreSaleMint * preSalePrice);
    }
    preSaleMinted[msg.sender] = true;
    _safeMint(msg.sender, maxPreSaleMint);
  }

  function signatureWallet (address sender, bytes memory signature) private pure returns (address){
      bytes32 hash = keccak256(
        abi.encodePacked(
        "\x19Ethereum Signed Message:\n32",
        keccak256(abi.encodePacked(sender))
        )
      );
      return ECDSA.recover(hash, signature);
  }

  function publicSaleMint(uint256 amount) external payable contractVerify {
    require(publicSaleOpen, "XOASIS PUBLIC SALE HAS NOT OPEN YET");
    require(amount <= maxPublicSaleMint, "EXCEEDS MAX PUBLIC SALE MINT");
    require(totalSupply() + amount <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
    uint256 mintedAmount = publicAmountMinted(msg.sender);
    require(mintedAmount + amount <= maxPublicSaleMint, "EXCEEDS MAX PUBLIC SALE MINT");
    require(msg.value >= amount * publicSalePrice, "INSUFFICIENT ETH AMOUNT");
    if (msg.value > amount * publicSalePrice) {
      payable(msg.sender).transfer(msg.value - amount * publicSalePrice);
    }
    publicSaleMinted[msg.sender] = mintedAmount + amount;
    _safeMint(msg.sender, amount);
  }

  function giftMint(address xer, uint256 amount) external onlyOwner {
    require(amount > 0, "GIFT AT LEAST ONE");
    require(amount + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");
    _safeMint(xer, amount);
  }

  //read
  function isPreMinted(address owner) public view returns (bool) {
    require(owner != address(0), "ERC721A: number minted query for the zero address");
    return preSaleMinted[owner];
  }

  function publicAmountMinted(address owner) public view returns (uint256) {
    require(owner != address(0), "ERC721A: number minted query for the zero address");
    return publicSaleMinted[owner];
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    return revealed ? string(abi.encodePacked(baseURI, '/', Strings.toString(tokenId), ".json")) : baseURI;
  }

  //setting
  function togglePreSale() external onlyOwner {
    preSaleOpen = !preSaleOpen;
  }

  function togglePublicSale() external onlyOwner {
    publicSaleOpen = !publicSaleOpen;
  }

  function toggleRevealed() external onlyOwner {
    revealed = !revealed;
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setPreSalePrice(uint256 newPreSalePrice) external onlyOwner {
    preSalePrice = newPreSalePrice;
  }

  function setPublicSalePrice(uint256 newPublicSalePrice) external onlyOwner {
    publicSalePrice = newPublicSalePrice;
  }

  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
  }

  //withdraw
  address private wallet1 = 0xC6578bF58AFBEE73267807ff8C5065B869f3394A;
  address private wallet2 = 0xfe35028A0AAad06029185E15849a9c5CA78E8478;

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "NOT ENOUTH BALANCE TO WITHDRAW");

    (bool success1, ) = payable(wallet1).call{value: balance / 2}("");
    require(success1, "Failed to withdraw to wallet1");

    (bool success2, ) = payable(wallet2).call{value: balance / 2}("");
    require(success2, "Failed to withdraw to wallet2");
  }

  function mintTo(address to, uint size) external onlyLaunchpad {
    require(to != address(0), "can't mint to empty address");
    require(size > 0, "size must greater than zero");
    require(LAUNCH_SUPPLY + size <= LAUNCH_MAX_SUPPLY, "max supply reached");

    require(size + totalSupply() <= maxSupplyAmount, "REACHED MAX SUPPLY AMOUNT");

    _safeMint(to, size);
    LAUNCH_SUPPLY = LAUNCH_SUPPLY + size;
  }
}