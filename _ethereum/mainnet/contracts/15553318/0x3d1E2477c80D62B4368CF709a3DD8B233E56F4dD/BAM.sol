//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract BoredApeMerge is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;
    string public baseURI;

    uint256 public mintPrice = 0.003 ether;
    uint256 public maxSupply = 5555;
    uint256 public maxFreeMint = 4000; 
    uint256 public maxMintPerWallet = 10;
    uint256 public totalFreeMinted;

    bool public mintEnabled = false;

    mapping(address => bool) public mintedFree;

    constructor() ERC721A("Bored Ape Merge", "BAM") {}

    modifier mintCompliance(uint256 _quantity) {
        require(mintEnabled, "Mint not Live yet");
        require(_quantity >= 1, "Enter the correct quantity");
        require(_quantity + _numberMinted(msg.sender) <= maxMintPerWallet, "Mint limit exceeded");
        require(_quantity + totalSupply() <= maxSupply, "Sold Out!");
        _;
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns(uint256) {
        return 1;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "Invalid TokenId");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
    }

    function mint(uint256 _quantity) external payable mintCompliance(_quantity) {
        
        uint256 cost = mintPrice;

        if(!(mintedFree[msg.sender])) {
            if(_quantity + totalFreeMinted <= maxFreeMint) {
                if(_quantity > 1) {
                    require(msg.value >= (cost * _quantity) - cost, "Incorrect amount");
                } else {
                    require(msg.value >= 0 ether, "Incorrect amount");
                }
                totalFreeMinted += 1;
                mintedFree[msg.sender] = true;
            } else {
                require(msg.value >= cost * _quantity, "Incorrect amount");
            }
        } else {
            require(msg.value >= cost * _quantity, "Incorrect amount");
        }
        
        _safeMint(msg.sender, _quantity);
    }

    function teamMint(uint256 _quantity) external payable onlyOwner{
        require(_quantity + _numberMinted(msg.sender) <= 155, "limit exceeded");
        _safeMint(msg.sender, _quantity);
    }

    function setMintEnabled() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function setMaxMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet; 
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxFreeMint(uint256 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function withdrawETH() external onlyOwner nonReentrant {
        (bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
        require(sent, "Failed Transaction");
    }

    receive() external payable {}
    fallback() external payable {}
}