// SPDX-License-Identifier: UNLICENSED

/*

...                                                                                                           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NotTrippinApeTribe is ERC721A, Ownable {
    bool public SALE_ACTIVE;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public MAX_TXN = 8;
    uint256 public MAX_TXN_FREE = 3;
    uint256 public constant FREE_SUPPLY = 2000;
    uint256 public constant PAID_SUPPLY = 3000;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;

    constructor() ERC721A("Not Trippin Ape Tribe", "NOTAT", MAX_TXN) {
        SALE_ACTIVE = false;
        price = 0.0066 ether;
    }

    function OWNER_RESERVE(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function MINT(uint256 count) external payable {
        require(SALE_ACTIVE, "Sale must be active.");
        require(totalSupply() + count <= MAX_SUPPLY, "Exceed max supply");
        require(count <= MAX_TXN, "Cant mint more than 8");
        require(
            (price * count) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, count);
    }

    function FREE_MINT(uint256 count) external payable {
        require(SALE_ACTIVE, "Sale must be active.");
        require(totalSupply() + count <= FREE_SUPPLY, "Exceed max supply");
        require(count <= MAX_TXN_FREE, "Cant mint more than 3");

        _safeMint(msg.sender, count);
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        SALE_ACTIVE = !(SALE_ACTIVE);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }
    function setMaxTxnFree(uint256 _maxTxnFree) external onlyOwner {
        MAX_TXN_FREE = _maxTxnFree;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

}