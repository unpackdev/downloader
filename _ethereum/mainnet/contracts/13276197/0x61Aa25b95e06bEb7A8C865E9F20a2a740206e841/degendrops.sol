// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";

contract DegenDrops is Ownable, ERC721 {

    event Mint(uint indexed _tokenId);
    
    uint public maxSupply = 1111; // Maximum tokens that can be minted
    uint public totalSupply = 0; // This is our mint counter as well
    uint public limitPerAccount = 111;
    mapping(uint => string) public tokenURIs; // Metadata location, updatable by owner
    mapping(address => uint) public mintCounts; // Amount minted per user
    string public _tokenURI; // Same for all tokens

    constructor() payable ERC721("DegenDrops", "DegenDrops") {
    }

    function mint(address to, uint quantity) external {
        
        require(totalSupply + quantity <= maxSupply, "maxSupply of mints already reached");
        require(mintCounts[to] + quantity <= limitPerAccount, "max 8 mints per account");
        mintCounts[to] += quantity;
        for (uint i = 0; i < quantity; i++) {
            totalSupply += 1; // 1-indexed instead of 0
            _mint(to, totalSupply);
            emit Mint(totalSupply);
        }
    }

    /**
     * @dev Returns the metadata URI
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return "ipfs://QmYHnKEaK61SUTLUm5xBbh8NPeuthuQ6zSajcLw2iFXkSX";
    }

    /**
     * @dev Updates the metadata URI
     */
    function changeTokenURI(string memory __tokenURI) public onlyOwner {
        _tokenURI = __tokenURI;
    }
}