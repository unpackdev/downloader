/*

      dP                   oo 
      88                      
.d888b88 dP    dP 88d888b. dP 
88'  `88 88    88 88'  `88 88 
88.  .88 88.  .88 88.  .88 88 
`88888P8 `88888P' 88Y888P' dP 
                  88          
                  dP          

by dupi.wtf 12/2023
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

contract DupiNFT is ERC721, Ownable {
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 private _currentTokenId = 0; 
    string private _baseTokenURI;
    string private _notRevealedUri;
    bool public revealed = false;
    bool public saleIsActive = false; // Control sale status
    address private specialAddress;
    uint256 private constant SPECIAL_FREE = 50;
    uint256 private specialClaimed = 0;

    constructor(string memory name, string memory symbol, string memory notRevealedUri) 
        ERC721(name, symbol) 
        Ownable(msg.sender)
    {
        _notRevealedUri = notRevealedUri;
        specialAddress = msg.sender; 
    }

    function mint(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(_currentTokenId + numberOfTokens <= MAX_SUPPLY, "Max supply exceeded");
        require(getPrice(numberOfTokens) <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _currentTokenId++; // Increment first to start token IDs at 1
            _safeMint(msg.sender, _currentTokenId);
        }
    }

       function totalSupply() public view returns (uint256) {
        return _currentTokenId;
    }


    function specialClaim(uint256 numberOfTokens) public {
        require(msg.sender == specialAddress, "Caller is not the special address");
        require(specialClaimed + numberOfTokens <= SPECIAL_FREE, "Claim limit exceeded");
        require(_currentTokenId + numberOfTokens <= MAX_SUPPLY, "Max supply exceeded");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _currentTokenId++; // Increment first to align token IDs
            _safeMint(msg.sender, _currentTokenId);
            specialClaimed++;
        }
    }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return revealed ? _baseTokenURI : _notRevealedUri;
    }

    function setSaleIsActive(bool _state) external onlyOwner {
        saleIsActive = _state;
    }

    function getPrice(uint256 numberOfTokens) public view returns (uint256) {
        uint256 currentSupply = _currentTokenId;
        if (currentSupply < 100) {
            return 0; // First 2 free
        } else if (currentSupply < 550) {
            return 0.003 ether * numberOfTokens; // Next 2 at 0.005 ETH each
        } else {
            return 0.005 ether * numberOfTokens; // Rest at 0.01 ETH each
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
