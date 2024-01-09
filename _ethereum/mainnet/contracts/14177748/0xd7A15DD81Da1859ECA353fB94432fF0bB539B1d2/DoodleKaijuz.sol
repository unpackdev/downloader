// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

contract DoodleKaijuz is ERC721Enum {
  using Strings for uint256;

  uint256 public constant SUPPLY = 3000;
  uint256 public constant MAX_MINT_PER_TX = 20; 

  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("DoodleKaijuz", "DKJ") {
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

  /** Mint DoodleKaijuz */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max20perTX"
    );
    require(
      currentSupply + amountPurchase <= SUPPLY,
      "alreadySoldout"
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

  /** ADMIN setPauseMint*/

  function setPauseMint(bool _setPauseMint) external onlyOwner {
    pauseMint = _setPauseMint;
  }

  /** ADMIN setBaseURI*/

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  /** ADMIN withdraw*/

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
