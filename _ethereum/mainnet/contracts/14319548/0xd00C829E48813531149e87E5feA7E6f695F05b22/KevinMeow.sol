// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

contract KevinMeow is ERC721Enum {
  using Strings for uint256;

  uint256 public constant SUPPLY = 555;
  uint256 public constant MAX_MINT_PER_TX = 1;
  uint256 public constant MAX_MINT_PER_WALLET = 2;

  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("KevinMeow", "KVM") {
    owner = msg.sender;
  }

  modifier mintOpen() {
    require(!pauseMint, "mint paused");
    _;
  }

  modifier onlyOwner() {
    _onlyOwner();
    _;
  }

  /** INTERNAL */ 

  function _onlyOwner() private view {
    require(msg.sender == owner, "onlyOwner");
  }

  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  /** Mint KevinMeow */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    uint256 buyerTokenCount = balanceOf(msg.sender);
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max1perTX"
    );
    require(
      amountPurchase + buyerTokenCount <= MAX_MINT_PER_WALLET,"Max2perWallet"
    );
    require(
      currentSupply + amountPurchase <= SUPPLY,
      "soldout"
    );
    for (uint8 i; i < amountPurchase; i++) {
      _safeMint(msg.sender, currentSupply + i);
    }
  }
  
  /** Get tokenURI */

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent meow");

    string memory currentBaseURI = _baseURI();

    return (
      bytes(currentBaseURI).length > 0
        ? string(
          abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)
        )
        : ""
    );
  }

  /** ADMIN SetPauseMint*/

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    pauseMint = _setPauseMint;
  }

  /** ADMIN SetBaseURI*/

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  /** ADMIN Withdraw*/

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}
