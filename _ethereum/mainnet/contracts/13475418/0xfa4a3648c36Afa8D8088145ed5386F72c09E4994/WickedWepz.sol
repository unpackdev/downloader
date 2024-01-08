// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title Wicked Wepz ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract WickedWepz is ERC721Enumerable, Ownable, Pausable {
  using SafeMath for uint256;
  using Address for address payable;

  uint256 public constant WWz_RESERVED = 10;
  uint256 public constant WWz_MAX = 1000;
  uint256 public constant WWz_PRICE = 0.04 ether;
  uint256 public constant WWz_MAX_PER_TX = 20;

  string private _baseTokenURI;

  bool public saleLive;

  constructor(string memory newBaseTokenURI)
    ERC721("Wicked Wepz", "WWz")
  {
    _baseTokenURI = newBaseTokenURI;
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable whenNotPaused {
    require(saleLive, "WickedWepz: Sale is not currently live");
    require(totalSupply() <= ((WWz_MAX - WWz_RESERVED) - quantity), "WickedWepz: Quantity exceeds remaining tokens");
    require(quantity <= WWz_MAX_PER_TX, "WickedWepz: Quantity exceeds max per transaction");
    require(quantity != 0, "WickedWepz: Cannot buy zero tokens");
    require(msg.value >= (quantity * WWz_PRICE), "WickedWepz: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Mint reserved tokens to owner's wallet after sale is finished.
   */
  function claimReserved() public onlyOwner {
    require(totalSupply() == WWz_MAX, "WickedWepzFactory: Token sale in progress");

    for (uint256 i=0; i<WWz_RESERVED; i++) {
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "KrubberDuckiez: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
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
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }
}