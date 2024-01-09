// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "Strings.sol";
import "ERC721Enum.sol";

contract Azugirl is ERC721Enum {
  using Strings for uint256;

  uint256 public constant SUPPLY = 5000;
  uint256 public constant MAX_MINT_PER_TX = 20;
  uint256 public freeSupply = 555;
  uint256 public price = 0.02 ether;
  
  address private constant addressOne = 0xCBbAd148Dcd6017875ca193401e2E600478842AA
  ;
  address private constant addressTwo = 0xEA4206f47EF6B52038DAAFf8b8D4015F982e28f9
  ;
  
  bool public pauseMint = true;
  string public baseURI;
  string internal baseExtension = ".json";
  address public immutable owner;

  constructor() ERC721P("Azugirl", "AZG") {
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

  /** Mint NFT */ 

  function mint(uint16 amountPurchase) external payable mintOpen {
    uint256 currentSupply = totalSupply();
    require(
      amountPurchase <= MAX_MINT_PER_TX,
      "Max20perTX"
    );
    require(
      currentSupply + amountPurchase <= SUPPLY,
      "soldout"
    );
    if(currentSupply > freeSupply) {
      require(msg.value >= price * amountPurchase, "not enougth eth");
    }
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

  /** ADMIN SetFreeSupply*/

  function setFreeSupply(uint256 _freeSupply) external onlyOwner {
    freeSupply = _freeSupply;
  }

  /** ADMIN SetPrice*/

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  /** ADMIN withdraw*/

  function withdrawAll() external onlyOwner {
    uint256 balance = address(this).balance;
    require(balance > 0, "No money");
    _withdraw(addressOne, (balance * 32) / 100);
    _withdraw(addressTwo, (balance * 64) / 100);
    _withdraw(msg.sender, address(this).balance);
  }

  function _withdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{ value: _amount }("");
    require(success, "Transfer failed");
  }
}
