// SDPX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./PaymentSplitter.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

contract AfterLife is Ownable, ERC721A, PaymentSplitter, ReentrancyGuard {
    using ECDSA for bytes32;

    string public baseURI;

    uint public maxSupply = 1100;
    uint public reservedTokens = 101;
    uint public publicPrice = 0.075 ether;
    uint public wlPrice = 0.07 ether;

    uint public walletMax = 5;
    uint public wlMax = 2;

    bool public wlSale = false;
    bool public publicSale = false;

    address private _wlSigner;

    uint[] private _shares = [8, 3, 10,5,3,20,51];
    address[] private _shareholders = [
        0x9C56c795Ef3aa4419BaBBBf61c7ba016a0D625F3,
        0xEe8dA9412e001ECc5ED131826b45864C115B6AC6,
        0xD87b1E3F99B4e389B35f47eE4539224d4cc30fE5,
        0xFD3B74C74fE08A6Bc39FEcE3DEF182008c270c5d,
        0x7D781E9F4eE9Ed16319526e864Ef52A7c38131C0,
        0x661dD81A52f1ecA83dd9A0e49423eA1D25c46aC9,
        0x90c12D47018d7957896601A716B8fF5f77391067
    ];

    mapping(address => uint) private _mintedPublic;
    mapping(address => uint) private _mintedWl;

    constructor(string memory _uri)
    ERC721A("AfterLife", "AL")
    PaymentSplitter(_shareholders, _shares) {
        baseURI = _uri;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender,"AfterLife: Only EOA can mint!");
        _;
    }

    modifier enoughSupply(uint256 _amount) {
        require(totalSupply() + _amount <= maxSupply - reservedTokens, "AfterLife: Minting would exceed max supply!");
        _;
    }

    function isAllowedToMint(bytes memory _signature) public view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(_signature) == _wlSigner;
    }

    function mint(uint _amount) external payable enoughSupply(_amount) onlyEOA() nonReentrant {
        require(publicSale, "AfterLife: Public sale isn't active at the moment!");
        require(msg.value == publicPrice *_amount, "AfterLife: Not enough ETH!");
        require(_mintedPublic[msg.sender] + _amount <= walletMax, "AfterLife: You can't mint more than 5 tokens!");
        _mintedPublic[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function whitelistMint(uint _amount, bytes memory _signature) external payable enoughSupply(_amount) onlyEOA nonReentrant {
        require(wlSale, "AfterLife: WL sale isn't active at the moment!");
        require(msg.value == wlPrice * _amount, "AfterLife: Not enough ETH!");
        require(isAllowedToMint(_signature), "AfterLife: You aren't whitelisted for presale!");
        require(_mintedWl[msg.sender] + _amount <= wlMax, "AfterLife: You can't mint more than 2 tokens!");
        _mintedWl[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }

    function reserveMint(uint _amount, address _to) external onlyOwner() {
        require(maxSupply >= totalSupply() + _amount, "AfterLife: Minting would exceed max supply!");
        _safeMint(_to, _amount);
        reservedTokens -=_amount;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setReservedTokens(uint _reservedTokens) external onlyOwner {
        reservedTokens = _reservedTokens;
    }

    function setPublicPrice(uint _price) external onlyOwner {
        publicPrice = _price;
    }

    function setWlPrice(uint _price) external onlyOwner {
        wlPrice = _price;
    }

    function setWalletMax(uint _walletMax) external onlyOwner {
        walletMax = _walletMax;
    }

    function setWlMax(uint _wlMax) external onlyOwner {
        wlMax = _wlMax;
    }

    function setBaseURI(string memory _newbaseURI) external onlyOwner {
        baseURI = _newbaseURI;
    }

    function setWlSale() external onlyOwner {
        wlSale = !wlSale;
    }

    function setPublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function setWlSigner(address _signer) external onlyOwner {
        _wlSigner = _signer;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdrawAll() external onlyOwner {
        for (uint256 sh = 0; sh < _shareholders.length; sh++) {
            address payable wallet = payable(_shareholders[sh]);
            release(wallet);
        }
    }

    function getMintedPublic(address _address) public view returns (uint) {
        return _mintedPublic[_address];
    }

    function getMintedWL(address _address) public view returns (uint) {
        return _mintedWl[_address];
    }
}