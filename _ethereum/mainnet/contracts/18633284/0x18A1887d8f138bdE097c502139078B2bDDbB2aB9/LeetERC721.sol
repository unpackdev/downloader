// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ERC165.sol";

abstract contract ERC721L is ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    // =============================================================
    //                        Fields
    // =============================================================
    string private _name;
    string private _description;
    string private _symbol;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                        Errors
    // =============================================================

    error TokenDoesNotExist();
    error TokenAlreadyMinted();
    error NotAllowedToMint();
    error NotTokenOwnerNorApproved();
    error NotTokenOwner();
    error TokenOwner();
    error ZeroAddressInvalidArgument();
    error NotAllowedToApprove();
    error IndexOutOfBounds();
    error TransferToNonERC721Receiver();

    constructor(string memory name_, string memory symbol_, string memory description_) {
        _name = name_;
        _description = description_;
        _symbol = symbol_;
    }

    // =============================================================
    //                        Opensea
    // =============================================================

    function contractURI() public view returns (string memory) {
        string memory json = string.concat('{"name": "', _name, '","description":"', _description, '"}');
        return string.concat("data:application/json;utf8,", json);
    }
    // =============================================================
    //                         IERC721
    // =============================================================

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert ZeroAddressInvalidArgument();

        uint256 count;
        uint256 i;

        do {
            if (owner == _owners[i]) ++count;
            ++i;
        } while (i < _owners.length);

        return count;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (_owners.length <= tokenId) revert TokenDoesNotExist();
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        _checkApprovedOrOwner(tokenId);
        ERC721L.transferFrom(from, to, tokenId);

        // Check that `to` is an ERC721Receiver if it is a contract
        uint256 size;
        assembly {
            // This opcode returns the size of the code on an address.
            // It is 0 for external accounts (non-contracts)
            size := extcodesize(to)
        }

        if (size > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert TransferToNonERC721Receiver();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        _checkApprovedOrOwner(tokenId);
        if (_owners[tokenId] != from) revert NotTokenOwner();
        if (to == address(0)) revert ZeroAddressInvalidArgument();

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = _owners[tokenId];
        if (owner == to) revert TokenOwner();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotTokenOwnerNorApproved();

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == msg.sender) revert NotAllowedToApprove();

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (_owners[tokenId] == address(0)) revert TokenDoesNotExist();
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // =============================================================
    //                        IERC721Enumerable
    // =============================================================

    function totalSupply() public view virtual override returns (uint256) {
        return _owners.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= _owners.length) revert IndexOutOfBounds();
        return index;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
        if (index >= _owners.length) revert IndexOutOfBounds();

        uint256 count;
        uint256 i;
        do {
            if (owner == _owners[i]) {
                if (count == index) return i;
                ++count;
            }
            ++i;
        } while (i < _owners.length);

        revert IndexOutOfBounds();
    }

    // =============================================================
    //                        Internal
    // =============================================================

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _owners.length && _owners[tokenId] != address(0);
    }

    function _checkApprovedOrOwner(uint256 tokenId) internal view virtual {
        address owner = ERC721L.ownerOf(tokenId);
        if (!(msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender))) {
            revert NotTokenOwnerNorApproved();
        }
    }

    /*
    * @notice Add a new token without minting it
    */
    function _add() internal virtual {
        _owners.push();
    }

    function _mint(address to) internal virtual returns (uint256 tokenId) {
        if (to == address(0)) revert ZeroAddressInvalidArgument();
        tokenId = _owners.length;
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }

    function _mintToken(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) revert ZeroAddressInvalidArgument();
        if (_owners.length <= tokenId) revert TokenDoesNotExist();
        if (_owners[tokenId] != address(0)) revert TokenAlreadyMinted();

        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = _owners[tokenId];
        delete _tokenApprovals[tokenId];
        _owners[tokenId] = address(0);
        emit Transfer(owner, address(0), tokenId);
    }

    function _buildMetadata(string memory key, string memory value) internal pure returns (string memory trait) {
        return string.concat('{"trait_type":"', key, '","value": "', value, '"}');
    }
}
