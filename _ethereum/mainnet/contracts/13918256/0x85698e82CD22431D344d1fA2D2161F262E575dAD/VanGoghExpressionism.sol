pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract VanGoghExpressionism is ERC721Enumerable, Ownable {
    using Strings for uint256;
    address private TREASURY_WALLET = 0x7772005Ad71b1BC6c1E25B3a82A400B0a8FC7680;
    string private _tokenBaseURI = "";

    constructor(
        string memory _name,
        string memory _symbol) ERC721(_name, _symbol) {}

    uint256 public constant GIFT = 20;
    uint256 public constant PUBLIC = 1000;
    uint256 public constant MAX_SUPPLY_LIMIT = GIFT + PUBLIC;
    uint256 public constant LAUNCH_PRICE = 0.08 ether;

    uint256 public giftedAmountMinted;
    uint256 public publicAmountMinted;
    uint256 public privateAmountMinted;

    bool public saleLive;

    function buy(uint256 tokenQuantity) external payable {
      require(saleLive, "SALE_CLOSED");
      require(totalSupply() < MAX_SUPPLY_LIMIT, "OUT_OF_STOCK");
      require(publicAmountMinted + tokenQuantity <= PUBLIC, "EXCEED_PUBLIC");
      require(LAUNCH_PRICE * tokenQuantity <= msg.value, "INSUFFICIENT_ETH");

      for (uint256 i = 0; i < tokenQuantity; i++) {
        publicAmountMinted++;
        _safeMint(msg.sender, totalSupply() + 1);
      }
        payable(TREASURY_WALLET).transfer(msg.value);
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            totalSupply() + receivers.length <= MAX_SUPPLY_LIMIT,
            "OUT_OF_STOCK"
        );
        require(giftedAmountMinted + receivers.length <= GIFT, "GIFTS_EMPTY");

        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmountMinted++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
}
