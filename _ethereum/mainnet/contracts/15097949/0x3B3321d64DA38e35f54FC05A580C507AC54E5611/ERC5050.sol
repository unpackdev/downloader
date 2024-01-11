// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract ERC5050 is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxPerTransaction = 10;
    uint256 public maxPerWallet = 40;
    uint256 public maxTotalSupply = 7000;
    uint256 public chanceFreeMintsAvailable = 3500;
    uint256 public freeMintsAvailable = 1500;
    uint256 public mintPrice = 0.005 ether;
    bool public isPublicLive = false;
    string public uriPrefix = "";
    mapping(address => uint256) public mintsPerWallet;

    constructor (string memory _uriPrefix) ERC721A ("CopeBullz", "CBullz") {
        setUri(_uriPrefix);
    }

    function mint(uint256 _amount) external payable nonReentrant {
        require(isPublicLive, "Sale not live");
        require(_amount > 0, "You must mint at least one");
        require(totalSupply() + _amount <= maxTotalSupply, "Exceeds total supply");
        require(_amount <= maxPerTransaction, "Exceeds max per transaction");
        require(mintsPerWallet[_msgSender()] + _amount <= maxPerWallet, "Exceeds max per wallet");

        // 1 guaranteed free per wallet
        uint256 pricedAmount = freeMintsAvailable > 0 && mintsPerWallet[_msgSender()] == 0
            ? _amount - 1
            : _amount;

        if (pricedAmount < _amount) {
            freeMintsAvailable = freeMintsAvailable - 1;
        }

        require(mintPrice * pricedAmount <= msg.value, "Not enough ETH sent for selected amount");

        uint256 refund = chanceFreeMintsAvailable > 0 && pricedAmount > 0 && isFreeMint()
            ? pricedAmount * mintPrice
            : 0;

        if (refund > 0) {
            chanceFreeMintsAvailable = chanceFreeMintsAvailable - pricedAmount;
        }

        // sends needed ETH back to minter
        payable(_msgSender()).transfer(refund);

        mintsPerWallet[_msgSender()] = mintsPerWallet[_msgSender()] + _amount;

        _safeMint(_msgSender(), _amount);
    }

    function isFreeMint() internal view returns (bool) {
        return (uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            _msgSender()
        ))) & 0xFFFF) % 2 == 0;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token unavailable.");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI,  _toString(tokenId), ".json"))
            : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function flipPublicSaleState() external onlyOwner {
        isPublicLive = !isPublicLive;
    }

    function setUri(string memory _newUri) public onlyOwner {
        uriPrefix = _newUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setFreeMintsAvailable(uint256 _freeMintsAvailable) external onlyOwner {
        freeMintsAvailable = _freeMintsAvailable;
    }

    function setChanceFreeMintsAvailable(uint256 _chanceFreeMintsAvailable) external onlyOwner {
        chanceFreeMintsAvailable = _chanceFreeMintsAvailable;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function ownerMint(uint256 _quantity) external onlyOwner {
        require(_quantity + totalSupply() <= maxTotalSupply, "Not_Enough_Supply.");
        _safeMint(_msgSender(), _quantity);
    }

    function withdraw() public onlyOwner nonReentrant {
        (bool success, ) = payable(owner()).call{value: address(this).balance}('');
        require(success, "Withdrawal_Failed.");
    }
}