// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 *       ______               ___            __      
 *      / ____/________ _____/ (_)__  ____  / /______
 *     / / __/ ___/ __ `/ __  / / _ \/ __ \/ __/ ___/
 *    / /_/ / /  / /_/ / /_/ / /  __/ / / / /_(__  ) 
 *    \____/_/   \__,_/\__,_/_/\___/_/ /_/\__/____/  
 *
 *                   Gradients | 2021  
 *             @author Josh Stow (jstow.com)
 */

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";

contract Gradients is ERC721Enumerable, Ownable {
  using Address for address payable;

  uint256 public constant GRAD_MAX = 9999;
  uint256 public constant GRAD_PRICE = 0.08 ether;

  string private _baseTokenURI;
  string private _contractURI;

  bool public saleLive;

  bool public locked;

  address private _devAddress = 0xbB61A5398EeF5707fa662F42B7fC1Ca32e76e747;

  constructor(
    string memory newBaseTokenURI,
    string memory newContractURI
  )
    ERC721("Gradients", "GRAD")
  {
    _baseTokenURI = newBaseTokenURI;
    _contractURI = newContractURI;
  }

  /**
   * @dev Mints number of tokens specified to wallet.
   * @param quantity uint256 Number of tokens to be minted
   */
  function buy(uint256 quantity) external payable {
    require(saleLive, "Gradients: Sale is not currently live");
    require(totalSupply() + quantity <= GRAD_MAX, "Gradients: Quantity exceeds remaining tokens");
    require(quantity != 0, "Gradients: Cannot buy zero tokens");
    require(msg.value >= quantity * GRAD_PRICE, "Gradients: Insufficient funds");

    for (uint256 i=0; i<quantity; i++) {
      _safeMint(msg.sender, totalSupply()+1);
    }
  }

  /**
   * @dev Set base token URI.
   * @param newBaseURI string New URI to set
   */
  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    require(!locked, "Gradients: Contract metadata is locked");
    _baseTokenURI = newBaseURI;
  }

  /**
   * @dev Set contract URI.
   * @param newContractURI string New URI to set
   */
  function setContractURI(string calldata newContractURI) external onlyOwner {
    require(!locked, "Gradients: Contract metadata is locked");
    _contractURI = newContractURI;
  }
  
  /**
   * @dev Returns token URI of token with given tokenId.
   * @param tokenId uint256 Id of token
   * @return string Specific token URI
   */
  function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
    require(_exists(tokenId), "Gradients: URI query for nonexistent token");
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
  function withdraw() external onlyOwner {
    payable(_devAddress).sendValue(address(this).balance / 100);  // 1%
    payable(msg.sender).sendValue(address(this).balance);
  }
}