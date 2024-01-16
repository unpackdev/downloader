// SPDX-License-Identifier: MIT
// Features: Airdrop only
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";


contract LUAFPD is ERC721, ERC721Enumerable, Ownable   {
    using Strings for uint256;

    // token
    uint256 public constant MAX_SUPPLY = 228;   
    uint256 private constant MAX_PER_MINT = 20;
    string private baseURI_ = "ipfs://bafybeigtwmjyijmxsdthuogols7xp6tnxinpbl3zjwaemtgpiormziahmi/";

    constructor() ERC721("LUAF Policy Donation", "LUAFPD")  {}

    /**
        @notice airdrop tokens to recievers
        @param recievers each account will receive one token
        @param tokenIds the tokenId to be airdropped
    */
    function airDrop(address[] calldata recievers, uint256[] calldata tokenIds) external onlyOwner {
        require(recievers.length <= MAX_PER_MINT, "High Quntity");
        require(totalSupply() + recievers.length <= MAX_SUPPLY,  "Out of Stock");
        require(recievers.length == tokenIds.length, "mismatch array length");

        for (uint256 i = 0; i < recievers.length; i++) {
            _safeMint(recievers[i], tokenIds[i]);
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
        override(ERC721, ERC721Enumerable)
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

}
