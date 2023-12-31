// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   

 - github: https://github.com/estarriolvetch/ERC721Psi
 - npm: https://www.npmjs.com/package/erc721psi
                                          
 */
pragma solidity ^0.8.13;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Context.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./StorageSlot.sol";
import "./BitMaps.sol";
import "./ERC2981.sol";
import "./Base64.sol";

contract ERC721Psi is Context, ERC165, IERC721, IERC721Metadata, ERC2981 {
    using Address for address;
    using Strings for uint256;
    using Strings for address;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _batchHead;
    BitMaps.BitMap private _mintBatchHead;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _minters;
    mapping(uint256 => uint256) internal _seeds;
    mapping(uint256 => uint256) internal _colors;
    mapping(uint256 => address) internal _originalAddress;
    string internal _baseTokenURI = "";
    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    uint256 internal _currentIndex;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 internal _generatedId;

    struct Traits {
        string colorPalette;
        string walletAddress;
        string seed;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor() {
        _name = "Grid Haus";
        _symbol = "GHAUS";
        _currentIndex = _startTokenId();
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal pure returns (uint256) {
        // It will become modifiable in the future versions
        return 1;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        return _currentIndex - _startTokenId();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, ERC2981)
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
        require(
            owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );

        uint256 count;
        for (uint256 i = _startTokenId(); i < _nextTokenId(); ++i) {
            if (_exists(i)) {
                if (owner == ownerOf(i)) {
                    ++count;
                }
            }
        }
        return count;
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
        (address owner, ) = _ownerAndBatchHeadOf(tokenId);
        return owner;
    }

    function _ownerAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address owner, uint256 tokenIdBatchHead)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: owner query for nonexistent token"
        );
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = _owners[tokenIdBatchHead];
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

    function minterOf(uint256 tokenId) public view virtual returns (address) {
        (address minter, ) = _minterAndBatchHeadOf(tokenId);
        return minter;
    }

    function _minterAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address minter, uint256 tokenIdBatchHead)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: owner query for nonexistent token"
        );
        tokenIdBatchHead = _getMintBatchHead(tokenId);
        minter = _minters[tokenIdBatchHead];
    }

    function _getMintBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        tokenIdBatchHead = _mintBatchHead.scanForward(tokenId);
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
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");
        if (bytes(_baseURI()).length > 0) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        } else if (tokenId <= _generatedId) {
            return getStorageURI(tokenId);
        } else {
            Traits memory traits = getTraits(tokenId);
            string memory json = string(
                abi.encodePacked(
                    '{"name":"Grid Haus #',
                    tokenId.toString(),
                    '", "description":"description", "image":"https://storage.googleapis.com/grid_haus_data/logo_',
                    traits.colorPalette,
                    '.jpeg", "animation_url":"https://storage.googleapis.com/grid_haus_data/grid_haus.html?address=',
                    traits.walletAddress,
                    "&colorPalette=",
                    traits.colorPalette,
                    "&seed=",
                    traits.seed,
                    '", "attributes":[{"trait_type":"Color Palette","value":',
                    traits.colorPalette,
                    "}]}"
                )
            );

            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(bytes(json))
                    )
                );
        }
    }

    function getStorageURI(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://storage.googleapis.com/grid_haus_data/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }

    function getWalletAddress(uint256 p_tokenId)
        internal
        view
        returns (address)
    {
        if (_originalAddress[p_tokenId] != address(0)) {
            return _originalAddress[p_tokenId];
        } else {
            return minterOf(p_tokenId);
        }
    }

    function getColorPalette(uint256 p_tokenId)
        internal
        view
        returns (uint256)
    {
        if (_colors[p_tokenId] != 0) {
            return _colors[p_tokenId];
        } else {
            uint256 additive = (uint256(
                keccak256(abi.encodePacked(minterOf(p_tokenId)))
            ) % 9) + 1;
            return ((p_tokenId * additive) % 31) + 1;
        }
    }

    function getTraits(uint256 p_tokenId) public view returns (Traits memory) {
        Traits memory traits = Traits({
            colorPalette: getColorPalette(p_tokenId).toString(),
            walletAddress: getWalletAddress(p_tokenId).toHexString(),
            seed: generateSeed(p_tokenId).toString()
        });
        return traits;
    }

    function generateSeed(uint256 p_tokenId) internal view returns (uint256) {
        if (_seeds[p_tokenId] != 0) {
            return _seeds[p_tokenId];
        } else {
            return
                uint256(
                    keccak256(abi.encodePacked(minterOf(p_tokenId), p_tokenId))
                );
        }
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */

    function _baseURI() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Psi: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Psi: approve caller is not owner nor approved for all"
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
        require(
            _exists(tokenId),
            "ERC721Psi: approved query for nonexistent token"
        );

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
        require(operator != _msgSender(), "ERC721Psi: approve to caller");

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
            "ERC721Psi: transfer caller is not owner nor approved"
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
            "ERC721Psi: transfer caller is not owner nor approved"
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
            _checkOnERC721Received(from, to, tokenId, 1, _data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _nextTokenId() && _startTokenId() <= tokenId;
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
        require(
            _exists(tokenId),
            "ERC721Psi: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 nextTokenId = _nextTokenId();
        _mint(to, quantity);
        require(
            _checkOnERC721Received(
                address(0),
                to,
                nextTokenId,
                quantity,
                _data
            ),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 quantity) internal virtual {
        uint256 nextTokenId = _nextTokenId();

        require(quantity > 0, "ERC721Psi: quantity must be greater 0");
        require(to != address(0), "ERC721Psi: mint to the zero address");

        _beforeTokenTransfers(address(0), to, nextTokenId, quantity);
        _currentIndex += quantity;
        _owners[nextTokenId] = to;
        _minters[nextTokenId] = to;
        _batchHead.set(nextTokenId);
        _mintBatchHead.set(nextTokenId);
        _afterTokenTransfers(address(0), to, nextTokenId, quantity);

        // Emit events
        for (
            uint256 tokenId = nextTokenId;
            tokenId < nextTokenId + quantity;
            tokenId++
        ) {
            emit Transfer(address(0), to, tokenId);
        }
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
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );

        require(owner == from, "ERC721Psi: transfer of token that is not own");
        require(to != address(0), "ERC721Psi: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 subsequentTokenId = tokenId + 1;

        if (
            !_batchHead.get(subsequentTokenId) &&
            subsequentTokenId < _nextTokenId()
        ) {
            _owners[subsequentTokenId] = from;
            _batchHead.set(subsequentTokenId);
        }

        _owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            _batchHead.set(tokenId);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param startTokenId uint256 the first ID of the tokens to be transferred
     * @param quantity uint256 amount of the tokens to be transfered.
     * @param _data bytes optional data to send along with the call
     * @return r bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity,
        bytes memory _data
    ) private returns (bool r) {
        if (to.isContract()) {
            r = true;
            for (
                uint256 tokenId = startTokenId;
                tokenId < startTokenId + quantity;
                tokenId++
            ) {
                try
                    IERC721Receiver(to).onERC721Received(
                        _msgSender(),
                        from,
                        tokenId,
                        _data
                    )
                returns (bytes4 retval) {
                    r =
                        r &&
                        retval == IERC721Receiver.onERC721Received.selector;
                } catch (bytes memory reason) {
                    if (reason.length == 0) {
                        revert(
                            "ERC721Psi: transfer to non ERC721Receiver implementer"
                        );
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
            return r;
        } else {
            return true;
        }
    }

    function _getBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        tokenIdBatchHead = _batchHead.scanForward(tokenId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * This function is compatiable with ERC721AQueryable.
     */
    function tokensOfOwner(address owner)
        external
        view
        virtual
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            return tokenIds;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}
