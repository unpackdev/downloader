// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

/*
  _____ _   _     ____        _ _            
 | ____| |_| |__ / ___| _   _(_) |_ ___  ___ 
 |  _| | __| '_ \\___ \| | | | | __/ _ \/ __|
 | |___| |_| | | |___) | |_| | | ||  __/\__ \
 |_____|\__|_| |_|____/ \__,_|_|\__\___||___/

  EthSuites.com / 2022 / V1.0
*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface FloorPlansRepo {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract FloorPlans is ERC721Enumerable, ReentrancyGuard, Ownable {
    string private baseURI;
    mapping (address => uint16) private _msgSenderMintCount;

    uint256 private constant _maxMintPerMsgSender = 5;
    uint256 public ownerLastMint = 0;
    uint256 public ownerMaxMint = 500;
    uint256 public lastMint = 500;
    uint256 public maxMint = 10000;
    uint256 public price = 0.08 ether;
    bool public isMintOpen = true;
    address internal floorPlansRepoAddress;

    event Minted(address indexed account, uint256 tokenId);
    event SetBaseURI(string baseURI);
    event SetMaxMint(uint256 maxMint);
    event SetOwnerMaxMint(uint256 ownerMaxMint);
    event SetFloorPlansRepoAddress(address floorPlansRepoAddress);
    event SetPrice(uint256 price);
    

    constructor(string memory __baseURI) ERC721("EthSuites", "ETHSUITES") Ownable() {
        baseURI = __baseURI;
    }

    function mint() public payable nonReentrant {
        require(isMintOpen, "Sorry the mint is not currenlty open.");
        require(lastMint < maxMint, "Token sold out! Please dont mint anymore.");
        require(msg.value >= price, "Insufficient ETH, please adjust the price.");
        require(_msgSenderMintCount[msg.sender] + 1 <= _maxMintPerMsgSender, "Max 5 mint allowed per wallet."); 

        uint256 tokenId = lastMint++;
        _msgSenderMintCount[msg.sender]++;
        _safeMint(_msgSender(), tokenId);
        emit Minted(_msgSender(), tokenId);
    }

    function mintMany(uint8 count) public payable nonReentrant{
        require(isMintOpen, "Sorry the mint is not currenlty open.");
        require(lastMint < maxMint, "Token sold out! Please dont mint anymore.");
        require(count <= _maxMintPerMsgSender, "Max count allowed is 5, please adjust the count");
        require(lastMint + count <= maxMint, "Not enough token available for the requested count.");
        require(price * count <= msg.value, "Insufficient ETH, please adjust the price.");

        require(_msgSenderMintCount[msg.sender] + count <= _maxMintPerMsgSender, "Max 5 mint allowed per wallet."); 

        for (uint8 i = 0; i < count; i++) {
            uint256 tokenId = lastMint++;
            _msgSenderMintCount[msg.sender]++;
            _safeMint(_msgSender(), tokenId);
            emit Minted(_msgSender(), tokenId);
        }
    }

    function ownerMintMany(uint8 count) public payable onlyOwner nonReentrant{
        for (uint8 i = 0; i < count; i++) {
            uint256 tokenId = lastMint++;
            _msgSenderMintCount[msg.sender]++;
            _safeMint(_msgSender(), tokenId);
            emit Minted(_msgSender(), tokenId);
        }
    }

    function ownerReservedMint(uint8 count) public payable onlyOwner nonReentrant{
        require(ownerLastMint < ownerMaxMint, "No more reserved token left for the owner.");
        require(ownerLastMint + count < ownerMaxMint, "Not enough token available for the requested count.");

        for (uint8 i = 0; i < count; i++) {
            uint256 tokenId = ownerLastMint++;
            _safeMint(_msgSender(), tokenId);
            emit Minted(_msgSender(), tokenId);
        }
    }

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
        emit SetMaxMint(maxMint);
    }

    function setOwnerMaxMint(uint256 _ownerMaxMint) external onlyOwner {
        ownerMaxMint = _ownerMaxMint;
        emit SetOwnerMaxMint(ownerMaxMint);
    }

    function getMsgSenderMintCount(address _address) external view onlyOwner returns(uint256 _count) {
        return _msgSenderMintCount[_address];
    }

    function withdraw(address payable recipient, uint256 amount) public nonReentrant onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance.");
        (bool succeed,) = recipient.call{value: amount}("");
        require(succeed, "Withdraw failed.");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function toggleMint() external onlyOwner {
        isMintOpen = !isMintOpen;
    }

    function isValid(uint256 tokenId) internal view {
        require(tokenId > 0 && tokenId <= maxMint, "Invalid Token ID.");
        require(_exists(tokenId), "Token is not minted yet.");
    }

    function setFloorPlansRepoAddress(address _floorPlansRepoAddress) external onlyOwner {
        floorPlansRepoAddress = _floorPlansRepoAddress;
        emit SetFloorPlansRepoAddress(_floorPlansRepoAddress);
    }

    function tokenURI(uint256 tokenId) override (ERC721) public view returns (string memory) {
        if (floorPlansRepoAddress == address(0)) {
            return super.tokenURI(tokenId);
        }
        
        isValid(tokenId);
        return FloorPlansRepo(floorPlansRepoAddress).tokenURI(tokenId);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit SetPrice(_price);
    }
}
