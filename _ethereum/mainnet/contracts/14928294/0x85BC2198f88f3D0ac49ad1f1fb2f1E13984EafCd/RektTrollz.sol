// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract RektTrollz is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant PRICE = 0 ether;             // Price of the single RektTrollz
    uint256 public constant MAX_MINT_SIZE = 2;             // Max RektTrollz allowed in one mint
    uint256 public constant MAX_MINTS = 3333;               // Maximum RektTrollz count
    uint256 public constant MAX_TOKENS_PUBLIC_MINT = 2933;  // Maximum RektTrollz count for public sale
    uint256 public RESERVED_MINTS_AVAILABLE = 400;          // Reserved RektTrollz count
    uint256 public numTokensMinted = 0;                     // Sold RektTrollz count
    uint256 public constant MINT_PER_WALLET = 2;           // One Wallet can mint only 2

    Counters.Counter private _tokenIds;
    mapping (address => uint256) private _userSaleMints;

    bool public isPublicSaleActive = false;          //Sale for all the accounts

    constructor(string memory _baseNFTURI) ERC721A("RektTrollz", "RektTrollz", MAX_MINT_SIZE, MAX_MINTS) {
        //Set BaseURL for the RektTrollz.
        setBaseURI(_baseNFTURI);
    }

    // this is reserved function which used to gift the RektTrollz 
    // to the given account address
    function releaseReserved(address userAddress, uint256 numberOfTokens) external onlyOwner {
        require(RESERVED_MINTS_AVAILABLE - numberOfTokens >= 0, "Purchase would exceed reserved tokens");
        _safeMint(userAddress, numberOfTokens);         // Gift RektTrollz to the address
        RESERVED_MINTS_AVAILABLE -= numberOfTokens;     // Reduce the count of the reserved RektTrollz
    }

    //Main Mint function which is used to mint the token
    function claimTheToken(uint256 numberOfTokens) public nonReentrant {

        //validation to check the public sale is on
        require(isPublicSaleActive, "Public sale is not open yet. Please try again after some time.");
        //validation to check per wallet mint
        require(_userSaleMints[msg.sender] + numberOfTokens <= MINT_PER_WALLET, "Max RektTrollz per wallet limit exceeded.");
        //validation to check total RektTrollz count
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS_PUBLIC_MINT, "We are sold out.");
        _safeMint(msg.sender, numberOfTokens);      //Mint RektTrollz for a price
        _userSaleMints[msg.sender] += numberOfTokens;
        numTokensMinted += numberOfTokens;          // Increase sold RektTrollz count
    }

    //only owner can switch on public sale
    function switchOnPublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    //To withdraw money to the owner's wallet
    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    // // metadata URI
    string private _baseTokenURI;

    // get baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // set baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

}