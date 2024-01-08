// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./Address.sol";
import "./DepressedOGClub.sol";

/**
 * @title Depressed Og Club token sale contract.
 * @author Josh Stow (https://github.com/jshstw)
 */
contract DepressedOGClubFactory is Ownable {
  /*** MODIFIERS ***/

  /**
   * @dev Functions with this modifier can only be called when the sale
   *    is live.
   */
  modifier isLive() {
    require(saleLive, "DepressedOGClubFactory: Sale is not currently in progress");
    _;
  }

  /** STORAGE */

  using Strings for string;
  using Address for address payable;

  /**
   * @dev Max supply of tokens.
   */
  uint256 constant MAX_SUPPLY = 8100;

  /**
   * @dev Max number of tokens that can be purchased per order.
   */
  uint256 constant MAX_PER_ORDER = 10;

  /**
   * @dev Price per token in Wei.
   */
  uint256 constant TOKEN_PRICE = 35000000000000000; // (0.035 ETH)

  /**
   * @dev Ethereum address of accompanying ERC-721 contract.
   */
  address public nftAddress;

  /**
   * @dev Stores bool representing status of sale. False by default.
   */
  bool public saleLive;

  /** FUNCTIONS */

  constructor(address _nftAddress) {
    nftAddress = _nftAddress;
  }

  function name() public pure returns (string memory) {
    return "Depressed OG Club Sale";
  }

  function transferOwnership(address newOwner) override public onlyOwner {
    super.transferOwnership(newOwner);
  }

  /**
   * @dev Mints new token of specified type.
   * @param _quantity uint256 Number of tokens to be minted
   * @param _toAddress address Of token recipient 
   */
  function mint(uint256 _quantity, address _toAddress) public payable isLive {
    require(canMint(_quantity), "DepressedOGClubFactory: Unable to mint token");
    require(msg.value >= (_quantity * TOKEN_PRICE), "DepressedOGClubFactory: Insufficient funds");

    DepressedOGClub depressedOGClub = DepressedOGClub(nftAddress);
    for (uint256 i=0; i<_quantity; i++) {
      depressedOGClub.mintTo(_toAddress);
    }
  }

  /**
   * @dev Runs checks before minting new token.
   * @param _quantity uint256 Number of tokens to be minted
   * @return bool Validity of mint
   */
  function canMint(uint256 _quantity) public view returns (bool) {
    if (_quantity > MAX_PER_ORDER || _quantity == 0) {
      return false;
    }

    DepressedOGClub depressedOGClub = DepressedOGClub(nftAddress);
    uint256 totalSupply = depressedOGClub.totalSupply();

    return totalSupply <= (MAX_SUPPLY - _quantity);
  }

  /**
   * @dev Toggle status of sale. Only callable by owner.
   */
  function toggleSale() public onlyOwner {
    if (saleLive) {
      saleLive = false;
    } else {
      saleLive = true;
    }
  }

  /**
   * @dev Withdraw funds from contract. Only callable by owner.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }
}
