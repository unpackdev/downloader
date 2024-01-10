//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Address.sol";
import "./ERC721A.sol";

error SaleIsNotStarted();
error ExceedTransactionLimit();
error ExceedMaxSupply();
error InsufficientFunds();

contract KevinDaKing is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public immutable _price;
    uint256 public immutable _maxSupply;
    uint256 public immutable _transactionLimit;

    string public _baseURIPrefix;
    bool public _saleStarted;

    constructor(
        uint256 price,
        uint256 maxSupply,
        uint256 transactionLimit
    ) ERC721A("KevinDaKing", "KDK") {
        _price = price;
        _maxSupply = maxSupply;
        _transactionLimit = transactionLimit;

        _baseURIPrefix = "https://metadata.kevindaking.com/json/";
    }

    function mintKevin(uint256 amount) external payable {
        if (!_saleStarted) revert SaleIsNotStarted();
        if (amount + totalSupply() > _maxSupply) revert ExceedMaxSupply();
        if (amount * _price != msg.value) revert InsufficientFunds();
        if (amount > _transactionLimit) revert ExceedTransactionLimit();

        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(_baseURIPrefix, tokenId.toString(), ".json"));
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseURIPrefix = baseURI;
    }

    function flipSaleState() external onlyOwner {
        _saleStarted = !_saleStarted;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(msg.sender), address(this).balance);
    }
}
