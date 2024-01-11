// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Baelockit is Ownable, ERC721A, ReentrancyGuard {
    uint256 public constant MAX_TOKENS_PUBLIC_MINT = 333;  // Maximum Baelockit count for public sale
    uint256 public numTokensMinted = 0;                     // Sold Baelockit count
    uint256 public constant MINT_PER_WALLET = 2;           // One Wallet can mint only 2

    Counters.Counter private _tokenIds;
    mapping (address => uint256) private _userSaleMints;

    string public _contractBaseURI;
    bool public isPublicSaleActive = false;          //Sale for all the accounts

    constructor(string memory _baseNFTURI) ERC721A("BAE Lock.it", "Baelockit") {
        _contractBaseURI = _baseNFTURI;
    }

    //Main Mint function which is used to mint the token
    function claimTheToken(uint256 numberOfTokens) public nonReentrant {

        //validation to check the public sale is on
        require(isPublicSaleActive, "Public sale is not open yet. Please try again after some time.");
        //validation to check per wallet mint
        require(_userSaleMints[msg.sender] + numberOfTokens <= MINT_PER_WALLET, "Max Baelockit per wallet limit exceeded.");
        //validation to check total Baelockit count
        require(numTokensMinted + numberOfTokens <= MAX_TOKENS_PUBLIC_MINT, "We are sold out.");
        _safeMint(msg.sender, numberOfTokens);      //Mint Baelockit for a price
        _userSaleMints[msg.sender] += numberOfTokens;
        numTokensMinted += numberOfTokens;          // Increase sold Baelockit count
    }

    //only owner can switch on public sale
    function switchOnPublicSale() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return _contractBaseURI;
    }

}