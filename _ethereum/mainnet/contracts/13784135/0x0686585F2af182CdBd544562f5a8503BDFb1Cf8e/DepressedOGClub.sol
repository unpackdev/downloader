// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";

/**
 * @title Depressed OG Club ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract DepressedOGClub is ERC721Enumerable, Ownable {
  using Address for address payable;

  uint256 public constant DOC_PREMINT = 30;
  uint256 public constant DOC_MAX = 8100;
  uint256 public constant DOC_PRICE = 0.035 ether;
  uint256 public constant DOC_PER_TX = 10;

  string private _baseTokenURI;

  bool public saleLive;

  bool public locked;

  constructor(string memory newBaseTokenURI)
    ERC721("Depressed OG Club", "DOC")
  {
    _baseTokenURI = newBaseTokenURI;
    _preMint(DOC_PREMINT);
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive, "DepressedOGClub: Sale is not currently live");
    require(totalSupply() <= (DOC_MAX - quantity), "DepressedOGClub: Quantity exceeds remaining tokens");
    require(quantity <= DOC_PER_TX, "DepressedOGClub: Quantity exceeds max tokens per transaction");
    require(quantity != 0, "DepressedOGClub: Cannot buy zero tokens");
    require(msg.value >= (quantity * DOC_PRICE), "DepressedOGClub: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply()+1);
    }
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    require(!locked, "DepressedOGClub: Contract metadata is locked");
    _baseTokenURI = newBaseURI;
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "DepressedOGClub: URI query for nonexistent token");
    return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
  }

  /**
   * @dev Toggles status of token sale. Only callable by owner.
   */
  function toggleSale() external onlyOwner {
    saleLive = !saleLive;
  }

  /**
   * @dev Locks contract metadata. Only callable by owner.
   */
  function lockMetadata() external onlyOwner {
    locked = true;
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Pre mint n tokens to owner address.
   * @param n uint256 Number of tokens to be minted
   */
  function _preMint(uint256 n) private {
    for (uint256 i=0; i<n; i++) {
      _safeMint(msg.sender, totalSupply()+1);
    }
  }
}