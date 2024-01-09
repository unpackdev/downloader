// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

 contract Down2Earth is ERC721, Ownable {
    using Address for address;
    
    
    string public baseURI;

    uint256 public constant MAX_EARTHLINGS = 4220;
    uint256 public constant PRICE = 0.1 ether;
    uint256 public constant TREASURY_PULL = 120;
    uint256 public totalSupply;

    bool public saleActive = false;

    
    bool public treasuryClaimed = false;


    constructor() ERC721("Down2Earth", "D2E") {   
    }
    
    function claimTreasury() public onlyOwner {
        require(!treasuryClaimed,                                   "Treasury already claimed");
        require(totalSupply + TREASURY_PULL < MAX_EARTHLINGS + 1,      "There are not enough for the treasury");
        for (uint256 i = 0; i < TREASURY_PULL; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += TREASURY_PULL;
        treasuryClaimed = true;
    }

    //hey there gumshoe, if you're viewing this to mint
    //during public window, congrats, you can mint 10 instead 
    //of 5. It pays to read the contract sometimes :D.
    function mint(uint256 numberOfMints) public payable {
        require(saleActive,                                         "Sale must be active to mint");
        require(numberOfMints > 0 && numberOfMints < 11,             "Invalid purchase amount");
        require(totalSupply + numberOfMints < MAX_EARTHLINGS + 1,         "Purchase would exceed max supply of tokens");
        require(PRICE * numberOfMints == msg.value,                 "Ether value sent is not correct");
        
        for(uint256 i; i < numberOfMints; i++) {
            _safeMint(msg.sender, totalSupply + i);
        }

        totalSupply += numberOfMints;
    }


    //we still would like to sell all the earthlings
    //so we'll mint them to the owner to list on secondary
    //ideally we never have to call this.
    function mintOut() public onlyOwner {
        require(!saleActive,                                         "Sale must be inactive to mint");
        uint256 count = totalSupply;
        for(count;count < MAX_EARTHLINGS; count++) {
            _safeMint(msg.sender, count + 1);
            totalSupply++;
        }
    }

    function toggleSale() public onlyOwner {
        saleActive = !saleActive;
    }
    
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }    
}