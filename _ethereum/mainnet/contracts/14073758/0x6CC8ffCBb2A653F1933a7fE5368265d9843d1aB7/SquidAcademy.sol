//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SquidAcademy is ERC721, Ownable 
{
    using Counters for Counters.Counter;
    Counters.Counter private currentTokenId;

    // Constants
    uint256 public constant TOTAL_SUPPLY = 50000;

    constructor() ERC721("SquidAcademy", "SQAC") {}

    function mintTo(address recipient) public onlyOwner returns (uint256) 
    {
        uint256 tokenId = currentTokenId.current();
        require(tokenId < TOTAL_SUPPLY, "Max tokens minted");

        currentTokenId.increment();
        uint256 newItemId = currentTokenId.current();
        _safeMint(recipient, newItemId);
        
        return newItemId;
    }

    function _baseURI() override internal pure returns (string memory) {
        return 'https://squidacademy.herokuapp.com/meta/';
    }

    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}