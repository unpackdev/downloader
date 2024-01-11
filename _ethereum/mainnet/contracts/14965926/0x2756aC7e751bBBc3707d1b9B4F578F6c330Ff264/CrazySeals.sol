// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";



// first 6999 free mint. max supply 5000, max 3 per wallet

contract CrazySeals is ERC721A,Ownable, ReentrancyGuard {
    string public baseURI = "ipfs://QmS3Uj21npuBB8KA7bvFrahYuupknJ4tM31jGyrbBAZWh3/";
    uint256 public constant MAX_SUPPLY = 10000;

    uint256 public publicCost = 0.005 ether;
    uint256 public constant maxPerWallet = 10;
    uint256 public freeMinted = 0;

    bool public manualOpenFreeMint = false;

    mapping (address => uint256) public freeMintRela;

    constructor() ERC721A("Crazy Seals","CST",300,MAX_SUPPLY) {
    }

    // public function  
    function Mint(bool isFree,uint256 quantity) external payable mintCompliance(quantity) {
        require(quantity <= maxPerWallet,"max 5 once time !");
        require(balanceOf(msg.sender) + quantity <= maxPerWallet, "max 10 per wallet");
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
        }

        _safeMint(msg.sender, quantity);

    }

    function devMint(address to,uint256 quantity) public onlyOwner {
        _safeMint(to,quantity);
    }


    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


    function changeManualOpenFreeMint(bool state) onlyOwner external {
        manualOpenFreeMint = state;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    } 

    function getFreeMintNum() public view returns (uint256) {
        return freeMinted;
    }

    // modifier 
    modifier mintCompliance(uint256 quantity) {
        require(totalSupply() + quantity <= MAX_SUPPLY,"not enough limit!");
        _;
    } 
}