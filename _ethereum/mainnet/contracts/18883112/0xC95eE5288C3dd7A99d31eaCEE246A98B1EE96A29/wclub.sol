// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract WClubMembership is ERC721, ERC721URIStorage, Ownable {
    uint256 public constant MAX_SUPPLY = 20;
    string private _baseURIextended;
    address _owner;

    constructor(address initialOwner)
        ERC721("W Club Membership Card", "W Club Membership Card")
        Ownable(initialOwner)
    {
        _owner = msg.sender;
        for (uint256 i = 0; i < MAX_SUPPLY; ++i) {
            _safeMint(msg.sender, i + 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        require(_msgSender() == _owner, "Only the contract deployer can transfer tokens");
        super.transferFrom(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
