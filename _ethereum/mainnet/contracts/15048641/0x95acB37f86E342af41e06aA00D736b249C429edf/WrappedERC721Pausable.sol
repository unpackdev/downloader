// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";

contract WrappedERC721Pausable is ERC721Enumerable, Pausable, Ownable {
    // Mapping from tokenID to metadata
    mapping(uint256 => string) private _metadata;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function safeMint(
        address to,
        uint256 tokenId,
        string memory metadata
    ) public onlyOwner {
        _safeMint(to, tokenId);

        _metadata[tokenId] = metadata;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "WrappedERC721: URI query for nonexistent token"
        );

        return _metadata[tokenId];
    }

    function burn(uint256 tokenId) public onlyOwner {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);

        delete _metadata[tokenId];
    }

    /// @notice Pauses the contract
    function pause() public onlyOwner {
        super._pause();
    }

    /// @notice Unpauses the contract
    function unpause() public onlyOwner {
        super._unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(
            !paused(),
            "WrappedERC721Pausable: token transfer while paused"
        );
    }
}
