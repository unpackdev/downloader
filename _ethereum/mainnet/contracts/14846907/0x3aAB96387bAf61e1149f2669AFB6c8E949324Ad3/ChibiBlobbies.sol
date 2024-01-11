// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract ChibiBlobbies is ERC721A, Ownable, ReentrancyGuard {
    
    string private __baseURI = "ipfs://QmQQMyKqAVDwVcGTG34oLgDd3EWUtu2zhqhRcTpB5g4AAa/";

    uint256 private _max_mint = 2;

    mapping(address => uint256) _account_mint;

    constructor() ERC721A("Chibi Blobbies", "BLOBBY", 4, 888) {}

    function mint(uint256 quantity) external {
        require(totalSupply() + quantity <= collectionSize, "already mint out");
        address to = msg.sender;
        require(_account_mint[to] + quantity <= _max_mint, "over the max minting");
        
        _safeMint(to, quantity);
        _account_mint[to] += quantity;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        __baseURI = baseURI;
    }

    function queryMintAmount(address owner) external view returns(uint256) {
        return _account_mint[owner];
    }
}
