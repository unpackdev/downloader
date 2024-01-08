// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract TemplateTest is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private constant PRICE = 0; 
    uint256 public constant TOTAL = 500;
    address private _owner;  
    string private _baseTokenUri = '';
    uint256 public startingIndex = 0;

    constructor() ERC721("TEMPLATE", "TMPLT") {
        _owner = msg.sender;
        _baseTokenUri = 'https://gateway.pinata.cloud/ipfs/QmatiJX8ch9AgQMw5eLNpgPEFKVVcs75SJWM4BByHUEcX7/metadata/';
    }

    function mint(uint256 items) public payable nonReentrant {
        require(items == 1, "Only 1 at a time");       
        require(totalSupply() < TOTAL, "Giveaway has ended");
        require(items > 0, "More than 1 required");        
        require(
            (totalSupply() + items) <= TOTAL,
            "Exceeds TOTAL"
        );
        require(
            (PRICE * items) == msg.value,
            "These are FREE, don't send ETH!"
        );

        for (uint256 i = 0; i < items; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function indexedTokenURI(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _baseTokenUri,
                    tokenId.toString(),
                    '.json'
                )
            );
    }    


    function setTokenURI(string memory newUri) public onlyOwner {
        _baseTokenUri = newUri;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
 
     require(_exists(tokenId), "NO TOKENID");
        string memory result;
        uint256 mappedTokenId = (tokenId + startingIndex) % TOTAL;
        result = indexedTokenURI(mappedTokenId);
        return result;
    }
}