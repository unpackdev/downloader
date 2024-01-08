pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";


/**
 * @title RabbitCollegeClub contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract RabbitCollegeClub is ERC721Enumerable, Ownable {
    using SafeMath for uint256;

    uint256 public constant rabbitPrice = 50000000000000000; // 0.05 ETH
    uint public constant maxRabbitPurchase = 100;
    uint256 public MAX_RABBITS = 10000;
    bool public saleIsActive = false;

    constructor() ERC721("Rabbit College Club", "RCC") {
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reserveRabbits() public onlyOwner {        
        uint supply = totalSupply();
        uint i;
        for (i = 0; i < 40; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    
    

    function mintRabbits(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Rabbits");
        require(numberOfTokens <= maxRabbitPurchase, "Can only mint 100 tokens at a time");
        require(totalSupply().add(numberOfTokens) <= MAX_RABBITS, "Purchase would exceed max supply of Rabbits");
        require(rabbitPrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            if (totalSupply() < MAX_RABBITS) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

}