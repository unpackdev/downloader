// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *                 _____                  __   _ 
 *                / ___/____ ________  __/ /__(_)
 *                \__ \/ __ `/ ___/ / / / //_/ / 
 *               ___/ / /_/ (__  ) /_/ / ,< / /  
 *              /____/\__,_/____/\__,_/_/|_/_/   
 *                               
 *                       Sasuki | 2022
 *               @author Josh Stow (jstow.com)
 */

import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Address.sol";
import "./ERC721A.sol";

contract Sasuki is ERC721A, Ownable {
  using Address for address payable;

  uint256 public constant SSK_PREMINT = 9;
  uint256 public constant SSK_PUBLIC = 990;
  uint256 public constant SSK_MAX = SSK_PREMINT + SSK_PUBLIC; // 999

  uint256 public constant SSK_PRICE = 0.1 ether;

  uint256 public publicMinted;

  string private _baseTokenURI;

  bool public saleLive;

  bool public locked;

  constructor(string memory newBaseTokenURI)
    ERC721A("Sasuki", "SSK")
  {
    _baseTokenURI = newBaseTokenURI;
    _safeMint(owner(), SSK_PREMINT);
  }

  modifier notLocked {
    require(!locked, "Contract metadata is locked");
    _;
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive, "Sale is not currently live");
    require(totalSupply() + quantity <= SSK_MAX &&
      publicMinted + quantity <= SSK_PUBLIC, "Quantity exceeds remaining tokens");
    require(msg.value >= quantity * SSK_PRICE, "Insufficient funds");

    publicMinted += quantity;
    _safeMint(msg.sender, quantity);
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner notLocked {
    _baseTokenURI = newBaseURI;
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
   * @dev Returns base token URI.
   * @return string Base token URI
   */
  function _baseURI() internal view override(ERC721A) returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev Returns starting tokenId.
   * @return uint256 Starting token Id
   */
  function _startTokenId() internal pure override(ERC721A) returns (uint256) {
    return 1;
  }
}