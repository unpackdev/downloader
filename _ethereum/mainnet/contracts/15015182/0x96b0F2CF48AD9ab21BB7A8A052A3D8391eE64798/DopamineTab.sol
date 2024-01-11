// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "./Errors.sol";
import "./IDopamineTab.sol";
import "./IOpenSeaProxyRegistry.sol";

import "./ERC721.sol";
import "./ERC721Votable.sol";

/// @title Dopamine Membership Tab
/// @notice Tab holders are first-class members of the Dopamine metaverse.
///  The tabs are minted through seasonal drops of varying sizes and durations,
///  with each drop featuring different sets of attributes. Drop parameters are
///  configurable by the admin address, with emissions controlled by the minter
///  address. A drop is completed once all non-allowlisted tabs are minted.
contract DopamineTab is ERC721Votable, IDopamineTab {

    /// @notice The maximum number of tabs that may be allowlisted per drop.
    uint256 public constant MAX_AL_SIZE = 99;

    /// @notice The minimum number of tabs that can be minted for a drop.
    uint256 public constant MIN_DROP_SIZE = 1;

    /// @notice The maximum number of tabs that can be minted for a drop.
    uint256 public constant MAX_DROP_SIZE = 9999;

    /// @notice The minimum delay required to wait between creations of drops.
    uint256 public constant MIN_DROP_DELAY = 1 days;

    /// @notice The maximum delay required to wait between creations of drops.
    uint256 public constant MAX_DROP_DELAY = 24 weeks;

    /// @notice The address administering drop creation, sizing, and scheduling.
    address public admin;

    /// @notice The temporary address that will become admin once accepted.
    address public pendingAdmin;

    /// @notice The address responsible for controlling tab emissions.
    address public minter;

    /// @notice The OS registry address - allowlisted for gasless OS approvals.
    IOpenSeaProxyRegistry public proxyRegistry;

    /// @notice The URI each tab initially points to for metadata resolution.
    /// @dev Before drop completion, `tokenURI()` resolves to "{baseURI}/{id}".
    string public baseURI;

    /// @notice The minimum time to wait in seconds between drop creations.
    uint256 public dropDelay;

    /// @notice The current drop's ending tab id (exclusive boundary).
    uint256 public dropEndIndex;

    /// @notice The time at which a new drop can start (if last drop completes).
    uint256 public dropEndTime;

    /// @notice Maps a drop to its allowlist (merkle tree root).
    mapping(uint256 => bytes32) public dropAllowlist;

    /// @notice Maps a drop to its provenance hash (concatenated image hash).
    mapping(uint256 => bytes32) public dropProvenanceHash;

    /// @notice Maps a drop to its finalized IPFS / Arweave tab metadata URI.
    mapping(uint256 => string) public dropURI;

    /// @dev Maps a drop id to its ending tab id (exclusive boundary).
    uint256[] private _dropEndIndices;

    /// @dev An internal tracker for the id of the next tab to mint.
    uint256 private _id;

    /// @dev Restricts a function call to address `minter`.
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert MinterOnly();
        }
        _;
    }

    /// @dev Restricts a function call to address `admin`.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        _;
    }

    /// @notice Initializes the membership tab with the specified drop settings.
    /// @param minter_ The address which will control tab emissions.
    /// @param proxyRegistry_ The OS proxy registry address.
    /// @param dropDelay_ The minimum delay to wait between drop creations.
    /// @param maxSupply_ The supply for the tab collection.
    constructor(
        string memory baseURI_,
        address minter_,
        address proxyRegistry_,
        uint256 dropDelay_,
        uint256 maxSupply_
    ) ERC721Votable("Dopamine Tabs", "TAB", maxSupply_) {
        admin = msg.sender;
        emit AdminChanged(address(0), admin);

        minter = minter_;
        emit MinterChanged(address(0), minter);

        baseURI = baseURI_;
        emit BaseURISet(baseURI);

        proxyRegistry = IOpenSeaProxyRegistry(proxyRegistry_);

        setDropDelay(dropDelay_);
    }

    /// @inheritdoc IDopamineTab
    function contractURI() external view returns (string memory)  {
        return string(abi.encodePacked(baseURI, "contract"));
    }

    /// @inheritdoc ERC721
    /// @dev Before drop completion, the token URI for tab of id `id` defaults
    ///  to {baseURI}/{id}. Once the drop completes, it is replaced by an IPFS /
    ///  Arweave URI, and `tokenURI()` will resolve to {dropURI[dropId]}/{id}.
    ///  This function reverts if the queried tab of id `id` does not exist.
    /// @param id The id of the NFT being queried.
    function tokenURI(uint256 id)
        external
        view
        override(ERC721)
        returns (string memory)
    {
        if (ownerOf[id] == address(0)) {
            revert TokenNonExistent();
        }

        string memory uri = dropURI[dropId(id)];
        if (bytes(uri).length == 0) {
            uri = baseURI;
        }
        return string(abi.encodePacked(uri, _toString(id)));
    }


    /// @dev Ensures OS proxy is allowlisted for operating on behalf of owners.
    /// @inheritdoc ERC721
    function isApprovedForAll(address owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return
            proxyRegistry.proxies(owner) == operator ||
            _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IDopamineTab
    function mint() external onlyMinter returns (uint256) {
        if (_id >= dropEndIndex) {
            revert DropMaxCapacity();
        }
        return _mint(minter, _id++);
    }

    /// @inheritdoc IDopamineTab
    function claim(bytes32[] calldata proof, uint256 id) external {
        if (id >= _id) {
            revert ClaimInvalid();
        }

        bytes32 allowlist = dropAllowlist[dropId(id)];
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, id));

        if (!_verify(allowlist, proof, leaf)) {
            revert ProofInvalid();
        }

        _mint(msg.sender, id);
    }

    /// @inheritdoc IDopamineTab
    function createDrop(
        uint256 dropId,
        uint256 startIndex,
        uint256 dropSize,
        bytes32 provenanceHash,
        uint256 allowlistSize,
        bytes32 allowlist
    )
        external
        onlyAdmin
    {
        if (_id < dropEndIndex) {
            revert DropOngoing();
        }
        if (startIndex != _id) {
            revert DropStartInvalid();
        }
        if (dropId != _dropEndIndices.length) {
            revert DropInvalid();
        }
        if (block.timestamp < dropEndTime) {
            revert DropTooEarly();
        }
        if (allowlistSize > MAX_AL_SIZE || allowlistSize > dropSize) {
            revert DropAllowlistOverCapacity();
        }
        if (
            dropSize < MIN_DROP_SIZE ||
            dropSize > MAX_DROP_SIZE
        ) {
            revert DropSizeInvalid();
        }
        if (_id + dropSize > maxSupply) {
            revert DropMaxCapacity();
        }

        dropEndIndex = _id + dropSize;
        _id += allowlistSize;
        _dropEndIndices.push(dropEndIndex);

        dropEndTime = block.timestamp + dropDelay;

        dropProvenanceHash[dropId] = provenanceHash;
        dropAllowlist[dropId] = allowlist;

        emit DropCreated(
            dropId,
            startIndex,
            dropSize,
            allowlistSize,
            allowlist,
            provenanceHash
        );
    }

    /// @inheritdoc IDopamineTab
    function setMinter(address newMinter) external onlyAdmin {
        emit MinterChanged(minter, newMinter);
        minter = newMinter;
    }

    /// @inheritdoc IDopamineTab
    function setPendingAdmin(address newPendingAdmin)
        public
        override
        onlyAdmin
    {
        pendingAdmin = newPendingAdmin;
        emit PendingAdminSet(pendingAdmin);
    }

    /// @inheritdoc IDopamineTab
    function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

        emit AdminChanged(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /// @inheritdoc IDopamineTab
    function setDropURI(uint256 id, string calldata uri)
        external
        onlyAdmin
    {
        uint256 numDrops = _dropEndIndices.length;
        if (id >= numDrops) {
            revert DropNonExistent();
        }
        dropURI[id] = uri;
        emit DropURISet(id, uri);
    }


    /// @inheritdoc IDopamineTab
    function updateDrop(
        uint256 dropId,
        bytes32 provenanceHash,
        bytes32 allowlist
    ) external onlyAdmin {
        uint256 numDrops = _dropEndIndices.length;
        if (dropId >= numDrops) {
            revert DropNonExistent();
        }

        // Once a drop's URI is set, it may not be modified.
        if (bytes(dropURI[dropId]).length != 0) {
            revert DropImmutable();
        }

        dropProvenanceHash[dropId] = provenanceHash;
        dropAllowlist[dropId] = allowlist;

        emit DropUpdated(
            dropId,
            provenanceHash,
            allowlist
        );
    }

    /// @inheritdoc IDopamineTab
    function setBaseURI(string calldata newBaseURI) public onlyAdmin {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @inheritdoc IDopamineTab
    function setDropDelay(uint256 newDropDelay) public override onlyAdmin {
        if (newDropDelay < MIN_DROP_DELAY || newDropDelay > MAX_DROP_DELAY) {
            revert DropDelayInvalid();
        }
        dropDelay = newDropDelay;
        emit DropDelaySet(dropDelay);
    }

    /// @inheritdoc IDopamineTab
    function dropId(uint256 id) public view returns (uint256) {
        for (uint256 i = 0; i < _dropEndIndices.length; i++) {
            if (id  < _dropEndIndices[i]) {
                return i;
            }
        }
        revert DropNonExistent();
    }

    /// @dev Checks whether `leaf` is part of merkle tree rooted at `merkleRoot`
    ///  using proof `proof`. Merkle tree generation and proof construction is
    ///  done using the following JS library: github.com/miguelmota/merkletreejs
    /// @param merkleRoot The hexlified merkle root as a bytes32 data type.
    /// @param proof The abi-encoded proof formatted as a bytes32 array.
    /// @param leaf The leaf node being checked (uses keccak-256 hashing).
    /// @return True if `leaf` is in `merkleRoot`-rooted tree, False otherwise.
    function _verify(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes32 leaf
    ) private pure returns (bool)
    {
        bytes32 hash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (hash <= proofElement) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }
        }
        return hash == merkleRoot;
    }

    /// @dev Converts a uint256 into a string.
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
