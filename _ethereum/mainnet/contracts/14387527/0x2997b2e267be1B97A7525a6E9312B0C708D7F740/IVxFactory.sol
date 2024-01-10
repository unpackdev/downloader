// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract IVxFactory is Ownable, ReentrancyGuard, ERC721Enumerable {
    event Redeem(address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 indexed tokenId, uint256 indexed ivxId);

    string private baseURIextended;

    bool public dropActive = false;

    uint256 public maxSupply = 222;
    uint256 public priceInWei = 0.24 ether;
    uint256 private creatorCount = 5;

    mapping(uint256 => address) public tokenToCreator;
    mapping(uint256 => bool) public redeemed;
    mapping(address => uint256) public creatorToIVxID;
    mapping(address => bool) public markets;

    modifier transferSafeguard(uint256 tokenId) {
        require(_msgSender() == ownerOf(tokenId) || !redeemed[tokenId] || markets[_msgSender()], 'Only the token owner can trade');
        _;
    }

    constructor(string memory _baseURIextended) ERC721('IVX', 'IVX') {
        baseURIextended = _baseURIextended;
        creatorToIVxID[_msgSender()] = 4;
    }

    function mint() external payable nonReentrant {
        uint256 ts = totalSupply();
        require(msg.value == priceInWei, 'IVX: Insufficient funds');
        require(dropActive || _msgSender() == owner(), 'Drop is not active');
        require(ts < maxSupply, 'Drop is sold out');

        uint256 id = creatorToIVxID[_msgSender()];
        if (id == 0) {
            creatorToIVxID[_msgSender()] = creatorCount;
            id = creatorCount;
            creatorCount++;
        }

        tokenToCreator[ts] = _msgSender();

        _mint(_msgSender(), ts);

        emit Mint(_msgSender(), ts, id);
    }

    // caution: once redeemed it can no longer be traded on secondary markets
    function redeem(uint256 tokenId) external {
        require(_msgSender() == ownerOf(tokenId), 'You are not the owner');
        require(!redeemed[tokenId], 'Token was already redeeemd');

        redeemed[tokenId] = true;

        emit Redeem(_msgSender(), tokenId);
    }

    // updating state
    function setBaseURI(string memory _baseURIextended) external onlyOwner {
        baseURIextended = _baseURIextended;
    }

    function toggleDropActive() external onlyOwner {
        dropActive = !dropActive;
    }

    function updatePrice(uint256 _priceInWei) external onlyOwner {
        priceInWei = _priceInWei;
    }

    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function updateMarket(address _marketAddress) external onlyOwner {
        markets[_marketAddress] = !markets[_marketAddress];
    }

    function withdrawBalance() external onlyOwner nonReentrant {
        (bool success, ) = _msgSender().call{ value: address(this).balance }('');
        require(success, 'Transfer failed.');
    }

    /** OVERRIDES **/
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURIextended;
    }

    // if you trade between yourself you are responsible for the physical good
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override transferSafeguard(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override transferSafeguard(tokenId) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override transferSafeguard(tokenId) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }
}
