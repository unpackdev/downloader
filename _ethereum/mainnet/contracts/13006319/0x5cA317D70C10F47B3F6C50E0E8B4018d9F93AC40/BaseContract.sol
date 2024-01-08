// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract BaseContract is ERC721Enumerable, Ownable {

    uint public maxSupply;
    uint public maxPurchasable;
    uint public tokenPrice;
    bool public isSaleActive;
    string private baseURI;

    constructor (
        string memory name,
        string memory symbol,
        uint _maxSupply,
        uint _maxPurchasable,
        uint _tokenPrice
    ) ERC721(name, symbol) {
        maxSupply = _maxSupply;
        maxPurchasable = _maxPurchasable;
        tokenPrice = _tokenPrice;
    }

    // region setters and getters
    function startSale() public onlyOwner {
        isSaleActive = true;
    }

    function pauseSale() public onlyOwner {
        isSaleActive = false;
    }

    function setBaseUri(string memory _baseURIArg) external onlyOwner {
        baseURI = _baseURIArg;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // endregion


    // region mint
    function _beforeMint() internal virtual {}

    modifier maxSupplyCheck(uint amount) {
        require(totalSupply() < maxSupply, "All NFTs have been minted.");
        require(amount > 0, "You must mint at least one token.");
        require(totalSupply() + amount <= maxSupply, "The amount of tokens you are trying to mint exceeds the maxSupply.");
        _;
    }

    function reserveTokens(uint amount) external onlyOwner maxSupplyCheck(amount) {
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function giftTokens(address[] memory addresses) external onlyOwner maxSupplyCheck(addresses.length) {
        for (uint i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], totalSupply() + 1);
        }
    }

    function mint(uint amountToMint) external payable maxSupplyCheck(amountToMint) {
        require(isSaleActive, "This sale has not started.");
        require(amountToMint <= maxPurchasable, "You cannot mint such amount of tokens.");
        require(tokenPrice * amountToMint == msg.value, "Incorrect Ether value.");

        _beforeMint();

        for (uint i = 0; i < amountToMint; i++) {
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    // endregion

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(0xF50d29e58a4077030a806c8972F20b16aBfD4BA5).transfer(balance * 42 / 100);
        payable(0xaF7AD5541A59818b234c7b1c4893A7f3EDc5A04D).transfer(balance * 58 / 100);
    }

}