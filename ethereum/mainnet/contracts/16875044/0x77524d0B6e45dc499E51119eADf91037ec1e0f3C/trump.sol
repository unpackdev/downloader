// SPDX-License-Identifier: MIT


// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⠋⠉⡉⣉⡛⣛⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠄⠄⠄⠄⠄⢀⣸⣿⣿⡿⠿⡯⢙⠿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣿⡿⠄⠄⠄⠄⠄⡀⡀⠄⢀⣀⣉⣉⣉⠁⠐⣶⣶⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣿⡇⠄⠄⠄⠄⠁⣿⣿⣀⠈⠿⢟⡛⠛⣿⠛⠛⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣿⡆⠄⠄⠄⠄⠄⠈⠁⠰⣄⣴⡬⢵⣴⣿⣤⣽⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣿⡇⠄⢀⢄⡀⠄⠄⠄⠄⡉⠻⣿⡿⠁⠘⠛⡿⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⡿⠃⠄⠄⠈⠻⠄⠄⠄⠄⢘⣧⣀⠾⠿⠶⠦⢳⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⣿⣶⣤⡀⢀⡀⠄⠄⠄⠄⠄⠄⠻⢣⣶⡒⠶⢤⢾⣿⣿⣿⣿⣿⣿⣿
// ⣿⣿⣿⣿⡿⠟⠋⠄⢘⣿⣦⡀⠄⠄⠄⠄⠄⠉⠛⠻⠻⠺⣼⣿⠟⠋⠛⠿⣿⣿
// ⠋⠉⠁⠄⠄⠄⠄⠄⠄⢻⣿⣿⣶⣄⡀⠄⠄⠄⠄⢀⣤⣾⣿⣿⡀⠄⠄⠄⠄⢹
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢻⣿⣿⣿⣷⡤⠄⠰⡆⠄⠄⠈⠉⠛⠿⢦⣀⡀⡀⠄
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠈⢿⣿⠟⡋⠄⠄⠄⢣⠄⠄⠄⠄⠄⠄⠄⠈⠹⣿⣀
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠘⣷⣿⣿⣷⠄⠄⢺⣇⠄⠄⠄⠄⠄⠄⠄⠄⠸⣿
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠹⣿⣿⡇⠄⠄⠸⣿⡄⠄⠈⠁⠄⠄⠄⠄⠄⣿
// ⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢻⣿⡇⠄⠄⠄⢹⣧⠄⠄⠄⠄⠄⠄⠄⠄⠘

// MAKE NFTS GREAT AGAIN!

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract TrumpCriminalDigitalCards is ERC721A, Ownable, ReentrancyGuard {

    using Strings for uint256;

    mapping(address => uint) public mintedPerAddress;
    uint256 public mintCost = 0.00345 ether;
    uint256 public maxSupply = 4545;
    uint256 public maxPerTXN = 10;
    bool private saleStarted = false;
    string internal baseUri = "ipfs://bafybeiewtexzf327ftxlgm7c4xkroifzisut7ufgzgp3f3bpdsfkaey37q/";


    constructor() ERC721A("Trump Criminal Digital Cards", "TCDC") {}
    
    function mint(uint256 _amount) external payable nonReentrant {
        require(saleStarted, "Sale not started yet.");
        mintModifier(_amount);
    }

    function mintModifier(uint256 _amount) internal {
        require(_amount <= maxPerTXN && _amount > 0, "Max 10 per Wallet.");
        uint256 free = mintedPerAddress[msg.sender] == 0 ? 1 : 0;
        require(msg.value >= mintCost * (_amount - free), "First mint is free, rest is 0.00345 ETH.");
        mintedPerAddress[msg.sender] += _amount;
        sendMint(_msgSender(), _amount);
    }

    function sendMint(address _wallet, uint256 _amount) internal {
        require(_amount + totalSupply() <= maxSupply, "No supply left.");
        _mint(_wallet, _amount);
    }
    
    function devMint(address _wallet, uint256 _amount) public onlyOwner {
  	    uint256 totalMinted = totalSupply();
	    require(totalMinted + _amount <= maxSupply);
        _mint(_wallet, _amount);
    }
    
    function setSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    
    function setMaxPerTXN(uint256 _max) external onlyOwner {
        maxPerTXN = _max;
    }

    function toggleSale() external onlyOwner {
        saleStarted = !saleStarted;
    }
    
    function setCost(uint256 newCost) external onlyOwner {
        mintCost = newCost;
    }

    function setMetadata(string calldata newUri) external onlyOwner {
        baseUri = newUri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseUri;
    }

    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
    

    function trasnferFunds() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}