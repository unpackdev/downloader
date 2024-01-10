// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that extends ERC721Enumerable with wallet and minting functionality.
 */
abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
    string private _baseTokenURI;
    string private _permanentStorageBaseTokenURI;
    string private _permanentStorageExt;

    // Mapping tokenId to indicate token uses permanent storage
    mapping(uint256 => bool) public usePermanentStorage;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenURIBase
    ) ERC721(_name, _symbol) {
        _baseTokenURI = _tokenURIBase;
    }

    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function safeMint(address _to) internal {
        uint256 currentTokenId = totalSupply();
        _safeMint(_to, currentTokenId);
    }

    /* public functions */
    function baseTokenURI() public view virtual returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (usePermanentStorage[_tokenId]) {
            return
                string(
                    abi.encodePacked(
                        _permanentStorageBaseTokenURI,
                        Strings.toString(_tokenId),
                        _permanentStorageExt
                    )
                );
        }
        return
            string(
                abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId))
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i = 0; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    /* owner functions */
    function setBaseTokenURI(string memory value) public onlyOwner {
        _baseTokenURI = value;
    }

    function setPermanentStorageBaseTokenURI(
        string memory uri,
        string memory ext
    ) public onlyOwner {
        _permanentStorageBaseTokenURI = uri;
        _permanentStorageExt = bytes(ext).length <= 1 ? "" : ext;
    }

    function setUsePermanentStorage(uint256 _tokenId, bool _value)
        external
        onlyOwner
    {
        usePermanentStorage[_tokenId] = _value;
    }
}
