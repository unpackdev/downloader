// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SmallMats is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Small Mats", "MATS") 
    {
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
    
    function mint() external payable {
        require(_tokenIdCounter.current() < 32, "Sold Out");
        require(msg.value >= 0.02 ether, "Ether sent is incorrect"); 
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeieqn35myefjfg7re4z3pnnrxcg7q6mn4zt726aglbevzxe6napljy/";
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
