// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";



// first 6999 free mint. max supply 5000, max 3 per wallet

contract MadSeals is ERC721A,Ownable, ReentrancyGuard {
    string public baseURI;
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public publicCost = 0.01 ether;
    uint256 public constant maxPerWallet = 5;
    uint256 public freeMinted = 0;
    bool public isOpen = false;
    bool public manualOpenFreeMint = false;

    mapping (address => uint256) public freeMintRela;

    constructor() ERC721A("Mad Seals","MST",maxPerWallet,MAX_SUPPLY) {
    }

    // private function 
    function refundIfOver(uint256 price) private {
        require(msg.value >= price,"need more ETH");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }


    // public function  
    function Mint(bool isFree,uint256 quantity) external payable mintCompliance(quantity) {
        require(isOpen == true, "not open yet");
        require(quantity <= maxPerWallet,"max 5 once time !");
        require(msg.sender == tx.origin, "must be human!");
        require(balanceOf(msg.sender) + quantity <= maxPerWallet, "max 5 per wallet");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Purchase would exceed max supply");

        if (isFree) {
            uint256 _userFreeMinted = freeMintRela[msg.sender];
            if (manualOpenFreeMint == false) {
                require(freeMinted <= 1000, "free mint is over!");
            }
            require(_userFreeMinted + quantity <= 2, "free mint per wallet max 2");

            freeMintRela[msg.sender] = _userFreeMinted + quantity;
            freeMinted = freeMinted + quantity;
        }
        else {
            uint256 price = publicCost * quantity;
            require(price == msg.value,"Ether value sent is not correct");
            refundIfOver(price);
        }

        _safeMint(msg.sender, quantity);

    }


    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function changeManualOpenFreeMint(bool state) onlyOwner external {
        manualOpenFreeMint = state;
    }

    function setBaseURI(string memory _baseUri) public onlyOwner {
        baseURI = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    } 

    function getFreeMintNum() public view returns (uint256) {
        return freeMinted;
    }

    function getUserFreeMint() public view returns (uint256) {
        return freeMintRela[msg.sender];
    } 
    
    function setOpenState(bool state) public onlyOwner {
        isOpen = state;
    }

    // modifier 
    modifier mintCompliance(uint256 quantity) {
        require(totalSupply() + quantity <= MAX_SUPPLY,"not enough limit!");
        _;
    } 
}
