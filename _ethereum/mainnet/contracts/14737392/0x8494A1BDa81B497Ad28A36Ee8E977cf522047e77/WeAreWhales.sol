// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721A.sol";

contract WeAreWhales is Ownable, ERC721A, ReentrancyGuard {

    string public baseURI;

    string private _baseTokenURI;
    uint256 public publicTime;
    uint256 public maxSupply = 2222;
    uint256 public mintTX = 5;
    uint256 public minted = 0;

    constructor() 
        ERC721A("We Are Whales", "WAW", 10, 2222)  {
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(payable(address(this)).balance);
    }

    function mint(uint256 amount) payable public {
        require(minted + amount <= maxSupply, "We Are Soldout");
        require(amount <= mintTX,"Limit Per TX");
        minted += amount;
         _safeMint(msg.sender, amount);
    }
    
}