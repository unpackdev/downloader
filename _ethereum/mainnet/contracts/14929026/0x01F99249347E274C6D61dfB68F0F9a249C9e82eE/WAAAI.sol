// SPDX-License-Identifier: MIT

// 888       888       d8888       d8888       d88888888888 
// 888   o   888      d88888      d88888      d88888  888   
// 888  d8b  888     d88P888     d88P888     d88P888  888   
// 888 d888b 888    d88P 888    d88P 888    d88P 888  888   
// 888d88888b888   d88P  888   d88P  888   d88P  888  888   
// 88888P Y88888  d88P   888  d88P   888  d88P   888  888   
// 8888P   Y8888 d8888888888 d8888888888 d8888888888  888   
// 888P     Y888d88P     888d88P     888d88P     8888888888                                                                                              

pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract WeAreAllAI is ERC721A, Ownable {

  using Strings for uint256;
  string public           baseURI;
  uint256 public constant maxSupply         = 6666;
  uint256 public          freeSupply        = 2222;
  uint256 public          price             = 0.002 ether;
  uint256 public          maxFreePerWallet  = 2;
  uint256 public          maxPerTx          = 5;
  bool public             mintEnabled       = true;

  mapping(address => uint256) private _walletFreeMints;
  mapping(address => uint256) private _walletMints;

  constructor() ERC721A("We Are All AI", "WAAAI"){
      baseURI = "ipfs://QmToG5751jJxmqmMaN8tGJWWJUMT1geUbYAhrvhzVYqpqC/";
      _safeMint(msg.sender, 1);
  }

  function mint(uint256 amt) external payable {
    require(mintEnabled, "Minting is not live yet.");
    require(msg.sender == tx.origin,"No bots, only true WAAAI!");
    require(totalSupply() + amt < maxSupply + 1, "Not enough WAAAI left.");
    require(amt < maxPerTx + 1, "That's enough WAAAI this tx!");
    require(msg.value >= amt * price,"Please send the exact amount.");

    _walletMints[_msgSender()] += amt;
    _safeMint(msg.sender, amt);
  }

    function freeMint(uint256 amt) external {
        require(mintEnabled, "Minting is not live yet.");
        require(msg.sender == tx.origin,"No bots, only true WAAAI!");
        require(totalSupply() + amt < freeSupply + 1, "Not enough Free WAAAI left.");
        require(_walletFreeMints[_msgSender()] + amt < maxFreePerWallet + 1, "That's enough Free WAAAI for you!");

        _walletFreeMints[_msgSender()] += amt;
        _safeMint(msg.sender, amt);
   }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: Nonexistent token");

	  string memory currentBaseURI = _baseURI();
	  return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : ".json";
  }

  function toggleMinting() external onlyOwner {
      mintEnabled = !mintEnabled;
  }

  function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
  }

  function setBaseURI(string calldata baseURI_) external onlyOwner {
      baseURI = baseURI_;
  }

  function setMaxFreePerWallet(uint256 maxFreePerWallet_) external onlyOwner {
      maxFreePerWallet = maxFreePerWallet_;
  }

  function setMaxPerWallet(uint256 maxPerTx_) external onlyOwner {
    maxPerTx = maxPerTx_;
  }

  function setPrice(uint256 price_) external onlyOwner {
      price = price_;
  }

  function setFreeSupply(uint256 freeSupply_) external onlyOwner {
     freeSupply = freeSupply_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }
  
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}

