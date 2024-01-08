// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


// 
//   ________   ___  ________  _______         ___  ________  _______   ________     
//  |\   ___  \|\  \|\   ____\|\  ___ \       |\  \|\   __  \|\  ___ \ |\   ____\    
//  \ \  \\ \  \ \  \ \  \___|\ \   __/|      \ \  \ \  \|\  \ \   __/|\ \  \___|    
//   \ \  \\ \  \ \  \ \  \    \ \  \_|/__  __ \ \  \ \   ____\ \  \_|/_\ \  \  ___  
//    \ \  \\ \  \ \  \ \  \____\ \  \_|\ \|\  \\_\  \ \  \___|\ \  \_|\ \ \  \|\  \ 
//     \ \__\\ \__\ \__\ \_______\ \_______\ \________\ \__\    \ \_______\ \_______\
//      \|__| \|__|\|__|\|_______|\|_______|\|________|\|__|     \|_______|\|_______|
//                                              
//

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

// This is the contract, cool.
contract JpegPass is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_ADMIN_MINT = 10;

    uint256 public constant MAX_SUPPLY = 500;
    
    uint256 public constant PRICE_WAVE_ONE =     0.4 ether;  // 100 Available
    uint256 public constant PRICE_WAVE_TWO =     0.5 ether;  // 150 Available
    uint256 public constant PRICE_WAVE_THREE =   0.6 ether;  // 250 Available

    bool public saleIsActive;

    // Constructor, because why not?
    constructor() ERC721("JpegPass", "JPEGS") {
        _nextTokenId.increment(); // Start Token Ids at 1
        saleIsActive = false;
    }

    // Mint the JPEG already...
    function mint() public payable {
        require(saleIsActive, "JPEGs are not on sale yet!");

        uint256 mintIndex = _nextTokenId.current(); // Get next id to mint
        require(mintIndex <= MAX_SUPPLY, "JPEGs are sold out!");
        require(msg.value >= currentPrice(), "Not enough ETH to buy a JPEG!");

        // Mint. That's the easy part.
        _nextTokenId.increment();
        _safeMint(msg.sender, mintIndex);
    }

    // How much is this JPEG going to cost me?
    function currentPrice() public view returns (uint256) {

        uint256 totalMinted = tokenSupply();

        if (totalMinted < 100) {
            return PRICE_WAVE_ONE;

        } else if (totalMinted < 250) {
            return PRICE_WAVE_TWO;

        } else {
            return PRICE_WAVE_THREE;
        }
    }

    // I wonder how many JPEGs are left?
    function remainingSupply() public view returns (uint256) {
        uint256 numberMinted = tokenSupply();
        return MAX_SUPPLY - numberMinted;
    }

    // I wonder how many JPEGs are minted?
    function tokenSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // All the functions you don't really care about but need to be here
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // Go go go, sale is live!
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // You had to expect this function, right?
    function withdrawBalance() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    // Admin function to mint up to 10 tokens. Just in case...
    function adminMint(uint256 numberOfTokens) public onlyOwner {

        require(numberOfTokens <= MAX_ADMIN_MINT, "Exceeds admin mint amount");

        uint256 totalMinted = tokenSupply();
        uint256 newSupply = totalMinted + numberOfTokens;

        require(newSupply <= MAX_SUPPLY, "Exceeds max supply");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 adminMintIndex = _nextTokenId.current();
            _nextTokenId.increment(); // Increment Id before minting
            _safeMint(msg.sender, adminMintIndex);
        }
    }
}