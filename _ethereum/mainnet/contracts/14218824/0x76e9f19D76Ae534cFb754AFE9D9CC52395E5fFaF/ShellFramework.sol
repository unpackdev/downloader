//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ERC165Checker.sol";
import "./IShellFramework.sol";

// Abstract implementation of the shell framework interface -- can be used as a
// base for all shell collections
abstract contract ShellFramework is IShellFramework, Initializable {
    // fork data
    mapping(uint256 => Fork) private _forks;

    // token id -> fork id
    mapping(uint256 => uint256) private _tokenForks;

    // all stored strings
    mapping(bytes32 => string) private _stringStorage;

    // all stored ints
    mapping(bytes32 => uint256) private _intStorage;

    // token id serial number
    uint256 public nextTokenId;

    // fork id serial number
    uint256 public nextForkId;

    // ensure that the deployed implementation cannot be initialized after
    // deployment. Clones do not trigger the constructor but are manually
    // initted by ShellFactory
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    // used to initialize the clone
    // solhint-disable-next-line func-name-mixedcase
    function __ShellFramework_init(IEngine engine, address owner_)
        internal
        onlyInitializing
    {
        nextTokenId = 1;
        nextForkId = 1;

        // not using createFork for initial fork
        _forks[0].engine = engine;
        _forks[0].owner = owner_;
        engine.afterEngineSet(0);
        emit ForkCreated(0, engine, owner_);
    }

    // ---
    // Fork functionality
    // ---

    function createFork(
        IEngine engine,
        address owner_,
        uint256[] calldata tokenIds
    ) external returns (uint256) {
        if (
            !ERC165Checker.supportsInterface(
                address(engine),
                type(IEngine).interfaceId
            )
        ) {
            revert InvalidEngine();
        }

        uint256 forkId = nextForkId++;
        _forks[forkId].engine = engine;
        _forks[forkId].owner = owner_;
        emit ForkCreated(forkId, engine, owner_);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            setTokenFork(tokenIds[i], forkId);
        }

        engine.afterEngineSet(forkId);

        return forkId;
    }

    // Set the fork of a specific token. Must be token owner
    function setTokenFork(uint256 tokenId, uint256 forkId) public override {
        if (!canSenderForkToken(msg.sender, tokenId)) {
            revert SenderCannotFork();
        }

        _forkToken(tokenId, forkId);
    }

    function setTokenForks(uint256[] memory tokenIds, uint256 forkId)
        external
        override
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!canSenderForkToken(msg.sender, tokenIds[i])) {
                revert SenderCannotFork();
            }

            _forkToken(tokenIds[i], forkId);
        }
    }

    function canSenderForkToken(address, uint256)
        public
        view
        virtual
        returns (bool)
    {
        // by default, do not allow forking
        return false;
    }

    function _forkToken(uint256 tokenId, uint256 forkId) internal {
        _tokenForks[tokenId] = forkId;
        emit TokenForkUpdated(tokenId, forkId);
    }

    function setForkEngine(uint256 forkId, IEngine engine) external {
        if (msg.sender != _forks[forkId].owner) {
            revert SenderNotForkOwner();
        }

        if (
            !ERC165Checker.supportsInterface(
                address(engine),
                type(IEngine).interfaceId
            )
        ) {
            revert InvalidEngine();
        }

        _forks[forkId].engine = engine;
        emit ForkEngineUpdated(forkId, engine);
        engine.afterEngineSet(forkId);
    }

    function setForkOwner(uint256 forkId, address owner_) external {
        if (msg.sender != _forks[forkId].owner) {
            revert SenderNotForkOwner();
        }

        _forks[forkId].owner = owner_;
        emit ForkOwnerUpdated(forkId, owner_);
    }

    // ---
    // Fork views
    // ---

    function owner() external view returns (address) {
        return _forks[0].owner; // collection owner = fork 0 owner
    }

    function getFork(uint256 forkId) public view returns (Fork memory) {
        return _forks[forkId];
    }

    function getForkEngine(uint256 forkId) public view returns (IEngine) {
        return _forks[forkId].engine;
    }

    function getForkOwner(uint256 forkId) public view returns (address) {
        return _forks[forkId].owner;
    }

    function getTokenForkId(uint256 tokenId) public view returns (uint256) {
        return _tokenForks[tokenId];
    }

    function getTokenEngine(uint256 tokenId) public view returns (IEngine) {
        return _forks[_tokenForks[tokenId]].engine;
    }

    // ---
    // Standard mint functionality
    // ---

    function _writeMintData(uint256 tokenId, MintEntry calldata entry)
        internal
    {
        // write engine-provided immutable data

        for (uint256 i = 0; i < entry.options.stringData.length; i++) {
            _writeTokenString(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.stringData[i].key,
                entry.options.stringData[i].value
            );
        }

        for (uint256 i = 0; i < entry.options.intData.length; i++) {
            _writeTokenInt(
                StorageLocation.MINT_DATA,
                tokenId,
                entry.options.intData[i].key,
                entry.options.intData[i].value
            );
        }

        // write framework immutable data

        if (entry.options.storeEngine) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "engine",
                uint256(uint160(address(getForkEngine(0))))
            );
        }
        if (entry.options.storeMintedTo) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "mintedTo",
                uint256(uint160(address(entry.to)))
            );
        }
        if (entry.options.storeTimestamp) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "timestamp",
                // solhint-disable-next-line not-rely-on-time
                block.timestamp
            );
        }
        if (entry.options.storeBlockNumber) {
            _writeTokenInt(
                StorageLocation.FRAMEWORK,
                tokenId,
                "blockNumber",
                block.number
            );
        }
    }

    // ---
    // Storage write controller (for engine)
    // ---

    function writeForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        string calldata value
    ) external {
        _validateForkWrite(location, forkId);
        _writeForkString(location, forkId, key, value);
    }

    function writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key,
        uint256 value
    ) external {
        _validateForkWrite(location, forkId);
        _writeForkInt(location, forkId, key, value);
    }

    function writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        string calldata value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenString(location, tokenId, key, value);
    }

    function writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key,
        uint256 value
    ) external {
        _validateTokenWrite(location, tokenId);
        _writeTokenInt(location, tokenId, key, value);
    }

    function _validateForkWrite(StorageLocation location, uint256 forkId)
        private
        view
    {
        if (location == StorageLocation.ENGINE) {
            if (msg.sender != address(getForkEngine(forkId))) {
                revert SenderNotEngine();
            }
            return; // made it
        }

        revert WriteNotAllowed();
    }

    function _validateTokenWrite(StorageLocation location, uint256 tokenId)
        private
        view
    {
        if (location == StorageLocation.ENGINE) {
            if (msg.sender != address(getTokenEngine(tokenId))) {
                revert SenderNotEngine();
            }
            return; // made it
        }

        revert WriteNotAllowed();
    }

    // ---
    // Storage write implementation
    // ---

    function _writeForkString(
        StorageLocation location,
        uint256 forkId,
        string memory key,
        string memory value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked("fork", location, forkId, key)
        );
        _stringStorage[storageKey] = value;
        emit ForkStringUpdated(location, forkId, key, value);
    }

    function _writeForkInt(
        StorageLocation location,
        uint256 forkId,
        string memory key,
        uint256 value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked("fork", location, forkId, key)
        );
        _intStorage[storageKey] = value;
        emit ForkIntUpdated(location, forkId, key, value);
    }

    function _writeTokenString(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        string memory value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked("token", location, tokenId, key)
        );
        _stringStorage[storageKey] = value;
        emit TokenStringUpdated(location, tokenId, key, value);
    }

    function _writeTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string memory key,
        uint256 value
    ) private {
        bytes32 storageKey = keccak256(
            abi.encodePacked("token", location, tokenId, key)
        );
        _intStorage[storageKey] = value;
        emit TokenIntUpdated(location, tokenId, key, value);
    }

    // ---
    // Storage views
    // ---

    function readForkString(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(
            abi.encodePacked("fork", location, forkId, key)
        );
        return _stringStorage[storageKey];
    }

    function readForkInt(
        StorageLocation location,
        uint256 forkId,
        string calldata key
    ) external view returns (uint256) {
        bytes32 storageKey = keccak256(
            abi.encodePacked("fork", location, forkId, key)
        );
        return _intStorage[storageKey];
    }

    function readTokenString(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (string memory) {
        bytes32 storageKey = keccak256(
            abi.encodePacked("token", location, tokenId, key)
        );
        return _stringStorage[storageKey];
    }

    function readTokenInt(
        StorageLocation location,
        uint256 tokenId,
        string calldata key
    ) external view returns (uint256) {
        bytes32 storageKey = keccak256(
            abi.encodePacked("token", location, tokenId, key)
        );
        return _intStorage[storageKey];
    }

    // ---
    // Views powered by current engine
    // ---

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return getTokenEngine(tokenId).getRoyaltyInfo(this, tokenId, salePrice);
    }

    // ---
    // introspection
    // ---

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == type(IShellFramework).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}
