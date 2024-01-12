//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Pausable.sol";

error InvalidQuantity();
error ExceedsWalletLimit();
error SoldOut();
error WrongAmountSent();

contract Tapiocuz is ERC721A, Pausable, Ownable {
    uint256 public constant maxSupply = 5555;
    uint256 public mintPrice = .001 ether;
    uint256 public maxMintsPerTransaction = 30;
    uint256 public maxMintsPerWallet = 100;

    string private _tokenBaseURI;
    address private immutable _founder1;
    address private immutable _founder2;

    constructor(
        string memory tokenBaseURI_,
        address founder1_,
        address founder2_,
        uint256 quantity
    ) ERC721A("Tapiocuz", "Tapiocuz") {
        _tokenBaseURI = tokenBaseURI_;
        _founder1 = founder1_;
        _founder2 = founder2_;
        _mint(founder1_, quantity);
        _mint(founder2_, quantity);
        _pause();
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        if (quantity == 0 || quantity > maxMintsPerTransaction) revert InvalidQuantity();
        if (quantity + _numberMinted(msg.sender) > maxMintsPerWallet) revert ExceedsWalletLimit();
        if (quantity + _totalMinted() > maxSupply) revert SoldOut();

        uint256 totalCost = _numberMinted(msg.sender) == 0
            ? (quantity - 1) * mintPrice
            : quantity * mintPrice; 
        
        if (msg.value < totalCost) revert WrongAmountSent();

        _mint(msg.sender, quantity);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseURI;
    }

    /* ———————— Admin functions ———————— */

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintsPerTransaction(uint256 _maxMintsPerTransaction) external onlyOwner {
        maxMintsPerTransaction = _maxMintsPerTransaction;
    }

    function setMaxMintsPerWallet(uint256 _maxMintsPerWallet) external onlyOwner {
        maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setTokenBaseURI(string memory tokenBaseURI_) external onlyOwner {
        _tokenBaseURI = tokenBaseURI_;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        uint256 half = address(this).balance / 2;
        (bool withdrawal1, ) = _founder1.call{value: half}("");
        require(withdrawal1, "Withdrawal 1 failed");
        (bool withdrawal2, ) = _founder2.call{value: half}("");
        require(withdrawal2, "Withdrawal 2 failed");
    }

    receive() external payable {}
}
