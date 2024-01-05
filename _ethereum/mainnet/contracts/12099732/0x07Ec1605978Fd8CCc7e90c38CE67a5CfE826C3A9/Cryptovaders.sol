// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Cryptovaders is ERC721, Ownable, ERC721Burnable {
    using Strings for uint256;
    string private _contractURI;
    string private _defaultBaseURI;

    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => bool) public autoIds;
    uint256 private currentTokenId = 0;

    constructor(
        string memory name,
        string memory symbol,
        string memory defaultBaseURI,
        string memory contractURI_
    ) ERC721(name, symbol) {
        _defaultBaseURI = defaultBaseURI;
        _contractURI = contractURI_;
    }

    function setDefaultBaseURI(string memory defaultBaseURI)
        public
        virtual
        onlyOwner
    {
        _defaultBaseURI = defaultBaseURI;
    }

    function setContractURI(string memory contractURI_)
        public
        virtual
        onlyOwner
    {
        _contractURI = contractURI_;
    }

    function mint(
        address to,
        uint256 tokenId,
        string memory _tokenURI
    ) public virtual onlyOwner {
        // If no ID is provided then we generate an ID automatically
        bool autoId = tokenId == 0;
        if (autoId) {
            tokenId = getNextTokenId();
        }
        _mint(to, tokenId);

        // If no tokenURI is provided we will use the default
        if (bytes(_tokenURI).length > 0) {
            tokenURIs[tokenId] = _tokenURI;
        }

        // Remember this token was an autoId and incriment
        if (autoId) {
            autoIds[tokenId] = true;
            incrementTokenId();
        }
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenBaseURI = tokenURIs[tokenId];

        if (autoIds[tokenId]) {
            return
                bytes(_tokenBaseURI).length > 0
                    ? string(
                        abi.encodePacked(_tokenBaseURI, tokenId.toString())
                    )
                    : string(
                        abi.encodePacked(_defaultBaseURI, tokenId.toString())
                    );
        } else {
            return
                bytes(_tokenBaseURI).length > 0
                    ? _tokenBaseURI
                    : string(
                        abi.encodePacked(_defaultBaseURI, tokenId.toString())
                    );
        }
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function getNextTokenId() private view returns (uint256) {
        return currentTokenId + 1;
    }

    function incrementTokenId() private {
        currentTokenId++;
    }
}
