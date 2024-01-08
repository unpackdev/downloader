// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC721Enumerable.sol";
import "./ERC165.sol";

contract DLWC is IERC165, ERC721, IERC721Enumerable {
    string private constant _NAME = "DL:WC";
    string private constant _SYMBOL = "DLWC";
    string private constant _URI = "data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%2036%2036%22%3E%3Cpath%20fill%3D%22%23AA8ED6%22%20d%3D%22M35.88%2011.83A9.87%209.87%200%200018%206.1%209.85%209.85%200%2000.38%2014.07C1.75%2022.6%2011.22%2031.57%2018%2034.03c6.78-2.46%2016.25-11.44%2017.62-19.96.17-.72.27-1.46.27-2.24z%22%2F%3E%3C%2Fsvg%3E";

    constructor() ERC721("", "") {
        _safeMint(msg.sender, 0, "");
        _safeMint(msg.sender, 1, "");
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
        return _URI;
    }

    function name() public pure override returns (string memory) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    function totalSupply() public pure override returns (uint256) {
        return 2;
    }

    function tokenByIndex(uint256 index)
        public
        pure
        virtual
        override
        returns (uint256)
    {
        require(index < 2, "ERC721Enumerable: global index out of bounds");
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return index == 0 && owner == ownerOf(0) ? 0 : 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
