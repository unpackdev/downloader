/**
________                         ________                                ________   __
\______ \____________     ____   \_____  \  __ __   ____   ____   ____   \______ \ |__|__  _______    ______
 |    |  \_  __ \__  \   / ___\   /  / \  \|  |  \_/ __ \_/ __ \ /    \   |    |  \|  \  \/ /\__  \  /  ___/
 |    `   \  | \// __ \_/ /_/  > /   \_/.  \  |  /\  ___/\  ___/|   |  \  |    `   \  |\   /  / __ \_\___ \
/_______  /__|  (____  /\___  /  \_____\ \_/____/  \___  >\___  >___|  / /_______  /__| \_/  (____  /____  >
        \/           \//_____/          \__>           \/     \/     \/          \/               \/     \/
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract DragQueenDivas is ERC721A, Ownable {
    using SafeMath for uint256;
    string private _baseTokenURI;
    uint256 public _mintPrice = 50000000000000000; // 0.05 ETH
    uint256 public _discountMintPrice = 25000000000000000; // 0.025 ETH
    uint256 public _maxSupply = 1000;
    uint256 public _maxMintAmount = 10;
    uint256 public _discountMaxMintAmount = 20;
    bool public _isPaused;

    event NewDragQueenDivasNFTMinted(address sender, uint256 mintAmount);

    constructor(string memory baseTokenURI) ERC721A ("Drag Queen Divas", "DIVA")
    {
        setBaseURI(baseTokenURI);
        setIsPaused(true);
    }

    function mint(address to, uint256 mintAmount) public payable {
        require(!_isPaused, "Minting is currently paused!");
        require(mintAmount > 0, "Mint amount must be bigger than zero!");
        require(totalSupply() + mintAmount <= _maxSupply, "Sold Out! The maximum amount of NFTs have already been reached!");

        bool hasDiscount = (super.balanceOf(msg.sender) >= 10);
        uint256 currentMaxMintAmount = (hasDiscount) ? _discountMaxMintAmount : _maxMintAmount;

        require(mintAmount <= currentMaxMintAmount, "Mint amount limit exceeded!");

        if (msg.sender != owner() && totalSupply() >= 100) {
            uint256 currentMintPrice = (hasDiscount) ? _discountMintPrice : _mintPrice;
            require(msg.value >= currentMintPrice * mintAmount, "Not enough ETH sent; check minting price!");
        }

        _safeMint(to, mintAmount);

        emit NewDragQueenDivasNFTMinted(to, mintAmount);
    }

    // Overrides
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function renounceOwnership() public pure override {
        revert("Can't renouce ownership of this smart contract.");
    }

    // Only Owner Functions
    function setBaseURI(string memory newBaseTokenURI) public onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function setMintPrice(uint256 newMintPrice) public onlyOwner {
        _mintPrice = newMintPrice;
    }

    function setDiscountMintPrice(uint256 newDiscountMintPrice) public onlyOwner {
        _discountMintPrice = newDiscountMintPrice;
    }

    function setMaxMintAmount(uint256 newMaxMintAmount) public onlyOwner {
        _maxMintAmount = newMaxMintAmount;
    }

    function setDiscountMaxMintAmount(uint256 newDiscountMaxMintAmount) public onlyOwner {
        _discountMaxMintAmount = newDiscountMaxMintAmount;
    }

    function setIsPaused(bool state) public onlyOwner {
        _isPaused = state;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether left to withdraw");
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(address tokenContractAddress, uint256 amount) public onlyOwner {
        require(amount > 0, "Amount to withdraw must be greater than zero");
        IERC20 tokenContract = IERC20(tokenContractAddress);
        tokenContract.transfer(msg.sender, amount);
    }
}