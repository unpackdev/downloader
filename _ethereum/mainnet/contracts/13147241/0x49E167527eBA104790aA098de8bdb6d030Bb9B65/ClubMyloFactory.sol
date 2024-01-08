// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IFactoryERC721.sol";
import "./ClubMylo.sol";

contract ClubMyloFactory is FactoryERC721, Ownable {
  /** STORAGE */

  using SafeMath for uint256;
  using Strings for string;
  using Address for address payable;

  address public nftAddress;

  /**
   * @dev Stores option keys used to determine which token to mint.
   */
  uint256 constant NUM_OPTIONS = 4;
  uint256 constant GOLD = 0;
  uint256 constant MYLO = 1;
  uint256 constant RAFO = 2;
  uint256 constant BREDO = 3;

  /**
   * @dev Stores max number of tokens per token type.
   */
  uint256[4] private MAXES = [
    10,   // 0
    990,  // 1
    3000, // 2
    6000  // 3
  ];

  /**
   * @dev Stores prices for each token type in Wei.
   */
  uint256[4] private PRICES = [
    1000000000000000000,  // 0 (Gold) - 1 Ether
    150000000000000000,   // 1 (Mylo) - 0.15 Ether
    100000000000000000,   // 2 (Rafo) - 0.1 Ether
    70000000000000000     // 3 (Bredo) - 0.07 Ether
  ];

  /**
   * @dev Stores current tokenId of each token type. 
   */
  uint256[4] private _currentIds = [
    0,    // 0 (Gold)
    10,   // 1 (Mylo)
    1000, // 2 (Rafo)
    4000  // 3 (Bredo)
  ];

  /**
   * @dev Stores total number of tokens for each token type.
   */
  uint256[4] totals;  // 0,1,2,3

  /** FUNCTIONS */

  constructor(address _nftAddress) {
    nftAddress = _nftAddress;
  }

  function name() override external pure returns (string memory) {
    return "Club Mylo Sale";
  }

  function symbol() override external pure returns (string memory) {
    return "CMS";
  }

  function supportsFactoryInterface() override public pure returns (bool) {
    return true;
  }

  function numOptions() override public pure returns (uint256) {
    return NUM_OPTIONS;
  }

  function transferOwnership(address newOwner) override public onlyOwner {
    super.transferOwnership(newOwner);
  }

  /**
   * @dev Mints new token of specified type.
   * @param _optionId uint256 Id of token type requested
   * @param _toAddress address Of token recipient 
   */
  function mint(uint256 _optionId, address _toAddress) public override payable {
    require(canMint(_optionId), "ClubMyloFactory: Unable to mint token");
    require(msg.value >= PRICES[_optionId], "ClubMyloFactory: Insufficient funds");

    ClubMylo clubMylo = ClubMylo(nftAddress);

    uint256 newTokenId = _getNextTokenId(_optionId);
    clubMylo.mintTo(_toAddress, newTokenId);
    _incrementTokenId(_optionId);
    _incrementTotal(_optionId);
  }

  /**
   * @dev Runs checks before minting new token.
   * @param _optionId uint256 Id of token type specified
   * @return bool Validity of mint
   */
  function canMint(uint256 _optionId) public view override returns (bool) {
    if (_optionId >= NUM_OPTIONS) {
      return false;
    }

    return totals[_optionId] < MAXES[_optionId];
  }

  /**
   * @dev Withdraw highest bid from smart-contract. Only callable
   *  from owner's Ethereum address and once auction is not active.
   */
  function withdraw() public onlyOwner {
    payable(msg.sender).sendValue(address(this).balance);
  }

  /**
   * @dev Calculates the next tokenId.
   * @param _optionId uint256 Id of token type required
   * @return uint256 Next tokenId
   */
  function _getNextTokenId(uint256 _optionId) private view returns (uint256) {
    return _currentIds[_optionId].add(1);
  }

  /**
   * @dev Increments the current tokenId.
   * @param _optionId uint256 Id of token type required
   */
  function _incrementTokenId(uint256 _optionId) private {
    _currentIds[_optionId]++;
  }

  /**
   * @dev Increments the token total.
   * @param _optionId uint256 Id of token type required
   */
  function _incrementTotal(uint256 _optionId) private {
    totals[_optionId]++;
  }
}