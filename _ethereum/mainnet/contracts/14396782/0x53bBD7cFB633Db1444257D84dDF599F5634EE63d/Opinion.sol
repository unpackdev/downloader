// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./ERC165.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./Context.sol";
import "./Address.sol";
import "./Strings.sol";
import "./IERC721Receiver.sol";

contract Opinion is Context, ERC165, IERC721, IERC721Metadata, Ownable, Pausable {

    using Address for address;
    using Strings for uint256;
    using ECDSA for bytes;

    // Max total supply
    uint256 public maxSupply = 5555;
    // Max painting name length
    uint256 private _maxImageNameLength = 190;
    // purchase price 0.1 eth
    uint256 public _purchasePrice = 100000000000000000 wei;
    // baseURI for Metadata
    string private _metadataURI = "https://ipfs.infura.io/ipfs/";
    // SC beneficiary
    address public beneficiary = 0x489C02eefce290Eb46D8cb582dC11cFCe01F9c51;
    // Max nft limit per wallet
    uint256 public maxLimitPerWallet = 5;
    // Token name
    string private _name;
    // Token symbol
    string private _symbol;
    // Token supply
    uint256 public _tokenSupply;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from image name to its purchased status
    mapping(string => bool) private _namePurchases;

    // Mapping from image name to its token id
    mapping(string => uint256) private _nameToTokenId;

    // Token Id to image hash
    mapping(uint256 => string) private _tokenImageHashes;

    // Token Id to image name
    mapping(uint256 => string) private _tokenIdToName;

    // Token Id to image id
    mapping(uint256 => string) private _tokenIdToImageId;

    // Status of signed messages
    mapping(bytes => bool) private _usedSignedMessages;
    // used IPFS hashes
    mapping(string => bool) private _usedIPFSHashes;

    // used image IDs
    mapping(string => bool) private _usedImageIds;


    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function tokenIdForName(string memory _paintingName)
        external
        view
        returns (uint256)
    {
        return _nameToTokenId[_paintingName];
    }

    function totalSupply() external view returns (uint256) {
        return maxSupply;
    }

    function _verifyName(string memory _imageName) private view returns (bool) {
        if (_namePurchases[_imageName]) {
            return false;
        }
        return true;
    }

    function _mint(
        address _owner,
        string memory _imageName,
        string memory _imageHash,
        string memory _imageId,
        bytes memory _signedMessage,
        uint _tokenId
    ) private returns (uint256) {
        uint256 _newTokenId = _tokenId;

        _safeMint(_owner, _newTokenId);
        _updateStoredValues(
            _imageName,
            _imageHash,
            _imageId,
            _signedMessage,
            _newTokenId
        );

        return _newTokenId;
    }

    function getMessageSigner(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function _verifySignedMessage(
        bytes memory _signedMessage,
        bytes32 _signedHash
    ) internal returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signedMessage);

        address messageSigner = getMessageSigner(_signedHash, v, r, s);
        address _messageSigner = msg.sender;
        if (messageSigner != _messageSigner) {
            return false;
        }
        _usedSignedMessages[_signedMessage] = true;
        return true;
    }

    function _verifyParams(
        string memory _imageName,
        string memory _imageHash,
        string memory _imageId,
        bytes memory _signedMessage,
        bytes32 _signedHash
    ) internal {
        require(!_usedImageIds[_imageId], "ImageID");
        require(!_usedIPFSHashes[_imageHash], "IPFS hash");
        require(bytes(_imageName).length <= _maxImageNameLength, "Name");
        require(msg.value >= _purchasePrice, "value");
        require(_verifyName(_imageName), "name purchased");
        require(
            _verifySignedMessage(
                _signedMessage,
                _signedHash
            ),
            "Signature"
        );
    }

    function _updateStoredValues(
        string memory _imageName,
        string memory _imageHash,
        string memory _imageId,
        bytes memory _signedMessage,
        uint256 _tokenId
    ) private {
        _namePurchases[_imageName] = true;
        _usedSignedMessages[_signedMessage] = true;
        _usedImageIds[_imageId] = true;
        _usedIPFSHashes[_imageHash] = true;

        _nameToTokenId[_imageName] = _tokenId;
        _tokenImageHashes[_tokenId] = _imageHash;
        _tokenIdToName[_tokenId] = _imageName;
        _tokenIdToImageId[_tokenId] = _imageId;
    }

    function mint(
        string memory _imageHash,
        string memory _imageName,
        string memory _imageId,
        bytes memory _signedMessage,
        bytes32 _signedHash,
        uint _tokenId
    ) external payable returns (uint256) {
        require(_tokenSupply < maxSupply, "Maximum supply");
        require(balanceOf(msg.sender) <= maxLimitPerWallet, "Limit per wallet");
        require(_tokenId <= maxSupply, "Wront token id");
        _verifyParams(_imageName, _imageHash, _imageId, _signedMessage, _signedHash);
        uint256 _newTokenId = _mint(
            msg.sender,
            _imageName,
            _imageHash,
            _imageId,
            _signedMessage,
            _tokenId
        );

        return _newTokenId;
    }

    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (
            string memory _imageHash,
            string memory _imageName,
            string memory _imageId
        )
    {
        return (
            _tokenImageHashes[_tokenId],
            _tokenIdToName[_tokenId],
            _tokenIdToImageId[_tokenId]
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(owner != address(0), "ERC721: zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _tokenImageHashes[tokenId]))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return _metadataURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Opinion.ownerOf(tokenId);
        require(to != owner, "ERC721: current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "ERC721: nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        return _operatorApprovals[owner][operator];
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: not owner nor approved"
        );

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
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(_exists(tokenId), "ERC721: nonexistent token");
        address owner = Opinion.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: non ERC721Receiver implementer"
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
        require(to != address(0), "ERC721: zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenSupply += 1;

        emit Transfer(address(0), to, tokenId);
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
        require(Opinion.ownerOf(tokenId) == from, "ERC721: not own");
        require(to != address(0), "ERC721: zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(Opinion.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function withdrawBalance() public onlyOwner virtual {
        payable(beneficiary).transfer(address(this).balance);
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
}