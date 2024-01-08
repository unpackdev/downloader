// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *  _____ _____  ________  ___ ___________  _____
 * |  _  \  _  ||  _  |  \/  ||  ___| ___ \/  ___|
 * | | | | | | || | | | .  . || |__ | |_/ /\ `--.
 * | | | | | | || | | | |\/| ||  __||    /  `--. \
 * | |/ /\ \_/ /\ \_/ / |  | || |___| |\ \ /\__/ /
 * |___/  \___/  \___/\_|  |_/\____/\_| \_|\____/
 */

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Doomers is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Contract to recieve ETH raised in sales
  address public _vault;

  // Amount of ETH required per mint
  uint256 public _price = .666 ether;

  // Reference to image and metadata storage
  string public _baseTokenURI;

  // Sets `_vault` and `_baseTokenURI` on deployment
  constructor(address vault, string memory baseURI) ERC721("Doomers", "DOOMERS") {
    setVault(vault);
    setBaseURI(baseURI);
  }

  // Sets `_baseTokenURI` to be returned by `_baseURI()`
  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  // Sets `_price` to be used in `mint()` (called on deployment)
  function setPrice(uint256 price) public onlyOwner {
    _price = price;
  }

  // Sets `_vault` to recieve ETH from sales and used within `withdraw()`
  function setVault(address vault) public onlyOwner {
    _vault = vault;
  }

  // Override of `_baseURI()` that returns `baseTokenURI`
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  // Minting function used in the public sale
  function mint() public payable {
    uint256 supply = totalSupply();

    require( msg.value >= _price, "YOU HAVE DIED.");
    require( supply < 667, "YOU HAVE DIED.");

    _safeMint(msg.sender, supply);
  }

  // Send balance of contract to address referenced in `_vault`
  function withdraw() public payable onlyOwner {
    uint256 amt = address(this).balance;
    require(payable(_vault).send(amt));
  }
}
