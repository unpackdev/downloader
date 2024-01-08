// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";


contract EtherFly is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint8 public constant etherFlyLimit = 100;
    address immutable marketAddress;

    constructor(address market) ERC721("EtherFly", "FLY") {
        marketAddress = market;
    }

    function _baseURI() internal pure override returns (string memory) {
       return  "https://gateway.pinata.cloud/ipfs/QmRfnBxcsh7KXwbvCaaSwvkmxY36uVXytNmwUXaA6WB5SW/EtherFly";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        string memory padding = tokenId > 9 ? "0" : "00";
        if (tokenId == 100) padding = "";
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, padding, tokenId.toString(), ".json")) : "";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint() public {
        require(_tokenIdCounter.current() < etherFlyLimit, "All EtherFlies have already been minted");
        
        _tokenIdCounter.increment();
        _safeMint(msg.sender, _tokenIdCounter.current());
        setApprovalForAll(marketAddress, true);
    }

    function safeMintTo(address to) public onlyOwner {
        require(_tokenIdCounter.current() < etherFlyLimit, "All EtherFlies have already been minted");
            
        _tokenIdCounter.increment();
        _safeMint(to, _tokenIdCounter.current());
        setApprovalForAll(marketAddress, true);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// Utility function to return a full array of all your EtherFly 
    function getMyEtherFlies() public view returns (uint256[] memory) {
        uint256 itemCount = balanceOf(msg.sender);
        uint256[] memory items = new uint256[](itemCount);
        
        for (uint256 i = 0; i < itemCount; i++) {
           items[i] = tokenOfOwnerByIndex(msg.sender, i);
        }
        return items;
    }
}
