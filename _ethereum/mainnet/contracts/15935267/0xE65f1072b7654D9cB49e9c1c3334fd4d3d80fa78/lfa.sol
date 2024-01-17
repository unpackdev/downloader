/**
Looting by randomly altering great balances stored on chain. 
Stats, images, and other functionality are intentionally omitted for others to interpret. 
Feel free to use Loot (for Altruists) in any way you want.

Paying tribute to one of the greatest crypto pieces of all times - https://www.sequoiacap.com/article/sam-bankman-fried-spotlight/
All quotes from Adam Fisher
**/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract LootForAltruists is ERC721, Ownable {
    string private uri;
    uint256 public totalSupply = 0;
    
    constructor() ERC721("Loot (for Altruists)", "LFA") {}

    function give() external {
        require (totalSupply < 123, "nothing more to give");
        require (msg.sender == tx.origin, "only helping mankind");
        totalSupply++;
        _safeMint(msg.sender, totalSupply);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uri;
    }

    function setUri(string memory _uri) external onlyOwner {
        uri = _uri;
    }

    function recoverForCharity() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}