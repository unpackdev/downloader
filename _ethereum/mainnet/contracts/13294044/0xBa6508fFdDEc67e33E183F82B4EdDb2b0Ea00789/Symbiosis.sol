// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./ERC165.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Counters.sol";
import "./Context.sol";
import "./Ownable.sol";

/**
 *
 *     S Y M B I O S I S
 *
 *                 _________________ by Lucien Loiseau (MetaPixel.art)
 *
 * This file contains the source code for the ERC-721 smart contract driving
 * the NFT logic for the project "Symbiosis" (https://symbiosis.metapixel.art).
 *
 */

contract Symbiosis is
    Context,
    Ownable,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    string private _name = "Symbiosis";
    string private _symbol = "SYMBIOS";

    // max supply and price
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 20;
    uint256 public constant TOKEN_LIMIT = 2048;
    uint256 private tokenPrice = 250 * 1000000000000000 wei;

    // artist
    uint256 public ARTIST_PRINTS = 128;
    address payable public constant ARTIST_WALLET =
        payable(0xde00d5483e685c67E83c0C639322150B0365fFfa);

    // Total amount of tokens
    Counters.Counter private _totalMinted;

    // reference to the generator on IPFS
    string public generatorIpfsHash = "";
    string public playerJsIpfsHash = "";
    string public webPlayerIpfsHash = "";
    bool public isLocked = false;

    // -----  Symbiosis NFT's history -----

    struct Ownership {
        address account;
        uint256 timestamp;
    }

    // Mapping token ID to owner's history
    mapping(uint256 => Ownership[]) private _owners;
    string public baseURI = "https://assets.symbiosis.metapixel.art/metadata/";

    // -----  IERC 721 ENUMERABLE -----

    // Mapping address to list of owned tokens
    mapping(address => uint256[]) private _tokensOf;
    // Mapping tokenId to index in owner's set
    mapping(uint256 => uint256) internal _idToOwnerIndex;

    // -----  IERC 721 APPROVALS -----

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor() {}

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
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalMinted.current();
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return tokenId < _totalMinted.current();
    }

    /**
     * @dev returns all the token owned by an owner
     */
    function tokensOf(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return _tokensOf[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        override
        returns (uint256)
    {
        require(index < balanceOf(owner), "Symbiosis: index out of range");
        return _tokensOf[owner][index];
    }

    function tokenByIndex(uint256 index)
        external
        pure
        override
        returns (uint256)
    {
        return index;
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
            "Symbiosis: balance query for the zero address"
        );
        return _tokensOf[owner].length;
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
        require(
            tokenId < TOKEN_LIMIT,
            "Symbiosis: owner query for nonexistent token"
        );
        require(
            _exists(tokenId),
            "Symbiosis: owner query for unminted token"
        );

        uint256 length = _owners[tokenId].length;
        return _owners[tokenId][length - 1].account;
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
        require(
            _exists(tokenId),
            "Symbiosis: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev ownership history
     */
    function tokenHistory(uint256 tokenId)
        public
        view
        returns (Ownership[] memory)
    {
        require(
            _exists(tokenId),
            "Symbiosis: unminted token has no history"
        );
        return _owners[tokenId];
    }

    /**
     * @dev seed generates token history as a compact hexadecimal string
     */
    function tokenArtSeed(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Symbiosis: unminted token has no seed");

        uint256 nbOfOwner = _owners[tokenId].length;

        bytes memory _output = new bytes((2 + (20 + 5) * nbOfOwner + 5) * 2);
        uint256 _offst = 0;

        uintToHexString(_output, _offst, tokenId, 2);
        _offst += 4;

        uint256 i;
        for (i = 0; i < nbOfOwner; i++) {
            uintToHexString(
                _output,
                _offst,
                uint160(_owners[tokenId][i].account),
                20
            );
            _offst += 40;

            uintToHexString(_output, _offst, _owners[tokenId][i].timestamp, 5);
            _offst += 10;
        }

        uintToHexString(_output, _offst, block.timestamp, 5);
        _offst += 10;

        return string(_output);
    }

    function uintToHexString(
        bytes memory _output,
        uint256 _offst,
        uint256 a,
        uint256 precision
    ) internal pure {
        uint256 value = a;
        uint256 i;
        for (i = (_offst + (precision * 2)); i > _offst; i--) {
            uint8 _f = uint8(value & 0x0f);
            uint8 _l = uint8((value & 0xf0) >> 4);

            _output[i - 1] = _f > 9 ? bytes1(87 + _f) : bytes1(48 + _f);
            i = i - 1;
            _output[i - 1] = _l > 9 ? bytes1(87 + _l) : bytes1(48 + _l);

            value = value >> 8;
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = Symbiosis.ownerOf(tokenId);
        require(to != owner, "Symbiosis: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "Symbiosis: approve caller is not owner nor approved for all"
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
            "Symbiosis: approved query for nonexistent token"
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
        require(operator != _msgSender(), "Symbiosis: approve to caller");

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
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "Symbiosis: operator query for nonexistent token"
        );
        address owner = Symbiosis.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    function artistMint(uint256 quantity, address to) external onlyOwner {
        require(
            ARTIST_PRINTS >= quantity,
            "Symbiosis: not enough artist prints"
        );
        require(
            (_totalMinted.current() + quantity) <= TOKEN_LIMIT,
            "Symbiosis: not enough token left to mint"
        );

        ARTIST_PRINTS -= quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _createNft(to);
        }
    }

    function mint(uint256 _count) external payable {
        require(
            (_totalMinted.current() + _count) <= TOKEN_LIMIT,
            "Symbiosis: exceed maximum token limit"
        );
        require(
            _count > 0 && _count < MAX_TOKENS_PER_PURCHASE + 1,
            "Symbiosis: exceeds maximum purchase in a single transaction"
        );

        uint256 mintPrice = tokenPrice * _count;
        require(
            msg.value >= mintPrice,
            "Symbiosis: not enough Ether to mint the art"
        );

        // mint tokens
        uint256 tokenId;
        for (uint256 i = 0; i < _count; i++) {
            tokenId = _createNft(_msgSender());
        }

        // send the change back if any
        uint256 change = (msg.value - mintPrice);
        if (change > 0) {
            (bool changeSent, ) = _msgSender().call{value: change}("");
            require(changeSent, "Failed to send change to buyer");
        }

        // pay the artist
        (bool paymentSent, ) = ARTIST_WALLET.call{value: mintPrice}("");
        require(paymentSent, "Failed to send Ether to artist wallet");

        require(
            _checkOnERC721Received(address(0), _msgSender(), tokenId, ""),
            "Symbiosis: transfer to non ERC721Receiver implementer"
        );
    }

    function _createNft(address to) private returns (uint256) {
        uint256 newTokenId = _totalMinted.current();

        // update erc721 enumerables
        _tokensOf[to].push(newTokenId);
        _idToOwnerIndex[newTokenId] = _tokensOf[to].length - 1;

        // updte nft art history
        _owners[newTokenId].push(
            Ownership({account: to, timestamp: block.timestamp})
        );

        // update minted token count
        _totalMinted.increment();

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
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
            "Symbiosis: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "Symbiosis: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Symbiosis: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(
            Symbiosis.ownerOf(tokenId) == from,
            "Symbiosis: transfer from of token that is not own"
        );
        require(
            to != address(0),
            "Symbiosis: transfer to the zero address"
        );
        require(to != from, "Symbiosis: transfer to the same address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        // transfer token
        _removeNFTokenFromOwner(from, tokenId);
        _addNFTokenToOwner(to, tokenId);

        // update token history
        _owners[tokenId].push(
            Ownership({account: to, timestamp: block.timestamp})
        );

        emit Transfer(from, to, tokenId);
    }

    function _removeNFTokenFromOwner(address from, uint256 tokenId) internal {
        uint256 tokenToRemoveIndex = _idToOwnerIndex[tokenId];
        uint256 lastTokenIndex = _tokensOf[from].length - 1;

        if (tokenToRemoveIndex != lastTokenIndex) {
            uint256 lastTokenId = _tokensOf[from][lastTokenIndex];
            _tokensOf[from][tokenToRemoveIndex] = lastTokenId;
            _idToOwnerIndex[lastTokenId] = tokenToRemoveIndex;
        }

        delete _idToOwnerIndex[tokenId];
        _tokensOf[from].pop();
    }

    function _addNFTokenToOwner(address to, uint256 tokenId) internal {
        _tokensOf[to].push(tokenId);
        _idToOwnerIndex[tokenId] = _tokensOf[to].length - 1;
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(Symbiosis.ownerOf(tokenId), to, tokenId);
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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "Symbiosis: transfer to non ERC721Receiver implementer"
                    );
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function getPrice() public view returns (uint256) {
        return tokenPrice;
    }

    function setGeneratorIpfsHash(string memory ipfsHash) public onlyOwner {
        require(!isLocked, "contract locked, cannot be set");
        generatorIpfsHash = ipfsHash;
    }

    function setPlayerJsIpfsHash(string memory ipfsHash) public onlyOwner {
        require(!isLocked, "contract locked, cannot be set");
        playerJsIpfsHash = ipfsHash;
    }

    function setWebPlayerIpfsHash(string memory ipfsHash) public onlyOwner {
        require(!isLocked, "contract locked, cannot be set");
        webPlayerIpfsHash = ipfsHash;
    }

    function lock() public onlyOwner {
        require(!isLocked, "contract already locked");
        isLocked = true;
    }
}
