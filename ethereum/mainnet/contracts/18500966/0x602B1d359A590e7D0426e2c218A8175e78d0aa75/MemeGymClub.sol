// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**

███╗   ███╗███████╗███╗   ███╗███████╗    
████╗ ████║██╔════╝████╗ ████║██╔════╝    
██╔████╔██║█████╗  ██╔████╔██║█████╗      
██║╚██╔╝██║██╔══╝  ██║╚██╔╝██║██╔══╝      
██║ ╚═╝ ██║███████╗██║ ╚═╝ ██║███████╗    
╚═╝     ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝    
                                          
 ██████╗██╗   ██╗███╗   ███╗              
██╔════╝╚██╗ ██╔╝████╗ ████║              
██║  ███╗╚████╔╝ ██╔████╔██║              
██║   ██║ ╚██╔╝  ██║╚██╔╝██║              
╚██████╔╝  ██║   ██║ ╚═╝ ██║              
 ╚═════╝   ╚═╝   ╚═╝     ╚═╝              
                                          
 ██████╗██╗     ██╗   ██╗██████╗          
██╔════╝██║     ██║   ██║██╔══██╗         
██║     ██║     ██║   ██║██████╔╝         
██║     ██║     ██║   ██║██╔══██╗         
╚██████╗███████╗╚██████╔╝██████╔╝         
 ╚═════╝╚══════╝ ╚═════╝ ╚═════╝          

License Agreement for "Meme Gym Club" NFT Collection

This License Agreement (the "Agreement") is entered into between the Licensee and the Licensor for the "Meme Gym Club" NFT collection (the "Collection"). By minting and/or using any NFT from the Collection, you (the "Licensee") agree to be bound by the following terms and conditions:

1. Supply: The Collection consists of 3333 NFTs, and each Licensee is allowed to mint up to 4 NFTs for free. Beyond this limit, additional NFTs may be obtained through a voluntary donation at a price of 0.0003 ETH per NFT.

2. License: All NFTs in the "Meme Gym Club" Collection are offered under the CC0 license. This means they are released into the public domain, and Licensee can use, share, modify, and distribute them without restrictions.

3. AS IS: The Licensor makes no representations or warranties regarding the financial, legal, or any other benefits to the Licensee resulting from the use or possession of NFTs from the Collection. The Licensor does not promise or guarantee any particular outcome, including but not limited to, financial gain, legal protections, or any other form of advantage.

4. Blockchain: The NFTs in the "Meme Gym Club" Collection are minted on the Ethereum blockchain.

5. Disclaimer of Liability: The Licensor shall not be held responsible for any financial losses, damages, or liabilities incurred by the Licensee while interacting with third parties, using the NFTs, or due to security breaches in the Licensee's electronic wallet. The Licensee understands that the Licensor cannot guarantee the security of the Licensee's digital assets or the actions of other parties in the blockchain space.

6. By minting any NFT from the "Meme Gym Club" Collection, the Licensee automatically agrees to and accepts all the terms and conditions of this Agreement. It is the Licensee's responsibility to review and understand the terms outlined herein before proceeding with minting or using any NFTs from the Collection.

7. This Agreement is a legally binding contract, and the Licensee is advised to seek legal counsel if they have any questions or concerns about its terms. The Licensor reserves the right to amend this Agreement at any time, and it is the Licensee's responsibility to stay informed about any updates or changes.

*/


interface IERC721A {

    error ApprovalCallerNotOwnerNorApproved();

    error ApprovalQueryForNonexistentToken();

    error ApproveToCaller();

    error BalanceQueryForZeroAddress();

    error MintToZeroAddress();

    error MintZeroQuantity();

    error OwnerQueryForNonexistentToken();

    error TransferCallerNotOwnerNorApproved();

    error TransferFromIncorrectOwner();

    error TransferToNonERC721ReceiverImplementer();

    error TransferToZeroAddress();

    error URIQueryForNonexistentToken();

    error MintERC2309QuantityExceedsLimit();

    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}


