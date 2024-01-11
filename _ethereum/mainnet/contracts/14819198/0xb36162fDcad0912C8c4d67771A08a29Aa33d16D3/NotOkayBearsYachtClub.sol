// SPDX-License-Identifier: UNLICENSED

/*

...                                                                                                           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract NotOkayBearsYachtClub is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;
    string public PROVENANCE;

    uint256 public MAX_TXN = 7;
    uint256 public MAX_TXN_FREE = 3;
    uint256 public constant FREE_SUPPLY = 2555;
    uint256 public constant PAID_SUPPLY = 3000;
    uint256 public constant MAX_SUPPLY = FREE_SUPPLY+PAID_SUPPLY;

    mapping(address => uint256) public freeMintWallets;

    constructor() ERC721A("Not Okay Bears Yacht Club", "NOBYC", MAX_TXN) {
        saleEnabled = false;
        price = 0.007 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }


    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
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

    function setProvenance(string memory _provenance) external onlyOwner {
        PROVENANCE = _provenance;
    }

    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 tokenCount) external payable {
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= MAX_TXN, "Cant mint more than 7");
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "Exceed max supply");
        require(
            (price * tokenCount) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, tokenCount);
    }

    function free_mint(uint256 tokenCount) external payable {
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + tokenCount <= FREE_SUPPLY, "Exceed max supply");
        require(tokenCount <= MAX_TXN_FREE, "Cant mint more than 3");
        require(tokenCount > 0, "Must mint at least 1 token");
        require((freeMintWallets[msg.sender] + tokenCount) <= 3, "Max minted for free!");

        freeMintWallets[msg.sender] += tokenCount;
        _safeMint(msg.sender, tokenCount);
    }
}