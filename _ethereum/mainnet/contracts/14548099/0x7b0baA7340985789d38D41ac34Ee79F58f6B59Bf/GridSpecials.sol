// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC721.sol";
import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./SafeMath.sol";

interface INFT is IERC721 {}

contract GridSpecials is ERC1155, Ownable {
  struct Collection{
    bool active;
    address nftAddress;
    mapping(address => bool) minted;
  }

  mapping(uint256 => Collection) private _collections;

  constructor() ERC1155("https://www.infinitegrid.art/api/specials/{id}") {}
  string private _contractURI = "https://www.infinitegrid.art/api/specials/contract";
  
  // ** METADATA **
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory newuri) public onlyOwner {
    _contractURI = newuri;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }

  // ** SALE STATE **
  function setSaleState(uint256 specialNumber, bool _saleState) public onlyOwner {
    //require(_collections[specialNumber], "No such special");
    _collections[specialNumber].active = _saleState;
  }

  function saleState(uint256 specialNumber) public view returns (bool) {
    return _collections[specialNumber].active;
  }

  // ** RELEASES **
  function addSpecialNumber(uint256 specialNumber, address _contract) public onlyOwner {
    _collections[specialNumber].active = false;
    _collections[specialNumber].nftAddress = _contract;
  }

  // ** MINTING **
  function specialHasBeenMinted(uint256 specialNumber, address minter) public view returns (bool) {
    return _collections[specialNumber].minted[minter];
  }

  function mintSpecial(uint256 specialNumber) public virtual {
    require(_collections[specialNumber].active, "Sale is closed");

    if(_collections[specialNumber].nftAddress != address(0x000000000000000000000000000000000000dEaD)) {
      require(INFT(_collections[specialNumber].nftAddress).balanceOf(msg.sender) > 0, "Wallet doesn't hold required NFT");
    }
    require(!specialHasBeenMinted(specialNumber, msg.sender), "Special already minted for this NFT");

    _collections[specialNumber].minted[msg.sender] = true;
    _mint(msg.sender, specialNumber, 1, "");
  }
}