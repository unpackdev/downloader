// SPDX-License-Identifier: MIT
// Warriors Unleashed Contract
//
// █     █░ ▄▄▄       ██▀███   ██▀███   ██▓ ▒█████   ██▀███    ██████         
//▓█░ █ ░█░▒████▄    ▓██ ▒ ██▒▓██ ▒ ██▒▓██▒▒██▒  ██▒▓██ ▒ ██▒▒██    ▒         
//▒█░ █ ░█ ▒██  ▀█▄  ▓██ ░▄█ ▒▓██ ░▄█ ▒▒██▒▒██░  ██▒▓██ ░▄█ ▒░ ▓██▄           
//░█░ █ ░█ ░██▄▄▄▄██ ▒██▀▀█▄  ▒██▀▀█▄  ░██░▒██   ██░▒██▀▀█▄    ▒   ██▒        
//░░██▒██▓  ▓█   ▓██▒░██▓ ▒██▒░██▓ ▒██▒░██░░ ████▓▒░░██▓ ▒██▒▒██████▒▒        
//░ ▓░▒ ▒   ▒▒   ▓▒█░░ ▒▓ ░▒▓░░ ▒▓ ░▒▓░░▓  ░ ▒░▒░▒░ ░ ▒▓ ░▒▓░▒ ▒▓▒ ▒ ░        
//  ▒ ░ ░    ▒   ▒▒ ░  ░▒ ░ ▒░  ░▒ ░ ▒░ ▒ ░  ░ ▒ ▒░   ░▒ ░ ▒░░ ░▒  ░ ░        
//  ░   ░    ░   ▒     ░░   ░   ░░   ░  ▒ ░░ ░ ░ ▒    ░░   ░ ░  ░  ░          
//    ░          ░  ░   ░        ░      ░      ░ ░     ░           ░          
//                                                                            
// █    ██  ███▄    █  ██▓    ▓█████ ▄▄▄        ██████  ██░ ██ ▓█████ ▓█████▄ 
// ██  ▓██▒ ██ ▀█   █ ▓██▒    ▓█   ▀▒████▄    ▒██    ▒ ▓██░ ██▒▓█   ▀ ▒██▀ ██▌
//▓██  ▒██░▓██  ▀█ ██▒▒██░    ▒███  ▒██  ▀█▄  ░ ▓██▄   ▒██▀▀██░▒███   ░██   █▌
//▓▓█  ░██░▓██▒  ▐▌██▒▒██░    ▒▓█  ▄░██▄▄▄▄██   ▒   ██▒░▓█ ░██ ▒▓█  ▄ ░▓█▄   ▌
//▒▒█████▓ ▒██░   ▓██░░██████▒░▒████▒▓█   ▓██▒▒██████▒▒░▓█▒░██▓░▒████▒░▒████▓ 
//░▒▓▒ ▒ ▒ ░ ▒░   ▒ ▒ ░ ▒░▓  ░░░ ▒░ ░▒▒   ▓▒█░▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░░ ▒░ ░ ▒▒▓  ▒ 
//░░▒░ ░ ░ ░ ░░   ░ ▒░░ ░ ▒  ░ ░ ░  ░ ▒   ▒▒ ░░ ░▒  ░ ░ ▒ ░▒░ ░ ░ ░  ░ ░ ▒  ▒ 
// ░░░ ░ ░    ░   ░ ░   ░ ░      ░    ░   ▒   ░  ░  ░   ░  ░░ ░   ░    ░ ░  ░ 
//   ░              ░     ░  ░   ░  ░     ░  ░      ░   ░  ░  ░   ░  ░   ░    
//                                                                     ░      

pragma solidity ^0.8.14;

import "./ERC721A.sol";
import "./ReentrancyGuard.sol";

interface DisperseGift {
    function safeTransferFrom(address, address, uint256) external;
}
contract WarriorsUnleashed is ERC721A, ReentrancyGuard, IERC721Receiver {
    address public owner;
    address[] public drawWinners;
    string private _baseTokenURI;
    uint256 public price;
    uint256 public maxSupply;
    uint256 public freeSupply;
    uint256 public maxFreeSupply;
    uint256 private randNonce;
    bool public mintStatus;
    bool public isRevealed;
    modifier onlyOwner() {
        require(owner == msg.sender,"Caller is not owner.");
        _;
    }
    receive() external payable {}
    constructor() ERC721A("Warriors Unleashed", "WAR") {
        owner = msg.sender;
        _baseTokenURI = "https://storageapi.fleek.co/1fd1a4f6-e1ab-41fd-94fb-bc30a424df1e-bucket/Warriors%20Unleashed/";
        price = 0.003 ether;
        maxSupply = 3333;
        maxFreeSupply = 1111;
        mintStatus = false;
    }
    // Minting functions start here ==============>>>>>>>>>>>
    function mint() external payable {
        require(mintStatus == true,"Minting is currently not active.");
        require(maxSupply >= (totalSupply() + 1),"Minting Quantity Exceeds Maximum Supply.");
        require(_numberMinted(msg.sender) == 0,"User has already minted already.");
        if(msg.value == 0) {
            require(freeSupply < maxFreeSupply,"Free supply has ended.");
            freeSupply += 1;
        } else {
            require(msg.value >= price,"Insufficient Amount Paid.");
        }
        _safeMint(msg.sender, 1);
    }
    function mintOwner(address[] calldata MintAdd) external onlyOwner {
        require(maxSupply >= totalSupply() + MintAdd.length,"Minting Quantity Exceeds NFT Maximum Supply.");
        for (uint256 i=0;i<MintAdd.length;i++) {
            _safeMint(MintAdd[i], 1);
        }
    }
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
    function burn(uint tokenId) external onlyOwner {
        _burn(tokenId);
    }
    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        if(isRevealed) {
            return string(abi.encodePacked(_baseTokenURI,tokenId,".json"));
        } else {
            return string(abi.encodePacked(_baseTokenURI,"warriorsunleashed.json"));
        }
    }
    //Override & Helper functions here ==============>>>>>>>>>>>
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    function setMintStatus(bool status) external onlyOwner {
        mintStatus = status;
    }
    function setRandNonce(uint256 randNumber) external onlyOwner {
        randNonce = randNumber;
    }
    function setRevealed() external onlyOwner {
        isRevealed = !isRevealed;
    }
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
      return this.onERC721Received.selector;
    }
    //Battle Functions from here ==============>>>>>>>>>>>
    function rewardEther(uint256 drawNo, uint256 amount) external onlyOwner nonReentrant {
        require(address(this).balance >= amount);
        payable(drawWinners[drawNo]).transfer(amount);
	}
    function rewardNFT(uint256 drawNo, address contractAddress, uint256 tokenId) external onlyOwner {
        DisperseGift(contractAddress).safeTransferFrom(address(this), drawWinners[drawNo], tokenId);
    }
    function startBattle() external onlyOwner {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, randNonce, block.timestamp, block.number, randNonce, msg.sender)));
        uint winnerID = randomHash % 3333;
        address winner = ownerOf(winnerID);
        drawWinners.push(winner);
    }
    function withdrawEther(address destWallet) external onlyOwner nonReentrant {
        payable(destWallet).transfer(address(this).balance);
	}
    function withdrawNFT(address destWallet, address contractAddress, uint256 tokenId) external onlyOwner {
        DisperseGift(contractAddress).safeTransferFrom(address(this), destWallet, tokenId);
    }
}