contract MemeGymClub is IERC721A { 

    address private _owner;
    function owner() public view returns(address){
        return _owner;
    }

    uint256 public constant MAX_SUPPLY = 3333; // Total collection supply

    uint256 public MAX_FREE = 3333; // Free mint supply

    uint256 public MAX_FREE_PER_WALLET = 4; // Free mint limit per wallet

    uint256 public COST = 0.0003 ether; // Donation per wallet

    string private constant _name = "Meme Gym Club";
    string private constant _symbol = "MGC";

    string private _baseURI = "bafybeihjj2ygw3q66ej5rffb7foe73ocs5l5yb7zzi4kg2gzqy44yeg6t4";

    constructor() {
        _owner = msg.sender;
    }

    function mint(uint256 amount) external payable{
        address _caller = _msgSenderERC721A();

        require(totalSupply() + amount <= MAX_SUPPLY, "Sold Out");
        require(amount*COST <= msg.value, "Value to Low");

        _mint(_caller, amount);
    }

    function freeMint() external nob{
        address _caller = _msgSenderERC721A();
        uint256 amount = MAX_FREE_PER_WALLET;

        require(totalSupply() + amount <= MAX_FREE, "Freemint Sold Out");
        require(amount + _numberMinted(_caller) <= MAX_FREE_PER_WALLET, "Max per Wallet");

        _mint(_caller, amount);
    }

    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    uint256 private constant BITPOS_AUX = 192;

    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    uint256 private constant BITMASK_BURNED = 1 << 224;

    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    uint256 private _currentIndex = 0;

    mapping(uint256 => uint256) private _packedOwnerships;

    mapping(address => uint256) private _packedAddressData;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function setConfig(uint _MAX_FREE, uint _COST, uint _MAX_FREE_PER_WALLET) external onlyOwner{
        MAX_FREE = _MAX_FREE;
        COST = _COST;
        MAX_FREE_PER_WALLET = _MAX_FREE_PER_WALLET;
    }

    function setData(string memory _base) external onlyOwner{
        _baseURI = _base;
    }

    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {

        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (_addressToUint256(owner) == 0) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & BITMASK_BURNED == 0) {

                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
    }

    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI;
        return bytes(baseURI).length != 0 ? string(abi.encodePacked("ipfs://", baseURI, "/", _toString(tokenId), ".json")) : "";
    }

    function _addressToUint256(address value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    function _boolToUint256(bool value) private pure returns (uint256 result) {
        assembly {
            result := value
        }
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = address(uint160(_packedOwnershipOf(tokenId)));
        if (to == owner) revert();

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
            address from,
            address to,
            uint256 tokenId
            ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId
            ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
            address from,
            address to,
            uint256 tokenId,
            bytes memory _data
            ) public virtual override {
        _transfer(from, to, tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex;
    }

    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (_addressToUint256(to) == 0) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        unchecked {

            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            _packedOwnerships[startTokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                (_boolToUint256(quantity == 1) << BITPOS_NEXT_INITIALIZED);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
            address from,
            address to,
            uint256 tokenId
            ) private {

        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        address approvedAddress = _tokenApprovals[tokenId];

        bool isApprovedOrOwner = (_msgSenderERC721A() == from ||
                isApprovedForAll(from, _msgSenderERC721A()) ||
                approvedAddress == _msgSenderERC721A());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();


        // Clear approvals from the previous owner.
        if (_addressToUint256(approvedAddress) != 0) {
            delete _tokenApprovals[tokenId];
        }

        unchecked {

            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            _packedOwnerships[tokenId] =
                _addressToUint256(to) |
                (block.timestamp << BITPOS_START_TIMESTAMP) |
                BITMASK_NEXT_INITIALIZED;

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _afterTokenTransfers(
            address from,
            address to,
            uint256 startTokenId,
            uint256 quantity
            ) internal virtual {}

    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {

            ptr := add(mload(0x40), 128)

         // Update the free memory pointer to allocate.
         mstore(0x40, ptr)

         // Cache the end of the memory to calculate the length later.
         let end := ptr

         for { 
             // Initialize and perform the first pass without check.
             let temp := value
                 // Move the pointer 1 byte leftwards to point to an empty character slot.
                 ptr := sub(ptr, 1)
                 // Write the character to the pointer. 48 is the ASCII index of '0'.
                 mstore8(ptr, add(48, mod(temp, 10)))
                 temp := div(temp, 10)
         } temp { 
             // Keep dividing `temp` until zero.
        temp := div(temp, 10)
         } { 
             // Body of the for loop.
        ptr := sub(ptr, 1)
         mstore8(ptr, add(48, mod(temp, 10)))
         }

     let length := sub(end, ptr)
         // Move the pointer 32 bytes leftwards to make room for the length.
         ptr := sub(ptr, 32)
         // Store the length.
         mstore(ptr, length)
        }
    }

    modifier onlyOwner() { 
        require(_owner==msg.sender, "not Owner");
        _; 
    }

    modifier nob() {
        require(tx.origin==msg.sender, "no Script");
        _;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}