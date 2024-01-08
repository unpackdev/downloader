// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC165.sol";
import "./Address.sol";
import "./EnumerableMap.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";

import "./IERC20.sol"; // For NCT

// Interface to communicate with Hashmasks and BAYC contracts
import "./IERC721.sol";

/**
 * @title Bored Hash Galleries contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract Galleries is Context, Ownable, ERC165, IERC721Enumerable, IERC721Metadata {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Public variables

    // This is the provenance record of all Galleries artwork in existence
    string public galleriesProvenance;

    // Time after which Galleries are randomized and allotted
    uint256 public revealTimestamp = 1626530400; // 17 July

    uint256 public constant MAX_NFT_SUPPLY = 4000;

    bool public isSaleActive = false;

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to mask token ID
    mapping (uint256 => uint256) private _connectedNftIdFromToken;

    // Mapping from token ID to type of connected NFT (can be 'hashmask' or 'bayc')
    mapping (uint256 => string) private _connectedNftType;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping (string => address) private _nftContracts;

    // name of connected NFT => list of IDs connectd NFTs
    mapping (string => EnumerableSet.UintSet) private _reservedNfts;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Base URI
    string private _baseURI;

    // Name Changing Token (NCT) address
    address public nctAddress; // 0x8A9c4dfe8b9D8962B31e4e16F8321C44d48e246E

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *
     *     => 0x06fdde03 ^ 0x95d89b41 == 0x93254542
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    // Events
    event NftReserved (uint256 galleryId, uint256 indexed nftId, string nftType, address indexed ownerAddress);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name, string memory symbol, address _nctAddress) {
        _name = name;
        _symbol = symbol;
        nctAddress = _nctAddress;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function startSale() public onlyOwner {
        isSaleActive = true;
    }

    function pauseSale() public onlyOwner {
        isSaleActive = false;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        galleriesProvenance = provenanceHash;
    }

    function setRevealTimestamp(uint256 _revealTimestamp) public onlyOwner {
        revealTimestamp = _revealTimestamp;
    }

    /**
    * @dev Returns the base URI set via {setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Public function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * @dev Set contract address of NFT that can be connected to Galleries
     */
    function setNftContract(string memory nftType, address nftAddress) public onlyOwner {
        _nftContracts[nftType] = nftAddress;
    }

    /**
     * @dev Returns contract address of NFT (that can be connected to Galleries)
     * for the specific NFT type ('hashmask' or 'bayc')
     */
    function getNftContract(string memory nftType) public view returns (address) {
        return _nftContracts[nftType];
    }

    /**
     * @dev Returns if the NFT ID has been reserved.
     */
    function isNftIdReserved(string memory nftType, uint256 nftId) public view returns (bool) {
        return _reservedNfts[nftType].contains(nftId);
    }

    /**
     * @dev Returns type of connected NFT ('hashmask' or 'bayc') for the specific token ID
     */
    function getConnectedNftTypeFromToken(uint256 token) public view returns (string memory) {
        return _connectedNftType[token];
    }

    /**
     * @dev Returns ID of connected NFT for the specific token index
     */
    function getConnectedNftIdFromToken(uint256 token) public view returns (uint256) {
        require(_exists(token), "Token not exists");
        return _connectedNftIdFromToken[token];
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    /**
     * @dev Gets Gallery Price in ETH
     */
    function getNFTPriceInETH() public view returns (uint256) {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        return 60000000000000000; // 0.06 ETH
    }

    /**
     * @dev Gets Gallery Price in NCT
     *
     * Before calling this function, frontend should call "increaseAllowance" or "approve"
     * for the NCT contract
     */
    function getNFTPriceInNCT() public view returns (uint256) {
        uint priceInETH = getNFTPriceInETH();
        return priceInETH * 200000; // 1 ETH = 200k NCT; 1 Gallery = 12k NCT
    }

    /**
    * @dev Buy Galleries with NCT
    */
    function mintNFTWithNCT(uint256[] memory connectedNftIndices, string memory nftType) public {
        uint numberOfNfts = connectedNftIndices.length;

        uint price = getNFTPriceInNCT().mul(numberOfNfts);
        require(IERC20(nctAddress).transferFrom(msg.sender, address(this), price) == true, "Not enough NCT");

        mintNFT(connectedNftIndices, nftType);
    }

    /**
    * @dev Buy Galleries with ETH
    */
    function mintNFTWithETH(uint256[] memory connectedNftIndices, string memory nftType) public payable {
        uint numberOfNfts = connectedNftIndices.length;
        require(getNFTPriceInETH().mul(numberOfNfts) == msg.value, "Ether value sent is not correct");
        mintNFT(connectedNftIndices, nftType);
    }

    /**
    * @dev Mints Galleries
    */
    function mintNFT(uint256[] memory connectedNftIndices, string memory nftType) internal {
        uint numberOfNfts = connectedNftIndices.length;

        require(isSaleActive == true, "Sale is not active");
        require(_nftContracts[nftType] != address(0), "Incorrect nftType");
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= 5, "You may not buy more than 5 NFTs at once");
        require(totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");

        for (uint i = 0; i < numberOfNfts; i++) {

            // Duplicate token index check
            for (uint j = i + 1; j < numberOfNfts; j++) {
                require(connectedNftIndices[i] != connectedNftIndices[j], "Duplicate token index");
            }

            uint connectedNftId = connectedNftIndices[i];
            address connectedNftAddress = _nftContracts[nftType];

            require(IERC721(connectedNftAddress).ownerOf(connectedNftId) == msg.sender, "Sender is not the owner");

            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex, connectedNftId, nftType);
        }

        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= revealTimestamp)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Set the starting index block for the collection, essentially unblocking
    * setting starting index
    */
    function emergencySetStartingIndexBlock() public onlyOwner {
        require(startingIndexBlock == 0, "Starting index block is already set");
        require(startingIndex == 0, "Starting index is already set");

        startingIndexBlock = block.number;
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
    }

    /**
     * @dev Withdraw NCT and any others ERC20 tokens from this contract (Callable by owner)
    */
    function withdrawERC20(address tokenAddress) public onlyOwner {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(address to, uint256 tokenId, uint256 connectedNftId, string memory nftType) internal virtual {
        _safeMint(to, tokenId, connectedNftId, nftType, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, uint256 connectedNftId, string memory nftType, bytes memory _data) internal virtual {
        _mint(to, tokenId, connectedNftId, nftType);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _mint(address to, uint256 tokenId, uint256 connectedNftId, string memory nftType) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        require(tokenId < MAX_NFT_SUPPLY, "Exceeds MAX_NFT_SUPPLY");
        require(isNftIdReserved(nftType, connectedNftId) == false, "NFT id already reserved");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        _connectedNftIdFromToken[tokenId] = connectedNftId;
        _connectedNftType[tokenId] = nftType;

        _reservedNfts[nftType].add(connectedNftId);
        emit NftReserved(tokenId, connectedNftId, nftType, to);
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = baseURI();

        // concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }
}