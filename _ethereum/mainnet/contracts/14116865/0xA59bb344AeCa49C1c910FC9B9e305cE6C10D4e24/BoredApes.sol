// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *  _______  _______  ______    _______  ______     _______  _______  _______  _______
 * |  _    ||       ||    _ |  |       ||      |   |   _   ||       ||       ||       |
 * | |_|   ||   _   ||   | ||  |    ___||  _    |  |  |_|  ||    _  ||    ___||  _____|
 * |       ||  | |  ||   |_||_ |   |___ | | |   |  |       ||   |_| ||   |___ | |_____
 * |  _   | |  |_|  ||    __  ||    ___|| |_|   |  |       ||    ___||    ___||_____  |
 * | |_|   ||       ||   |  | ||   |___ |       |  |   _   ||   |    |   |___  _____| |
 * |_______||_______||___|  |_||_______||______|   |__| |__||___|    |_______||_______|
 */

pragma solidity ^0.8.7;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// Bored Ape Yacht Club Interface
interface BAYC {
  function ownerOf(uint tokenId) external view returns (address);
}

contract BoredApes is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // BAYC contract
  address public baycContract;

  // Contract to recieve ETH raised in sales
  address public vault;

  // Control for public sale
  bool public isActive;

  // Reference to image and metadata storage
  string public baseTokenURI;

  // Amount of ETH required per mint
  uint256 public price;

  // Sets `baycContract` and `price` upon deployment
  constructor(address _baycContract, uint256 _price) ERC721("BoredApes", "BA") {
    setBAYCContract(_baycContract);
    setPrice(_price);
  }

  // Override of `_baseURI()` that returns `baseTokenURI`
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // Sets `isActive` to turn on/off minting in `mint()`
  function setActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  // Sets `baseTokenURI` to be returned by `_baseURI()`
  function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  // Sets `baycContract` to be used in `gift()` and `mint()`
  function setBAYCContract(address _baycContract) public onlyOwner {
    baycContract = _baycContract;
  }

  // Sets `price` to be used in `gift()` and `mint()` (called on deployment)
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // Sets `vault` to recieve ETH from sales and used within `withdraw()`
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  // Minting function used for gifting
  function gift(uint[] calldata apes) external onlyOwner {
    for(uint i; i < apes.length; i++){
      uint tokenId = apes[i];
      address owner = BAYC(baycContract).ownerOf(tokenId);

      require(!_exists(tokenId), "Ape Minted");

      _safeMint(owner, tokenId);
    }
  }

  // Minting function used in the public sale
  function mint(uint[] memory apes) external payable {
    require(isActive, 'Not Active');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(msg.value >= price * apes.length, 'Ether Amount Denied');

    for(uint i; i < apes.length; i++){
      uint tokenId = apes[i];
      address owner = BAYC(baycContract).ownerOf(tokenId);

      require(!_exists(tokenId), "Ape Minted");

      _safeMint(owner, tokenId);
    }
  }

  // Send balance of contract to address referenced in `vault`
  function withdraw() external payable onlyOwner {
    require(vault != address(0), 'Vault Invalid');
    require(payable(vault).send(address(this).balance));
  }
}
