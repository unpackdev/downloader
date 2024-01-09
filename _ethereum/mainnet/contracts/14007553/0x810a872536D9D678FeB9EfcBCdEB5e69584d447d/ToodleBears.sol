// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enum.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./PaymentSplitter.sol";
import "./ReentrancyGuard.sol";

contract ToodleBears is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
    using Strings for uint256;

    string public baseURI;

    // sale settings
    uint256 public cost = 0.015 ether;
    uint256 public maxSupply = 8888;
    uint256 public freeMint = 1000;
    uint256 public maxMintPerTx = 20;
    uint256 public maxMintPerWallet = 200;
    bool public status = false;

    mapping(address => uint256) public minted;

    // share settings
    address[] private addressList = [
        0x54E0d5C4a6303203D698205737a1C433f49Ca285,
        0x50FF8fe56aB2e17Fd951F4352757EDC569a96E75,
        0xc417cb91aF4dE1f83cF64DB5176f7eBFb027A94b,
        0x98B3b486756B61d5AF95Da07bEDFcD603224FA32
    ];
    uint[] private shareList = [39, 39, 14, 8];

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721P(_name, _symbol) PaymentSplitter(addressList, shareList){
        setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI;
    }

    // public minting
    function mint(uint256 _mintAmount) public payable nonReentrant {
        uint256 s = totalSupply();

        require(status, "Off");
        require(_mintAmount > 0, "Duh");
        require(_mintAmount <= maxMintPerTx, "Too many");
        require(_mintAmount + minted[msg.sender] <= maxMintPerWallet, "Too many");
        require(s + _mintAmount <= maxSupply, "Sorry");

        if (_mintAmount <= freeMint) {
            freeMint -= _mintAmount;
        } else {
            require(msg.value >= cost * (_mintAmount - freeMint), "Insufficient");
            freeMint = 0;
        }

        for (uint256 i = 0; i < _mintAmount; ++i) {
            _safeMint(msg.sender, s + i, "");
        }

        minted[msg.sender] += _mintAmount;

        delete s;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setMaxMintPerTx(uint256 _newMaxMintPerTx) public onlyOwner {
        maxMintPerTx = _newMaxMintPerTx;
    }

    function setMaxMintPerWallet(uint256 _newMaxMintPerWallet) public onlyOwner {
        maxMintPerWallet = _newMaxMintPerWallet;
    }

    function setFreeMint(uint256 _newFreeMint) public onlyOwner {
        freeMint = _newFreeMint;
    }

    function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        maxSupply = _newMaxSupply;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSaleStatus(bool _status) public onlyOwner {
        status = _status;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}