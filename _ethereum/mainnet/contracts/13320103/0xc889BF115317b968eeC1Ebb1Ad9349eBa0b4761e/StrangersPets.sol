// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";

/*
 *  Art by @strangersolemn
 *  Code by @dadev42
 */
contract StrangersPets is Context, ERC721Enumerable, Ownable {

  enum airDropClaimStatus { Invalid, Unclaimed, Claimed }

  uint private constant MAX_PETS = 150;
  uint public petsPerDrop;

  bool private _isActive = false;

  mapping (address => airDropClaimStatus) private _airDropClaims;

  string private _baseTokenURI;
  bool private _hasBaseTokenUri = false;

  constructor(string memory baseTokenURI) ERC721("Strangers Pets", "Stangers Pets") {
    _baseTokenURI = baseTokenURI;
  }

  // claim pet
  function claimPet() external {
    require(_isActive, "Not active");
    require(petsPerDrop > 0, "No more pets available for this drop");
    require(_airDropClaims[msg.sender] != airDropClaimStatus.Claimed, "You've already claimed your pet");
    require(_airDropClaims[msg.sender] == airDropClaimStatus.Unclaimed, "You are not on the airdrop list");
    require(totalSupply() + 1 <= MAX_PETS, "Mint would exceed max supply of pets");
    uint tokenId = totalSupply() + 1;
    _safeMint(msg.sender, tokenId);
    _airDropClaims[msg.sender] = airDropClaimStatus.Claimed;
		petsPerDrop--;
  }

  // see if airdrop is active
  function isAirDropActive() external view returns (bool status) {
    return _isActive;
  }

  // token uri
  function tokenURI(uint tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "Token does not exist");

    return string(abi.encodePacked(_baseTokenURI, uintToBytes(tokenId)));
  }

  // add address for a free mint
  function addAddressToAirdrop(address[] memory wallets) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      _airDropClaims[wallets[i]] = airDropClaimStatus.Unclaimed;
    }
  }

  // set pets per drop
  function setPetsPerDrop() external onlyOwner {
		petsPerDrop = 50;
  }

  // reset addresses
  function resetAirdropAddresses(address[] memory wallets) external onlyOwner {
    for (uint256 i = 0; i < wallets.length; i++) {
      _airDropClaims[wallets[i]] = airDropClaimStatus.Invalid;
    }
  }

  // toggle airdrop on
  function startAirDrop() external onlyOwner {
    _isActive = true;
  }

  // toggle airdrop off
  function stopAirDrop() external onlyOwner {
    _isActive = false;
  }

  // if the airdrops are not claimed owner can send it
  function safeMint() public onlyOwner {
		require(petsPerDrop > 0, "No more pets available for this drop");
    uint tokenId = totalSupply() + 1;
    _safeMint(owner(), tokenId);
		petsPerDrop--;
  }

  // set the base uri for the tokens
  function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
    _baseTokenURI = baseTokenURI;
    _hasBaseTokenUri = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function uintToBytes(uint v) private pure returns (bytes32 ret) {
    if (v == 0) {
      ret = '0';
    }
    else {
      while (v > 0) {
        ret = bytes32(uint(ret) / (2 ** 8));
        ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
        v /= 10;
      }
    }
    return ret;
  }

}
