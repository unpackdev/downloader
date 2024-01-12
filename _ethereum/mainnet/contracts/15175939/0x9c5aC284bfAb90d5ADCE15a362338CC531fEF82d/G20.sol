// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Counters.sol";


contract G20 is ERC721, ERC721Enumerable, Ownable,  ERC721Burnable, ERC721Royalty {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 20;   
    uint256 private constant MAX_PER_MINT = 20;
    uint96 private constant SELLER_FEE = 500; //5%
    address private constant WALLET_ADDRESS = 0x5088D02bf2940E73848aD979Dfa0790846870D4f; 
    string private baseURI_ = "ipfs://bafybeifvtwexqg5g5ak5yxiyih7jjmfhsbktujx24n2g3tvvehi2slodby/";
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("G20", "G20") {
        _setDefaultRoyalty(WALLET_ADDRESS, SELLER_FEE);
    }

    /**
        @notice get the total supply including burned token
    */
    function tokenIdCurrent() external view returns(uint256) {
        return _tokenIdCounter.current();
    }

    function _safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /**
        @notice air drop tokens to recievers
        @param recievers each account will receive one token
    */
    function airDrop(address[] calldata recievers) external onlyOwner {
        require(recievers.length <= MAX_PER_MINT, "High Quntity");
        require(_tokenIdCounter.current() + recievers.length <= MAX_SUPPLY,  "Out of Stock");

        for (uint256 i = 0; i < recievers.length; i++) {
            _safeMint(recievers[i]);
        }
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, tokenId.toString(), ".json")) : "";
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721Royalty){
        super._burn(tokenId);
    }
}
