// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract FrahmEntropy is ERC721A, Ownable, ReentrancyGuard {

  uint256 public constant MAX_MINTS_10 = 10;
  uint256 public constant MINT_PRICE_3 = 0.08 ether;
  uint256 public constant MINT_PRICE_10 = 0.04 ether;
  uint256 public constant MINT_PRICE_OE = 0.01 ether;
  uint256 public constant D_MINT_PRICE_OE = 0.0006 ether;

  uint256 private mint_1_count = 0;
  uint256 private mint_2_count = 0;
  uint256 private mint_3_count = 0;
  uint256 private mint_4_count = 0;
  uint256 private mint_5_count = 0;
  uint256 private mint_6_count = 0;
  uint256 private mint_7_count = 0;
  uint256 private mint_8_count = 0;
  uint256 private mint_9_count = 0;
  uint256 private mint_10_count = 0;

  string private _baseTokenURI = 'https://api.frahm.art/drops/2/metadata/';

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  constructor() ERC721A("Frahm Entropy Collection", "FRAHMEN") {}

  // 1 - 1:1
  function mint1() external payable callerIsUser {
    require(mint_1_count == 0, "can only mint 1 maximum");
    _safeMint(msg.sender, 1);
    mint_1_count += 1;
    refundIfOver(0.15 ether);
  }

  // 2 - 3:3
  function mint2(uint256 quantity) external payable callerIsUser {
    require(quantity <= 3, "can only mint 3 maximum");
    require(mint_2_count + quantity <= 3, "reached max supply of edition");
    _safeMint(msg.sender, quantity);
    mint_2_count += quantity;
    refundIfOver(quantity * MINT_PRICE_3);
  }

  // 3 - 3:3
  function mint3(uint256 quantity) external payable callerIsUser {
    require(quantity <= 3, "can only mint 3 maximum");
    require(mint_3_count + quantity <= 3, "reached max supply of edition");
    _safeMint(msg.sender, quantity);
    mint_3_count += quantity;
    refundIfOver(quantity * MINT_PRICE_3);
  }

  // 4 - 10:10
  function mint4(uint256 quantity) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    require(mint_4_count + quantity <= 10, "reached max supply of edition");
    _safeMint(msg.sender, quantity);
    mint_4_count += quantity;
    refundIfOver(quantity * MINT_PRICE_10);
  }

  // 5 - 10:10
  function mint5(uint256 quantity) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    require(mint_5_count + quantity <= 10, "reached max supply of edition");
    _safeMint(msg.sender, quantity);
    mint_5_count += quantity;
    refundIfOver(quantity * MINT_PRICE_10);
  }

  // 6 - 10:10
  function mint6(uint256 quantity) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    require(mint_6_count + quantity <= 10, "reached max supply of edition");
    _safeMint(msg.sender, quantity);
    mint_6_count += quantity;
    refundIfOver(quantity * MINT_PRICE_10);
  }

  // 7 - OE - No discounts
  function mint7(uint256 quantity) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    _safeMint(msg.sender, quantity);
    refundIfOver(quantity * MINT_PRICE_OE);
  }

  // 8 - OE
  function mint8(uint256 quantity, bool discount) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    _safeMint(msg.sender, quantity);
    if (discount) {
      refundIfOver(quantity * D_MINT_PRICE_OE);
    } else {
      refundIfOver(quantity * MINT_PRICE_OE);
    }
  }

  // 9 - OE
  function mint9(uint256 quantity, bool discount) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    _safeMint(msg.sender, quantity);
    if (discount) {
      refundIfOver(quantity * D_MINT_PRICE_OE);
    } else {
      refundIfOver(quantity * MINT_PRICE_OE);
    }
  }

  // 10 - OE
  function mint10(uint256 quantity, bool discount) external payable callerIsUser {
    require(quantity <= 10, "can only mint 10 maximum");
    _safeMint(msg.sender, quantity);
    if (discount) {
      refundIfOver(quantity * D_MINT_PRICE_OE);
    } else {
      refundIfOver(quantity * MINT_PRICE_OE);
    }
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "need to send more ETH");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success,) = msg.sender.call{value : address(this).balance}("");
    require(success, "Transfer failed.");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
}