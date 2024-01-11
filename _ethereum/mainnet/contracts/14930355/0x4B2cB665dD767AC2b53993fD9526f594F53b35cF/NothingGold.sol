// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

//                                                    _ 
//                                                   (_)
//   __ _ _ __ ___     __      ____ _  __ _ _ __ ___  _ 
//  / _` | '_ ` _ \    \ \ /\ / / _` |/ _` | '_ ` _ \| |
// | (_| | | | | | |_   \ V  V / (_| | (_| | | | | | | |
//  \__, |_| |_| |_( )   \_/\_/ \__,_|\__, |_| |_| |_|_|
//   __/ |         |/                  __/ |            
//  |___/                             |___/             
//

// based on work by @truedrewco for @bildrHQ

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NothingGold is ERC721, Ownable { // UPDATE THIS (optional) // The name of this function usually matches the contract file name
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 8; // UPDATE THIS // total tokens that can ever be minted
    uint256 public constant MAX_PER_MINT = 8; // UPDATE THIS // max tokens allowed in a single mint
    
    uint256 public MINT_PRICE = 0.2 ether; // UPDATE THIS // set to 0 for free mints
    bool public saleIsActive;

    address r1 = 0xb333449fd966227cF3Af0FfD3aAF9d4Ff6F7C3e4; // UPDATE THIS // withdraw function will send eth to this address

    constructor() ERC721("NothingGold", "NGCS") { // UPDATE THIS// Contract Name and Token Symbol (they can be anything!)
        _nextTokenId.increment();   // Start Token Ids at 1
        saleIsActive = false;       // Set sale to inactive
    }

    // standard mint
    function mint(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply.");
        require(msg.value >= numberOfTokens * currentPrice(), "Requires more eth.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(msg.sender, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // airdrop mint
    function airdropMint(uint256 numberOfTokens, address recipient) external onlyOwner payable {
        // require(saleIsActive, "Sale is not active."); // owner can airdrop mint even if sale is off... uncomment to restrict airdrop mints
        require(numberOfTokens > 0, "Quantity must be greater than 0.");
        require(numberOfTokens <= MAX_PER_MINT, "Exceeds max per mint.");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "Exceeds max supply.");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _safeMint(recipient, _nextTokenId.current());
            _nextTokenId.increment();
        }
    }

    // set current price
    function setCurrentPrice(uint256 _price) external onlyOwner {
        MINT_PRICE = _price;
    }

    // return current price
    function currentPrice() public view returns (uint256) {
        return MINT_PRICE;
    }

    // return how many tokens have been minted
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    // override the baseURI function
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // set or update the baseURI
    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // toggle sale on or off
    function toggleSale() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // withdraw ETH balance
    function withdrawBalance() public onlyOwner {
        payable(r1).transfer(address(this).balance);   // Transfer remaining balance to r1 from top of contract
    }

}