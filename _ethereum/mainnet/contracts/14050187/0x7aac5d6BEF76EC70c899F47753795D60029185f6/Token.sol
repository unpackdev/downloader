// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Token is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721("harm.work", "HvdD") {}
  
    function mint(address recipient, string memory metadata) external onlyOwner returns (uint256){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, metadata);
        
        return newItemId;
    }
}