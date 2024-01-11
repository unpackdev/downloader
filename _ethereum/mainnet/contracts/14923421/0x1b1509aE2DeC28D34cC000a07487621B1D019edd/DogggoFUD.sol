// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981.sol";
import "./Mintable.sol";

contract DogggoFUD is ERC721, ERC721URIStorage, ERC2981, Mintable {
    constructor(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _imx,
        address feeReceiver,
        uint96 feeNumerator
    ) ERC721(_name, _symbol) Mintable(_owner, _imx) {
        _setDefaultRoyalty(feeReceiver, feeNumerator);
    }

    function _mintFor(
        address user,
        uint256 id,
        bytes memory
    ) internal override {
        _safeMint(user, id);
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmYK9TG76S6a9HpvzB8mEeDWdjwANajbzZ1yoxKUsjrHiM/";
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
