// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title Rune Club ERC-721 token contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract RuneClub is ERC721Enumerable, Ownable, Pausable {
  using SafeMath for uint256;
  using Address for address payable;

  uint256 public constant RCK_PREMINT = 20;
  uint256 public constant RCK_SUPPLY = 10000;
  uint256 public constant RCK_PRICE = 0.07 ether;

  string private _baseTokenURI;
  string private _contractURI;

  bool public saleLive;

  bool public locked;

  constructor(
    string memory newBaseTokenURI,
    string memory newContractURI
  )
    ERC721("Rune Club", "RCK")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;
    _preMint(RCK_PREMINT);
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable whenNotPaused {
    require(saleLive, "RuneClub: Sale is not currently live");
    require(totalSupply() <= (RCK_SUPPLY - quantity), "RuneClub: Quantity exceeds remaining tokens");
    require(quantity != 0, "RuneClub: Cannot buy zero tokens");
    require(msg.value >= (quantity * RCK_PRICE), "RuneClub: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply().add(1));
    }
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    require(!locked, "RuneClub: Contract metadata is locked");
    _baseTokenURI = newBaseURI;
  }
  
  /**
   * @dev Set contract URI.
   * @param newContractURI string New URI to set
   */
  function setContractURI(string calldata newContractURI) external onlyOwner {
    require(!locked, "RuneClub: Contract metadata is locked");
    _contractURI = newContractURI;
  }

  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "RuneClub: URI query for nonexistent token");
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
      _safeMint(owner(), totalSupply().add(1));
    }
  }
}