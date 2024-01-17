// SPDX-License-Identifier: MIT
// Based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.8.0;

import "./Address.sol";
import "./Strings.sol";

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./LibAppStorage.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract MukabeLandFacet is Modifiers, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    ////////////////////////////////////////////////////////////////////////////////
    // Events

    // New tokens available
    event Available(
        uint256 _maxAvailable24x24Id,
        uint256 _maxAvailable16x16Id,
        uint256 _maxAvailable8x8Id,
        uint256 _maxAvailable5x5Id,
        uint256 _maxAvailable3x3Id,
        uint256 _maxAvailable2x2Id,
        uint256 _maxAvailable1x1Id
    );

    ////////////////////////////////////////////////////////////////////////////////
    // Constants

    // Max tokens
    uint256 private constant MAX_LAND_ID = 599553;

    // Type 1
    uint256 private constant MAX_LAND_24x24_ID = 256 + 1;
    // Type 2
    uint256 private constant MAX_LAND_16x16_ID = 512 + 256;
    // Type 3
    uint256 private constant MAX_LAND_8x8_ID = 1024 + 512 + 256;
    // Type 4
    uint256 private constant MAX_LAND_5x5_ID = 2048 + 1024 + 512 + 256;
    // Type 5
    uint256 private constant MAX_LAND_3x3_ID = 4096 + 2048 + 1024 + 512 + 256;
    // Type 6
    uint256 private constant MAX_LAND_2x2_ID = 8192 + 4096 + 2048 + 1024 + 512 + 256;
    // Type 7
    //uint256 private constant MAX_LAND_1x1_ID = MAX_LAND_ID;

    ////////////////////////////////////////////////////////////////////////////////
    // Functions

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "MukabeLandFacet: address zero is not a valid owner");
        return s.balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address tokenOwner = s.owners[tokenId];
        require(tokenOwner != address(0), "MukabeLandFacet: not minted");
        return tokenOwner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return s.name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return s.symbol;
    }

    function contractURI() public view virtual returns (string memory) {
        return s.contractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        return bytes(s.baseURI).length > 0 ? string(abi.encodePacked(s.baseURI, tokenId.toString(), "/")) : "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = MukabeLandFacet.ownerOf(tokenId);
        require(to != owner, "MukabeLandFacet: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "MukabeLandFacet: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return s.tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return s.operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "MukabeLandFacet: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "MukabeLandFacet: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "MukabeLandFacet: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return s.owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = MukabeLandFacet.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Mints a specific token to an address.
     * @param to address of the future owner of the token
     * @param tokenId ID of the land
     */
    function mintTo(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Set new fees address
     * @param _fees address to send mint fees
     */
    function setFeesAddress(address payable _fees) public virtual onlyOwner {
        require(s.fees != _fees, "MukabeLandFacet: invalid token type");
        s.fees = _fees;
    }

    /**
     * @dev Mints a specific token to an address.
     * @param tokenType 0, 1, 2, 3, 4, 5 or 6
     * @param price Ether
     */
    function setMintPrice(uint256 tokenType, uint256 price) public virtual onlyOwner {
        require(tokenType <= 6, "MukabeLandFacet: invalid token type");
        s.mintingPrices[tokenType] = price;
    }

    /**
     * @dev Get mint price.
     * @param tokenId ID of the land
     */
    function getMintPrice(uint256 tokenId) public view virtual returns (uint256) {
        require((tokenId > 0) && (tokenId <= MAX_LAND_ID), "MukabeLandFacet: invalid token");
        require(!_exists(tokenId), "MukabeLandFacet: token already minted");
        return _getMintPrice(tokenId);
    }

    /**
     * @dev Get mint price.
     * @param tokenId ID of the land
     */
    function _getMintPrice(uint256 tokenId) private view returns (uint256) {
        require(tokenId > 1, "MukabeLandFacet: token not available for minting");
        if (tokenId <= MAX_LAND_24x24_ID) {
          require(tokenId <= s.maxAvailable24x24Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[0];
        } else if (tokenId <= MAX_LAND_16x16_ID) {
          require(tokenId <= s.maxAvailable16x16Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[1];
        } else if (tokenId <= MAX_LAND_8x8_ID) {
          require(tokenId <= s.maxAvailable8x8Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[2];
        } else if (tokenId <= MAX_LAND_5x5_ID) {
          require(tokenId <= s.maxAvailable5x5Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[3];
        } else if (tokenId <= MAX_LAND_3x3_ID) {
          require(tokenId <= s.maxAvailable3x3Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[4];
        } else if (tokenId <= MAX_LAND_2x2_ID) {
          require(tokenId <= s.maxAvailable2x2Id, "MukabeLandFacet: token not available for minting");
          return s.mintingPrices[5];
        }
        require(tokenId <= s.maxAvailable1x1Id, "MukabeLandFacet: token not available for minting");
        return s.mintingPrices[6];
    }

    /**
     * @dev Make token available for each token type.
     * @param maxAvailable24x24Id_ Max ID available in its range.
     * @param maxAvailable16x16Id_ Max ID available in its range.
     * @param maxAvailable8x8Id_ Max ID available in its range.
     * @param maxAvailable5x5Id_ Max ID available in its range.
     * @param maxAvailable3x3Id_ Max ID available in its range.
     * @param maxAvailable2x2Id_ Max ID available in its range.
     * @param maxAvailable1x1Id_ Max ID available in its range.
     * Emits a {Available} event.
     */
    function makeAvailable(
        uint256 maxAvailable24x24Id_,
        uint256 maxAvailable16x16Id_,
        uint256 maxAvailable8x8Id_,
        uint256 maxAvailable5x5Id_,
        uint256 maxAvailable3x3Id_,
        uint256 maxAvailable2x2Id_,
        uint256 maxAvailable1x1Id_
        ) public onlyOwner  {
      require(maxAvailable24x24Id_ >= s.maxAvailable24x24Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable24x24Id = maxAvailable24x24Id_;
      require(maxAvailable16x16Id_ >= s.maxAvailable16x16Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable16x16Id = maxAvailable16x16Id_;
      require(maxAvailable8x8Id_ >= s.maxAvailable8x8Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable8x8Id = maxAvailable8x8Id_;
      require(maxAvailable5x5Id_ >= s.maxAvailable5x5Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable5x5Id = maxAvailable5x5Id_;
      require(maxAvailable3x3Id_ >= s.maxAvailable3x3Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable3x3Id = maxAvailable3x3Id_;
      require(maxAvailable2x2Id_ >= s.maxAvailable2x2Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable2x2Id = maxAvailable2x2Id_;
      require(maxAvailable1x1Id_ >= s.maxAvailable1x1Id, "MukabeLandFacet: max token ID should be greater than previous one");
      s.maxAvailable1x1Id = maxAvailable1x1Id_;
      emit Available(
        s.maxAvailable24x24Id,
        s.maxAvailable16x16Id,
        s.maxAvailable8x8Id,
        s.maxAvailable5x5Id,
        s.maxAvailable3x3Id,
        s.maxAvailable2x2Id,
        s.maxAvailable1x1Id
      );
    }

    /**
     * @dev Mints a specific token to the caller address.
     * @param tokenId ID of the land
     */
    function mint(uint256 tokenId) public virtual payable {
      uint256 price = getMintPrice(tokenId);
      require(msg.value >= price, "MukabeLandFacet: not enough ether");
      _safeMint(msg.sender, tokenId);
      s.fees.transfer(price);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "MukabeLandFacet: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "MukabeLandFacet: mint to the zero address");
        require(!_exists(tokenId), "MukabeLandFacet: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = MukabeLandFacet.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        s.balances[owner] -= 1;
        delete s.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(MukabeLandFacet.ownerOf(tokenId) == from, "MukabeLandFacet: transfer from incorrect owner");
        require(to != address(0), "MukabeLandFacet: transfer to invalid address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        s.balances[from] -= 1;
        s.balances[to] += 1;
        s.owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        s.tokenApprovals[tokenId] = to;
        emit Approval(MukabeLandFacet.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "MukabeLandFacet: approve to caller");
        s.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        //require((tokenId > 0) && (tokenId <= MAX_LAND_ID), "MukabeLandFacet: invalid token ID");
        require(_exists(tokenId), "MukabeLandFacet: token does not exist");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("MukabeLandFacet: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
