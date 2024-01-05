// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
import "./ERC721.sol";
import "./Ownable.sol";
import "./PricingCalculator.sol";

// Inspired by PIXL and Chubbies. 
contract DumplingERC721 is ERC721, Ownable, PricingCalculator {


    uint public constant MAX_DUMPLINGS = 2500;
    bool public hasSaleStarted = true;

    string public constant R = "We are nervous. Are you?";

    constructor (string memory name, string memory symbol, string memory baseURI) public ERC721(name, symbol){
        _setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started");
        require(totalSupply() < MAX_DUMPLINGS, "No more dumplings");

        uint currentSupply = totalSupply();

        uint currentPrice =  priceCalculator(currentSupply);
        return currentPrice;

    }

    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < MAX_DUMPLINGS, "Sale has already ended");

        uint currentPrice = priceCalculator(_id);
        return currentPrice;
    }
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }
    
    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    function steamDumplings(uint256 numDumplings) public payable {
        require(SafeMath.add(totalSupply(), 1) <= MAX_DUMPLINGS, "Exceeds maximum dumpling supply.");
        require(numDumplings > 0 && numDumplings <= 12, "You can steam minimum 1, maximum 12 dumpling pets");
        require(msg.value >= SafeMath.mul(calculatePrice(), numDumplings), "Oh No. No dumplings for you. Amount of Ether sent is not correct.");
        
        for (uint i = 0; i < numDumplings; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            // _setTokenURI(newTokenId, Strings.toString(newTokenId));
        }
        
    }
}
