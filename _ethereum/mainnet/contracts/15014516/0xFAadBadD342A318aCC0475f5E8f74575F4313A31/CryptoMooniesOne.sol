// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract CryptoMooniesOne is ERC721AQueryable, Ownable {
    using Strings for uint256;

    mapping(uint256 => string) public tokenMetaData;

    string public uriPrefix = "ipfs://";

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721A(_tokenName, _tokenSymbol)
    {}

    /// @dev The owner can mint tokens to any address.

    function mint(address _receiver, string memory _cid) public onlyOwner {
        setTokenMetadata(_totalMinted(), _cid);
        _safeMint(_receiver, 1);
    }

    //***************************************************************************
    //  VIEW FUNCTIONS
    //***************************************************************************

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory currentBaseURI = _baseURI();
        require(_exists(_tokenId), "URI query for nonexistent token");

        return
            string(abi.encodePacked(currentBaseURI, tokenMetaData[_tokenId]));
    }

    //***************************************************************************
    //  CRUD FUNCTIONS
    //***************************************************************************

    function setTokenMetadata(uint256 _id, string memory _cid)
        public
        onlyOwner
    {
        tokenMetaData[_id] = string(abi.encodePacked(_cid));
    }

    function setUriPrefix(string memory _prefix) public onlyOwner {
        uriPrefix = _prefix;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
