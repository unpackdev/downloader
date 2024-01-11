// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

contract FortitudeV1 is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeMath for uint256;

    // ===== Variables =====
    string public baseTokenURI;
    uint256 public mintPrice = 0.1 ether;
    uint256 public collectionSize = 1000;
    uint256 public maxItemsPerTx = 10;

    bool public publicMintPaused = true;

    address public marketingWalletAddress;
    address public devWalletAddress;
    address public ownerWalletAddress;

    // ===== Constructor =====
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address marketingWalletAddress_,
        address devWalletAddress_,
        address ownerWalletAddress_
    ) ERC721A(name_, symbol_) {
        baseTokenURI = baseTokenURI_;
        marketingWalletAddress = marketingWalletAddress_;
        devWalletAddress = devWalletAddress_;
        ownerWalletAddress = ownerWalletAddress_;
    }

    // ===== Modifier =====
    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender() {
        _onlySender();
        _;
    }

    // ===== Public mint =====
    function publicMint() external payable onlySender nonReentrant {
        require(!publicMintPaused, 'Public mint is paused');

        uint256 amount = _getMintAmount(msg.value);

        require(amount <= maxItemsPerTx, 'Minting amount exceeds allowance per tx');

        _mintWithoutValidation(msg.sender, amount);

        payable(marketingWalletAddress).transfer((msg.value.mul(10)).div(100));
        payable(devWalletAddress).transfer((msg.value.mul(10)).div(100));
        payable(ownerWalletAddress).transfer((msg.value.mul(80)).div(100));
    }

    // ===== Helper =====
    function _getMintAmount(uint256 value) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, 'Send a divisible amount of eth');

        uint256 amount = value / mintPrice;
        require(amount > 0, 'Amount to mint is 0');
        require((totalSupply() + amount) <= collectionSize, 'Sold out!');
        return amount;
    }

    function _mintWithoutValidation(address to, uint256 amount) internal {
        require((totalSupply() + amount) <= collectionSize, 'Sold out!');
        _safeMint(to, amount);
    }

    // ===== Setter (owner only) =====

    function updateMarketingWalletAddress(address marketingWalletAddress_) external onlyOwner {
        marketingWalletAddress = marketingWalletAddress_;
    }

    function updateDevWalletAddress(address devWalletAddress_) external onlyOwner {
        devWalletAddress = devWalletAddress_;
    }

    function updateOwnerWalletAddress(address ownerWalletAddress_) external onlyOwner {
        ownerWalletAddress = ownerWalletAddress_;
    }

    function setPublicMintPaused(bool _publicMintPaused) external onlyOwner {
        publicMintPaused = _publicMintPaused;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxItemsPerTx(uint256 _maxItemsPerTx) external onlyOwner {
        maxItemsPerTx = _maxItemsPerTx;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // ===== Withdraw to owner =====
    function withdrawAll() external onlyOwner onlySender nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'Failed to send ether');
    }

    // ===== View =====
    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function walletOfOwner(address address_) public view virtual returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply();
        for (uint256 i = 0; i < _loopThrough; i++) {
            bool _exists = _exists(i);
            if (_exists) {
                if (ownerOf(i) == address_) {
                    _tokens[_index] = i;
                    _index++;
                }
            } else if (!_exists && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
        }
        return _tokens;
    }
}