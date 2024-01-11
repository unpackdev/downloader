// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./ERC721A.sol";

contract WAGFLIP is ERC721A, Ownable{
    
    error CannotMintMoreThanMaximum();
    error SendMoreEther();
    error DontBeGreedy();

    uint256 public constant MAX_SUPPLY = 6666;
    uint256 public constant MINT_PRICE = 0.0 ether;
    uint256 public constant MAX_MINT = 1;
    uint256 public constant TEAM_CLAIM_AMOUNT = 111;
    mapping(address => uint) public addressClaimed;
    uint256 public CURRENT_SUPPLY = 0;
    string public baseUri = "";

    bool public claimed = false;
    
    constructor() ERC721A("We Are All Going To Fucking Love Inverted Pictures", "WAGFLIP")
    {}

    
    function teamClaim(address teamAddress_) external onlyOwner {
        require(!claimed, "Team already claimed");
        _safeMint(teamAddress_, TEAM_CLAIM_AMOUNT);
        claimed = true;
      }

    
    function safeMint(address to, uint256 _numberToMint) public payable {
        
        if(_numberToMint>1){
            revert DontBeGreedy();
        }

        
        if(CURRENT_SUPPLY + _numberToMint > MAX_SUPPLY - TEAM_CLAIM_AMOUNT){
            revert CannotMintMoreThanMaximum();
        }
        
        if(msg.value < _numberToMint * MINT_PRICE){
            revert SendMoreEther();
        }


        if(addressClaimed[msg.sender] >= MAX_MINT){
            revert DontBeGreedy();
        }
        
        addressClaimed[msg.sender] += _numberToMint;

        CURRENT_SUPPLY += _numberToMint;

        _safeMint(to, _numberToMint);

    }
   
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseURI(string memory baseUri_) external onlyOwner {
        baseUri = baseUri_;
    }

    function withdraw() external onlyOwner {
        payable(Ownable.owner()).transfer(address(this).balance);
    }

    
    

    
}
