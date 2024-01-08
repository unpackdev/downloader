// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

import "./ERC721ApprovalProxy.sol";
import "./ERC721TokenPausable.sol";
//import "./ERC721Enumerable.sol";
import "./ERC721Mintable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Permit.sol";
import "./ERC721MetaTransaction.sol";
import "./ERC721Metadata.sol";

contract NFTStudioTokenEthereum is
    ERC721ApprovalProxy,
    ERC721TokenPausable,
    ERC721Mintable,
    ERC721Burnable,
    ERC721Permit("NFTStudio:Token"),
    ERC721MetaTransaction("NFTStudio:Token"),
    ERC721Metadata(
        "NFTStudio:Token",
        "STD",
        "https://nft-studio/api/metadata/"
    )
{

    constructor() {}

    //overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721TokenPausable, ERC721)
        whenNotPaused()
        whenNotTokenPaused(tokenId)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721Metadata, ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setApprovalForAll(address _spender, bool _approved)
        public
        override(ERC721ApprovalProxy, ERC721, IERC721)
    {
        super.setApprovalForAll(_spender, _approved);
    }

    function isApprovedForAll(address _owner, address _spender)
        public
        view
        override(ERC721ApprovalProxy, ERC721, IERC721)
        returns (bool)
    {
        return super.isApprovedForAll(_owner, _spender);
    }

    function _msgSender()
        virtual
        internal
        override(ERC721MetaTransaction, Context)
        view
        returns (address)
    {
        return super._msgSender();
    }

    function bulkMint(address[] memory _tos, uint256[] memory _tokenIds) public onlyMinter {
        require(_tos.length == _tokenIds.length);
        uint8 i;
        for (i = 0; i < _tos.length; i++) {
          mint(_tos[i], _tokenIds[i]);
        }
    }
}
