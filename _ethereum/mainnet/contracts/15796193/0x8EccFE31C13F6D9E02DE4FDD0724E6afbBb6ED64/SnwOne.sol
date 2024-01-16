//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract SnwOne is ERC721, ERC721Enumerable, Ownable {

    // store
    string private _basePath;

    constructor(string memory urlPath) ERC721("SNW ONE", "SNWONE") {
        _basePath = urlPath;
        for (uint256 i = 1; i <= 14; ++i){
            _safeMint(msg.sender, i);
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

    function _baseURI() internal view override returns (string memory) {
        return _basePath;
    }

    function setBaseURI(string calldata path) public onlyOwner{
        _basePath = path;
    }
}