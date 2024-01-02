// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract ShibaInuNFT is ERC721, ERC2981, Ownable {
    using Strings for uint256;

    string private baseURI;
    uint256 public cost = 0.014 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 5;
    uint256 public totalSupply = 0;
    uint256 public startTime;
    uint256 public endTime;
    bool public paused = false;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startTime,
        uint256 _endTime
    ) ERC721(_name, _symbol) Ownable() {
        baseURI = "ipfs://";
        startTime = _startTime;
        endTime = _endTime;
        _setDefaultRoyalty(msg.sender, 450);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    modifier hasStarted() {
        require(block.timestamp >= startTime, "Minting has not started yet");
        _;
    }

    modifier hasNotEnded() {
        require(block.timestamp <= endTime, "Minting has ended");
        _;
    }

    event Minted(address indexed to, uint256 indexed tokenId, uint256 amount);

    function mint(uint256 _mintAmount) public payable hasStarted hasNotEnded {
        address to = msg.sender;
        require(!paused, "Minting is paused");
        require(_mintAmount > 0, "Must mint at least one token");
        require(_mintAmount <= maxMintAmount, "Exceeds max mint amount");
        require(totalSupply + _mintAmount <= maxSupply, "Exceeds max supply");
        require(msg.value >= cost * _mintAmount, "Insufficient funds");

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(to, totalSupply + i);
            
            emit Minted(to, totalSupply + i, _mintAmount);
        }

        totalSupply += _mintAmount;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
    
    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }
    
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    
    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        startTime = _newStartTime;
    }

    function setEndTime(uint256 _newEndTime) public onlyOwner {
        endTime = _newEndTime;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}