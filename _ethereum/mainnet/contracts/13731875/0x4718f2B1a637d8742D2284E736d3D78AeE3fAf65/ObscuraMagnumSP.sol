// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.0 <0.9.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ObscuraMagnumSeasonPass is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    Counters.Counter private reservedTokenIds;
    string private _baseURIextended;

    uint256 private constant MAX_TOKENS = 55;
    uint256 private constant PLATFORM_RESERVE_AMOUNT = 5;
    uint256 private constant MAX_PUBLIC_TOKENS = MAX_TOKENS - PLATFORM_RESERVE_AMOUNT;
    uint256 private constant MINT_PRICE = 2.80 ether;
    uint256 private constant MAX_PER_ADDRESS = 5;

    address payable treasury;
    bool public isPublicSaleActive = false;

    constructor() ERC721("ObscuraMagnumSeasonPass", "ObscuraMagnumSP") {
        treasury = payable(0xb94404C28FeAA59f8A3939d53E6b2901266Fa529);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function mint(uint count) external payable {
        require(isPublicSaleActive, "Public sale is not open");
        require(count > 0 && count <= MAX_PER_ADDRESS, "Invalid max count");
        require(tokenIds.current() + count <= MAX_PUBLIC_TOKENS, "All tokens have been minted");
        require(count * MINT_PRICE == msg.value, "Incorrect amount of ether sent");

        for (uint256 i = 0; i < count; i++) {
            tokenIds.increment();
            uint256 tokenId = tokenIds.current();
            _safeMint(msg.sender, tokenId);
        }
    }

    function platformMint(uint256 count) public onlyOwner {
        require(reservedTokenIds.current() + count <= PLATFORM_RESERVE_AMOUNT, "All reserved tokens have been minted");

        for (uint256 i = 0; i < count; i++) {
            reservedTokenIds.increment();
            uint256 tokenId = reservedTokenIds.current();
            _safeMint(treasury, MAX_PUBLIC_TOKENS + tokenId);
        }
    }

    function withdraw() public {
        uint256 balance = address(this).balance;
        Address.sendValue(treasury, balance);
    }

    function changeTreasuryAddress(address newTreasuryAddress) public onlyOwner {
        treasury = payable(newTreasuryAddress);
    }

    function setPublicSaleState(bool newState) public onlyOwner {
        isPublicSaleActive = newState;
    }
}
