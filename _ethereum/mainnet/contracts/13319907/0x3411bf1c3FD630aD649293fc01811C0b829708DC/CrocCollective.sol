// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title Croc Collective ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract CrocCollective is ERC721Enumerable, Ownable, Pausable {
  using SafeMath for uint256;
  using Address for address payable;

  uint256 public constant CROC_SUPPLY = 7777;
  uint256 public constant CROC_SUPPLY_PRESALE = 500;
  uint256 public constant CROC_PER_ORDER = 20;
  uint256 public constant CROC_PRICE = 0.04 ether;
  uint256 public constant CROC_PRICE_PRESALE = 0.03 ether;

  string private _baseTokenURI;
  string private _contractURI;

  bool public presaleLive;
  bool public saleLive;

  address private _devAddress = 0xbB61A5398EeF5707fa662F42B7fC1Ca32e76e747;

  constructor(
    string memory initBaseTokenURI,
    string memory initContractURI
  )
    ERC721("The Croc Collective", "CROC")
  {
    _baseTokenURI = initBaseTokenURI;
    _contractURI = initContractURI;
  }

  /**
   * @dev Mints number of tokens specified during presale.
   * @param quantity uint256 Number of tokens to be minted
   */
  function presaleBuy(uint256 quantity) external payable whenNotPaused {
    require(presaleLive, "CrocCollective: Presale not currently live");
    require(!saleLive, "CrocCollective: Sale is no longer in the presale stage");
    require(quantity <= CROC_PER_ORDER, "CrocCollective: Max per order exceeded");
    require(quantity != 0, "CrocCollective: Cannot mint zero tokens");
    require(totalSupply() <= (CROC_SUPPLY_PRESALE - quantity), "CrocCollective: Quantity exceeds remaining tokens");
    require(msg.value >= (quantity * CROC_PRICE_PRESALE), "CrocCollective: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Mints number of tokens specified.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable whenNotPaused {
    require(!presaleLive, "CrocCollective: Sale is currently in the presale stage");
    require(saleLive, "CrocCollective: Sale is not currently live");
    require(quantity <= CROC_PER_ORDER, "CrocCollective: Max per order exceeded");
    require(quantity != 0, "CrocCollective: Cannot mint zero tokens");
    require(totalSupply() <= (CROC_SUPPLY - quantity), "CrocCollective: Quantity exceeds remaining tokens");
    require(msg.value >= (quantity * CROC_PRICE), "CrocCollective: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "CrocCollective: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }

  /**
   * @dev Returns contract URI.
   * @return string Contract URI
   */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Toggles status of token presale. Only callable by owner.
   */
  function togglePresale() external onlyOwner {
    presaleLive = !presaleLive;
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() external onlyOwner {
    payable(_devAddress).sendValue(address(this).balance / 10);
    payable(msg.sender).sendValue(address(this).balance);
  }
}