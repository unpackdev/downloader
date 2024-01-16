// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol"; 
import "./ERC2981.sol";

contract ARCStellarsHonoraryMembers is ERC721, ERC2981, Ownable {
    using Counters for Counters.Counter;
    string public baseURI = "";
    Counters.Counter private tokenId;
    uint96 private constant _royaltyFeesInBips = 880; // 8.8%
    string public contractURI;
    
    constructor() ERC721("ARC Stellars Honorary Members", "ASH") {
        setRoyaltyInfo(owner());
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalSupply() public view returns (uint256) {
        return tokenId.current();
    }

    function airdropHonorary(address to) public onlyOwner {
        tokenId.increment();
        _safeMint(to, tokenId.current());
    }

    function setContractURI(string calldata URI) public onlyOwner {
        contractURI = URI;
    }

    function setRoyaltyInfo(address _receiver) public onlyOwner {
        super._setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }
    /**
    * ERC2981 
    * The following functions are overrides 
    */
    function _beforeTokenTransfer(address from, address to, uint256 _tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, _tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }
}
