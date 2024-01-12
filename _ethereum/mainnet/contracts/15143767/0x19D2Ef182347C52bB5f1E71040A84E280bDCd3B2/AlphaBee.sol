// SPDX-License-Identifier: MIT
/// @title AlphaBee
pragma solidity ^0.8.4;

//  _____ _     _          _____
// |  _  | |___| |_ ___   | __  |___ ___
// |     | | . |   | .'|  | __ -| -_| -_|
// |__|__|_|  _|_|_|__,|  |_____|___|___|
//         |_|

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";

contract AlphaBeeToken is ERC721A, Ownable, ReentrancyGuard {
  uint public constant MAX_SUPPLY = 10000;
  uint public constant MAX_MINT_AMOUNT = 10;

  uint public price = 0.3 ether;
  uint public supporterPrice = 0.2 ether;
  bool public isPublicSaleActive = false;

  string private _contractURI;
  string private baseURI;

  constructor(
    string memory _initBaseURI,
    string memory _initContractURI) ERC721A('AlphaBee', 'ALPHABEE') {
    baseURI = _initBaseURI;
    _contractURI = _initContractURI;
  }

  /// Minting Region
  /// @notice Pause sale if active, make active if paused.
  function togglePublicSaleState() public onlyOwner {
    isPublicSaleActive = !isPublicSaleActive;
  }

  /// @notice returns whether public mint is sold out or not
  function isPublicMintSoldOut() view public returns (bool) {
    return totalSupply() >= MAX_SUPPLY;
  }

  /**
  * @notice Treasury mints by owner to be used for promotions and awards.
  * @param quantity the quanity of AlphaBee NFTs to mint.
  */
  function mintTreasury(uint quantity) public onlyOwner {
    uint currentTotalSupply = totalSupply();
    uint totalSupplyAfterMint = currentTotalSupply + quantity;

    /// @notice Treasure mints can't be more than max supply
    require(totalSupplyAfterMint <= MAX_SUPPLY, "AlphaBeeToken should not exceed total supply");
    _safeMint(msg.sender, quantity);
  }

  function mint(uint256 quantity, bool isSupporter) external payable {
    require(isPublicSaleActive, "Sale must be active");
    uint currentTotalSupply = totalSupply();
    require(currentTotalSupply + quantity <= MAX_SUPPLY, "AlphaBeeToken Not enough public mints remaining");
    require(quantity <= MAX_MINT_AMOUNT, 'AlphaBeeToken mint per txn amount exceeds maximum');
    uint mintPrice = isSupporter ? supporterPrice : price;
    require(msg.value > 0 && msg.value == quantity * mintPrice, "AlphaBeeToken Not enough value sent");
    _safeMint(msg.sender, quantity);
  }

  /// Contract Metadata Region
  /**
  * @notice sets the base URI
  * @param _newBaseURI is the address of the ipfs base uri
  */
  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal override view returns (string memory){
    return baseURI;
  }

  /**
  * @notice sets the contract uri
  * @param _newContractURI uri to the contract ipfs address
  */
  function setContractURI(string memory _newContractURI) external onlyOwner {
    _contractURI = _newContractURI;
  }

  function contractURI() external view returns (string memory){
    return _contractURI;
  }

  /**
  * @notice sets the price of the token
  * @param _priceInWei value in eth to set price to
  */
  function setPrice(uint256 _priceInWei) public onlyOwner {
    price = _priceInWei;
  }

  /**
  * @notice sets the price of the supporter discounted token cost
  * @param _priceInWei value in eth to set price to
  */
  function setSupporterPrice(uint256 _priceInWei) public onlyOwner {
    supporterPrice = _priceInWei;
  }

  /// @notice Sends balance of this contract to owner
  function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      require(balance > 0, "No balance to withdraw");

      (bool success, ) = payable(msg.sender).call{value: balance}("");
      require(success, "Failed to withdraw payment");
  }
}