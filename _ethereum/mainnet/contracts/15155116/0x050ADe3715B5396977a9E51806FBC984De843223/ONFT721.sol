// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IONFT721.sol";
import "./ONFT721Core.sol";

contract ONFT721 is ONFT721Core, ERC721, IONFT721 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint
    ) ERC721(_name, _symbol) ONFT721Core(_lzEndpoint) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ONFT721Core, ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IONFT721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _tokenId
    ) internal virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ONFT721: send caller is not owner nor approved"
        );
        require(
            ERC721.ownerOf(_tokenId) == _from,
            "ONFT721: send from incorrect owner"
        );
        _burn(_tokenId);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _tokenId
    ) internal virtual override {
        _safeMint(_toAddress, _tokenId);
    }
}
