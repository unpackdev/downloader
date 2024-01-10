// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract HonoraryFrogs is ERC721, Ownable {
    event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("HonoraryFrogs", "HONORARYFROG") {}

    /********************
     * Public functions *
     ********************/

    /// Flags for preventing metadata changes
    mapping(uint256 => bool) public metadataFrozen;

    /// Get the token metadata URI
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _tokenURIs[_tokenId];
    }

    /*****************
     * Admin actions *
     *****************/

    /// Mint a new token
    function mint(
        uint256 _tokenId,
        string memory _tokenURI,
        address _to
    ) external onlyOwner {
        _mint(_to, _tokenId);
        setTokenURI(_tokenId, _tokenURI);
    }

    /// Set the metadata URI for a token
    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        public
        exists(_tokenId)
        onlyOwner
    {
        require(!metadataFrozen[_tokenId], "Metadata is frozen");

        _tokenURIs[_tokenId] = _tokenURI;
    }

    /// Freeze metadata URI for a token
    function freezeTokenURI(uint256 _tokenId)
        public
        exists(_tokenId)
        onlyOwner
    {
        metadataFrozen[_tokenId] = true;
        emit PermanentURI(tokenURI(_tokenId), _tokenId);
    }

    /*************
     * Internals *
     *************/

    /// Token URIs
    mapping(uint256 => string) private _tokenURIs;

    modifier exists(uint256 _tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        _;
    }
}
