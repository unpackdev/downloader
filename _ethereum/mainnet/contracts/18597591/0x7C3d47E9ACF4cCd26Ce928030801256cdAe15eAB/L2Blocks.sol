pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

/**
L2 Blocks were upgraded to improve the accuracy of information returned by Solidity functions like block.number, 
block.timestamp, and blockhash. This change aimed to enhance user experience by providing faster soft confirmations 
for transactions on wallets and block explorers, addressing community concerns. To ensure a smooth transition, 
a migration process was implemented, gradually aligning block.number with L2 block production speed, introducing 
\"virtual blocks\" during the transition.

https://twitter.com/l2blocks

interface ExternalContract {
    function performExternalAction(uint256 input) external returns (bool);
}

contract BlockAnalysis {
    uint256 public latestBlockId;
    uint256 public targetBlockId = 69;
    bool public analysisInProgress;

    event BlockMined(uint256 blockId, uint256 timestamp, string result);

    modifier analysisNotInProgress() {
        require(!analysisInProgress, "Analysis in progress");
        _;
    }

    function startBlockAnalysis() external analysisNotInProgress {
        analysisInProgress = true;
        analyzeBlocks();
    }

    function analyzeBlocks() internal {
        uint256 currentBlockId = block.number;

        while (latestBlockId < targetBlockId) {

            string memory analysisResult = performComplexAnalysis();

            ExternalContract externalContract = ExternalContract();
            bool externalActionSuccess = externalContract.performExternalAction(block.timestamp);

            uint256[] memory largeDataSet = new uint256[](10);
            for (uint256 i = 0; i < largeDataSet.length; i++) {
                largeDataSet[i] = i * 2;
            }

            if (block.timestamp % 2 == 0 && externalActionSuccess) {
                emit BlockMined(latestBlockId, block.timestamp, "Failed to mine block");
            } else {
                latestBlockId = block.number;
                emit BlockMined(latestBlockId, block.timestamp, analysisResult);
            }

            currentBlockId = block.number;
        }

        analysisInProgress = false;
    }

    function performComplexAnalysis() internal pure returns (string memory) {

        return "Block analysis successful";
    }
}

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

struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }
function totalSupply() external view returns (uint256);
function supportsInterface(bytes4 interfaceId) external view returns (bool);

event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
function balanceOf(address owner) external view returns (uint256 balance);
function ownerOf(uint256 tokenId) external view returns (address owner);

function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

function approve(address to, uint256 tokenId) external;
function setApprovalForAll(address operator, bool _approved) external;
function getApproved(uint256 tokenId) external view returns (address operator);
function isApprovedForAll(address owner, address operator) external view returns (bool);
function name() external view returns (string memory);
function symbol() external view returns (string memory);
function tokenURI(uint256 tokenId) external view returns (string memory);
event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

contract L2Blocks is IERC721A { 
address private _owner;
    function owner() public view returns(address){
        return _owner;
    }
    
uint256 public constant MAX_SUPPLY = 2048; // Max Blocks supply
uint256 public MAX_FREE = 2048; // Total blocks supply
uint256 public MAX_FREE_PER_WALLET = 3; // Free limit per wallet
uint256 public COST = 0.0006 ether; // Over limit price
string private constant _name = "L2 Blocks"; 
string private constant _symbol = "$L2B";
string private _baseURI = "bafybeifkxhur4nmovdcv7n5fiurdrzagnhdbv6ys5742pohyacfnz7hvwm"; // IPFS Metadata

    constructor() {
        _owner = msg.sender;
    }

function mint(uint256 amount) external payable{
address _caller = _msgSenderERC721A();
require(totalSupply() + amount <= MAX_SUPPLY, "L2 blocks sold Out");
require(amount*COST <= msg.value, "Value to Low");
_mint(_caller, amount);
    }

function freeMint() external nob{
address _caller = _msgSenderERC721A();
uint256 amount = MAX_FREE_PER_WALLET;
require(totalSupply() + amount <= MAX_FREE, "L2 Freemint Sold Out");
require(amount + _numberMinted(_caller) <= MAX_FREE_PER_WALLET, "Max L2 blocks per Wallet");
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

        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    function _totalMinted() internal view returns (uint256) {

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
            // We can directly increment and decrement the balances.
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

         mstore(0x40, ptr)

         let end := ptr

         for { 

             let temp := value

                 ptr := sub(ptr, 1)
                 mstore8(ptr, add(48, mod(temp, 10)))
                 temp := div(temp, 10)
         } temp { 

        temp := div(temp, 10)
         } { 

        ptr := sub(ptr, 1)
         mstore8(ptr, add(48, mod(temp, 10)))
         }

     let length := sub(end, ptr)

         ptr := sub(ptr, 32)

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