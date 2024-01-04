// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Address.sol";
import "./ERC165.sol";

/**
 * @dev ERC721 Non-Fungible Token Implementation
 *
 * Exert uniqueness of owner: one owner can only have one token
 */
contract ERC721 is IERC721, ERC165 {

    using Address for address;

    /*
     * Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     * which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x081812fc ^ 0xe985e9c5 ^
     *        0x095ea7b3 ^ 0xa22cb465 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    // Mapping from owner address to tokenId
    // tokenId starts from 1, 0 is reserved for nonexistent token
    // One owner can only own one token in this contract
    mapping (address => uint256) _ownerTokenId;

    // Mapping from tokenId to owner
    mapping (uint256 => address) _tokenIdOwner;

    // Mapping from tokenId to approved operator
    mapping (uint256 => address) _tokenIdOperator;

    // Mapping from owner to operator for all approval
    mapping (address => mapping (address => bool)) _ownerOperator;


    constructor () {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev See {IERC721}.{balanceOf}
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (_exists(owner)) {
            return 1;
        } else {
            return 0;
        }
    }

    /**
     * @dev See {IERC721}.{ownerOf}
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: ownerOf for nonexistent tokenId");
        return _tokenIdOwner[tokenId];
    }

    /**
     * @dev See {IERC721}.{getApproved}
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: getApproved for nonexistent tokenId");
        return _tokenIdOperator[tokenId];
    }

    /**
     * @dev See {IERC721}.{isApprovedForAll}
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        require(_exists(owner), "ERC721: isApprovedForAll for nonexistent owner");
        return _ownerOperator[owner][operator];
    }

    /**
     * @dev See {IERC721}.{approve}
     */
    function approve(address operator, uint256 tokenId) public override {
        require(msg.sender == ownerOf(tokenId), "ERC721: approve caller is not owner");
        _approve(msg.sender, operator, tokenId);
    }

    /**
     * @dev See {IERC721}.{setApprovalForAll}
     */
    function setApprovalForAll(address operator, bool approved) public override {
        require(_exists(msg.sender), "ERC721: setApprovalForAll caller is not existent owner");
        _ownerOperator[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721}.{transferFrom}
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        _validateTransfer(msg.sender, from, to, tokenId);
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721}.{safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721}.{safeTransferFrom}
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public override
    {
        _validateTransfer(msg.sender, from, to, tokenId);
        _safeTransfer(from, to, tokenId, data);
    }


    /**
     * @dev Returns if owner exists.
     */
    function _exists(address owner) internal view returns (bool) {
        return _ownerTokenId[owner] != 0;
    }

    /**
     * @dev Returns if tokenId exists.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenIdOwner[tokenId] != address(0);
    }

    /**
     * @dev Approve `operator` to manage `tokenId`, owned by `owner`
     *
     * Validation check on parameters should be carried out before calling this function.
     */
    function _approve(address owner, address operator, uint256 tokenId) internal {
        _tokenIdOperator[tokenId] = operator;
        emit Approval(owner, operator, tokenId);
    }

    /**
     * @dev Validate transferFrom parameters
     */
    function _validateTransfer(address operator, address from, address to, uint256 tokenId)
        internal view
    {
        require(from == ownerOf(tokenId), "ERC721: transfer not owned token");
        require(to != address(0), "ERC721: transfer to 0 address");
        require(!_exists(to), "ERC721: transfer to already existent owner");
        require(
            operator == from || _tokenIdOperator[tokenId] == operator || _ownerOperator[from][operator],
            "ERC721: transfer caller is not owner nor approved"
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Validation check on parameters should be carried out before calling this function.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        // clear previous ownership and approvals
        delete _ownerTokenId[from];
        delete _tokenIdOperator[tokenId];

        // set up new owner
        _ownerTokenId[to] = tokenId;
        _tokenIdOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract
     * recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Validation check on parameters should be carried out before calling this function.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     *      The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID.
     * @param to target address that will receive the tokens.
     * @param tokenId uint256 ID of the token to be transferred.
     * @param data bytes optional data to send along with the call.
     * @return bool whether the call correctly returned the expected magic value.
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

}
