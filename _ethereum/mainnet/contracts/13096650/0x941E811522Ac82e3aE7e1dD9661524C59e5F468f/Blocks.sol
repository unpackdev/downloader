//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./console.sol";
import "./ERC721PresetMinterPauserAutoId.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Blocks is ERC721PresetMinterPauserAutoId, Ownable {
    using Strings for uint256;
    uint256 public BLOCKS_PRICE = 88000000000000000;
    uint public constant MAX_PURCHASABLE = 32;
    uint256 public constant MAX_NFT_SUPPLY = 556;
    string UIRoot = "https://gateway.pinata.cloud/ipfs/QmaLkgZanrcdc9GJea34DupPnRVBfDqqPtarh2WBdYGgKB/";

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    constructor() ERC721PresetMinterPauserAutoId("Blockchain Blocks", "BLOCKS", UIRoot) {
        _tokenIds.increment();
    }
    
    function buy(uint16 pack) payable external {
        
        // enforce supply limit
        uint256 totalMinted = totalSupply();
        require(totalMinted < MAX_NFT_SUPPLY, "Sold out.");
        
 
        uint256 p = (BLOCKS_PRICE*pack);
        console.log("PRICE P %s", p);
        console.log("MSG VAL %s", msg.value);
        require(msg.value >= p, "Not enough ETH.");
        mintNFT(pack);
    }
    
    function mintNFT(uint16 amount)
    private
    {
        for (uint i = 0; i < amount; i++) { 
            _mint(msg.sender, _tokenIds.current());
            _tokenIds.increment();
        }
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
