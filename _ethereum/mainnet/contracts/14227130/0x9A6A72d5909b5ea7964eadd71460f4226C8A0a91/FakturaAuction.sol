// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract FakturaAuction is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public _totalSupply;
    string private baseURI;
    // if a token's URI has been locked or not
    bool private tokenURILocked;

    constructor(string memory name_, string memory symbol_ ,uint256 totalSupply_, string memory baseURI_) ERC721(name_, symbol_) {
        _totalSupply = totalSupply_;
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // Allow the platform to update a token's URI if it's not locked yet (for fixing tokens post mint process)
    function updateTokenURI(string memory _tokenURI)
    external
    onlyOwner
    {
        // ensure that the URI for this token is not locked yet
        require(tokenURILocked == false, "URI Locked.");

        // update the token URI
        baseURI = _tokenURI;
    }

    // Locks a token's URI from being updated
    function lockTokenURI() external onlyOwner {
        // lock this token's URI from being changed
        tokenURILocked = true;
    }

    function safeMint(address to) public onlyOwner {
        require(_tokenIdCounter.current() < totalSupply(), "There's no token to mint.");

        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }

    /// @notice Transfers the ownership of multiple NFTs from one address to another address
    /// @param _to The new owner
    function safeBatchMint(address[] memory _to) public onlyOwner {
        require(_tokenIdCounter.current() < totalSupply(), "There's no token to mint.");

        for (uint256 i = 0; i < _to.length; i++) {
            _safeMint(_to[i], _tokenIdCounter.current());
            _tokenIdCounter.increment();
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

}