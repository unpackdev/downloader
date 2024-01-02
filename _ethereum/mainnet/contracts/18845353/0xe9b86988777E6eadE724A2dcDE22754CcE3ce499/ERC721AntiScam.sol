// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC721AntiScam.sol";
import "./ERC721Lockable.sol";
import "./ERC721RestrictApprove.sol";
import "./Ownable.sol";

/// @title AntiScam機能付きERC721A
/// @dev Readmeを見てください。

abstract contract CNCERC721AntiScam is
CNCIERC721AntiScam,
CNCERC721Lockable,
CNCERC721RestrictApprove,
CNCOwnable
{

    /*///////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(CNCERC721Lockable, CNCERC721RestrictApprove)
        returns (bool)
    {
        if (isLocked(owner) || !_isAllowed(owner, operator)) {
            return false;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(CNCERC721Lockable, CNCERC721RestrictApprove)
    {
        require(
            isLocked(msg.sender) == false || approved == false,
            "Can not approve locked token"
        );
        require(
            _isAllowed(operator) || approved == false,
            "RestrictApprove: Can not approve locked token"
        );
        super.setApprovalForAll(operator, approved);
    }

    function _beforeApprove(address to, uint256 tokenId)
        internal
        virtual
        override(CNCERC721Lockable, CNCERC721RestrictApprove)
    {
        CNCERC721Lockable._beforeApprove(to, tokenId);
        CNCERC721RestrictApprove._beforeApprove(to, tokenId);
    }

    function approve(address to, uint256 tokenId)
        public
        virtual
        override(CNCERC721Lockable, CNCERC721RestrictApprove)
    {
        _beforeApprove(to, tokenId);
        CNCERC721Psi.approve(to, tokenId);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(CNCERC721Psi, CNCERC721Lockable) {
        CNCERC721Lockable._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(CNCERC721Lockable, CNCERC721RestrictApprove) {
        CNCERC721Lockable._afterTokenTransfers(from, to, startTokenId, quantity);
        CNCERC721RestrictApprove._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(CNCERC721Lockable, CNCERC721RestrictApprove)
        returns (bool)
    {
        return
            CNCERC721Psi.supportsInterface(interfaceId) ||
            CNCERC721Lockable.supportsInterface(interfaceId) ||
            CNCERC721RestrictApprove.supportsInterface(interfaceId) ||
            interfaceId == type(CNCIERC721AntiScam).interfaceId;
    }
}
