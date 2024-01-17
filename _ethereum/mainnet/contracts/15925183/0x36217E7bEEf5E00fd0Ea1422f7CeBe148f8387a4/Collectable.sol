// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Counters.sol";

/// @title Collectable contract
/// @custom:juice 100%
/// @custom:security-contact charles@branch.gg
contract Collectable is ERC721, ERC721Burnable, Ownable, Pausable {
    using Counters for Counters.Counter;

    string public baseURI;
    bool public mintFrozen;

    Counters.Counter private tokenIdCounter;

    constructor(string memory baseURI_)
        ERC721("Collectable", "COLLECTABLE")
    {
        baseURI = baseURI_;
    }

    function mint(address _recipient, uint256 amount)
        external
        onlyOwner
    {
        require(!mintFrozen, "Collectable: Mint frozen");

        for (uint256 i = 0; i < amount; i++)
        {
            uint256 tokenId = tokenIdCounter.current();
            tokenIdCounter.increment();
            _mint(_recipient, tokenId);
        }
    }

    function freezeMint()
        external
        onlyOwner
    {
        require(!mintFrozen, "Collectable: Mint frozen");

        mintFrozen = true;
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function setBaseURI(string calldata newBaseURI)
        external
        onlyOwner
    {
        baseURI = newBaseURI;
    }

    function totalSupply()
        external
        view
        returns (uint256)
    {
        return tokenIdCounter.current();
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}