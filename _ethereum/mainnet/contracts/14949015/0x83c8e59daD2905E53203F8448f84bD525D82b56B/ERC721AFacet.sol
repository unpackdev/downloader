// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721ALib.sol";
import "./PausableModifiers.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at ERC721ALib._startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
abstract contract ERC721AFacet is IERC721Metadata, PausableModifiers {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view returns (uint256) {
        ERC721ALib.ERC721AStorage storage s = ERC721ALib.erc721AStorage();
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return s._currentIndex - s._burnCounter - 1;
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        return ERC721ALib.totalMinted();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return ERC721ALib.balanceOf(owner);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return ERC721ALib._ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return ERC721ALib.erc721AStorage()._name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return ERC721ALib.erc721AStorage()._symbol;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId)
        public
        override
        whenNotPaused
    {
        address owner = ERC721AFacet.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        ERC721ALib._approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        return ERC721ALib._getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
        whenNotPaused
    {
        if (operator == msg.sender) revert ApproveToCaller();

        ERC721ALib.erc721AStorage()._operatorApprovals[msg.sender][
            operator
        ] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return ERC721ALib._isApprovedForAll(owner, operator);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        ERC721ALib._transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override whenNotPaused {
        ERC721ALib._transfer(from, to, tokenId);
        if (
            to.isContract() &&
            !ERC721ALib._checkContractOnERC721Received(from, to, tokenId, _data)
        ) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function burn(uint256 tokenId) public whenNotPaused {
        ERC721ALib._burn(tokenId);
    }

    function startTokenId() public pure returns (uint256) {
        return ERC721ALib._startTokenId();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return ERC721ALib._exists(tokenId);
    }

    function numberMinted(address tokenOwner) public view returns (uint256) {
        return ERC721ALib._numberMinted(tokenOwner);
    }
}
