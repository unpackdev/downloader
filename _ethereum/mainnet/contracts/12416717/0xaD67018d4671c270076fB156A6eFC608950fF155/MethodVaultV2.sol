// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;
pragma abicoder v2;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC721.sol";
import "./Initializable.sol";
import "./EnumerableSet.sol";
import "./Address.sol";
import "./TransferHelper.sol";

import "./EIP712.sol";
import "./ERC1271.sol";
import "./OwnableByERC721.sol";
import "./UniStakerV2.sol";

interface IUniversalVaultV2 {
    /* user events */

    event Locked(address delegate, address token, uint256 amount);
    event Unlocked(address delegate, address token, uint256 amount);
    event LockedERC721(address delegate, address token, uint256 tokenId);
    event UnlockedERC721(address delegate, address token, uint256 tokenId);
    event RageQuit(address delegate, address token, bool notified, string reason);
    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);

    /* data types */

    struct LockData {
        address delegate;
        address token;
        uint256 balance;
    }

    /* initialize function */

    function initialize() external;

    /* user functions */

    function lock(
        address token,
        uint256 amount,
        bytes calldata permission
    ) external;

    function unlock(
        address token,
        uint256 amount,
        bytes calldata permission
    ) external;

    function lockERC721(
        address token,
        uint256 tokenId,
        bytes calldata permission
    ) external;

    function unlockERC721(
        address token,
        uint256 tokenId,
        bytes calldata permission
    ) external;

    function rageQuit(address delegate, address token)
        external
        returns (bool notified, string memory error);

    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function transferERC721(
        address token,
        address to,
        uint256 tokenId
    ) external;

    function transferETH(address to, uint256 amount) external payable;

    /* pure functions */

    function calculateLockID(address delegate, address token)
        external
        pure
        returns (bytes32 lockID);

    /* getter functions */

    function getPermissionHash(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) external view returns (bytes32 permissionHash);

    function getPermissionHashERC721(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 tokenId,
        uint256 nonce
    ) external view returns (bytes32 permissionHash);

    function getNonce() external view returns (uint256 nonce);

    function owner() external view returns (address ownerAddress);

    function getLockSetCount() external view returns (uint256 count);

    function getLockAt(uint256 index) external view returns (LockData memory lockData);

    function getBalanceDelegated(address token, address delegate)
        external
        view
        returns (uint256 balance);

    function getBalanceLocked(address token) external view returns (uint256 balance);

    function getNumERC721TypesLocked() external view returns (uint256 count);

    function getERC721TypeLockedAt(uint index) external view returns (address token);

    function getERC721LockedBalance(address token) external view returns (uint256 balance);

    function getERC721LockedAt(address token, uint index) external view returns (uint256 tokenId);

    function getNumERC721TypesInVault() external view returns (uint256 count);

    function getERC721TypeInVaultAt(uint index) external view returns (address token);

    function getERC721VaultBalance(address token) external view returns (uint256 balance);

    function getERC721InVaultAt(address token, uint index) external view returns (uint256 tokenId);

    function checkERC20Balances() external view returns (bool validity);

    function checkERC721Balances() external view returns (bool validity);
}

/// @title MethodVault
/// @notice Vault for isolated storage of staking tokens
/// @dev Warning: not compatible with rebasing tokens
contract MethodVaultV2 is
    IUniversalVaultV2,
    EIP712("UniversalVault", "1.0.0"),
    ERC1271,
    OwnableByERC721,
    Initializable,
    IERC721Receiver
{
    using SafeMath for uint256;
    using Address for address;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;


    /* constant */

    // Hardcoding a gas limit for rageQuit() is required to prevent gas DOS attacks
    // the gas requirement cannot be determined at runtime by querying the delegate
    // as it could potentially be manipulated by a malicious delegate who could force
    // the calls to revert.
    // The gas limit could alternatively be set upon vault initialization or creation
    // of a lock, but the gas consumption trade-offs are not favorable.
    // Ultimately, to avoid a need for fixed gas limits, the EVM would need to provide
    // an error code that allows for reliably catching out-of-gas errors on remote calls.
    uint256 public constant RAGEQUIT_GAS = 500000;
    bytes32 public constant LOCK_TYPEHASH =
        keccak256("Lock(address delegate,address token,uint256 amount,uint256 nonce)");
    bytes32 public constant UNLOCK_TYPEHASH =
        keccak256("Unlock(address delegate,address token,uint256 amount,uint256 nonce)");
    bytes32 public constant LOCK_ERC721_TYPEHASH =
        keccak256("LockERC721(address delegate,address token,uint256 tokenId,uint256 nonce)");
    bytes32 public constant UNLOCK_ERC721_TYPEHASH =
        keccak256("UnlockERC721(address delegate,address token,uint256 tokenId,uint256 nonce)");
    string public constant VERSION = "1.0.0";

    /* storage */

    uint256 private _nonce;

    EnumerableSet.AddressSet private _vaultERC721Types;
    // nft type to id mapping
    mapping(address => EnumerableSet.UintSet) private _vaultERC721s;

    EnumerableSet.AddressSet private _lockedERC721Types;
    // nft type to id mapping
    mapping(address => EnumerableSet.UintSet) private _lockedERC721s;
    mapping(bytes32 => LockData) private _locks;
    EnumerableSet.Bytes32Set private _lockSet;

    /* initialization function */

    function initializeLock() external initializer {}

    function initialize() external override initializer {
        OwnableByERC721._setNFT(msg.sender);
    }

    /* ether receive */

    receive() external payable {}

    /* internal overrides */

    function _getOwner() internal view override(ERC1271) returns (address ownerAddress) {
        return OwnableByERC721.owner();
    }

    /* overrides */

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
       emit ERC721Received(operator, from, tokenId, data);
       return IERC721Receiver(0).onERC721Received.selector;
    }

    /* pure functions */

    function calculateLockID(address delegate, address token)
        public
        pure
        override
        returns (bytes32 lockID)
    {
        return keccak256(abi.encodePacked(delegate, token));
    }

    /* getter functions */

    function getPermissionHash(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 amount,
        uint256 nonce
    ) public view override returns (bytes32 permissionHash) {
        return
            EIP712._hashTypedDataV4(
                keccak256(abi.encode(eip712TypeHash, delegate, token, amount, nonce))
            );
    }

    function getPermissionHashERC721(
        bytes32 eip712TypeHash,
        address delegate,
        address token,
        uint256 tokenId,
        uint256 nonce
    ) public view override returns (bytes32 permissionHash) {
        return
            EIP712._hashTypedDataV4(
                keccak256(abi.encode(eip712TypeHash, delegate, token, tokenId, nonce))
            );
    }

    function getNonce() external view override returns (uint256 nonce) {
        return _nonce;
    }

    function owner()
        public
        view
        override(IUniversalVaultV2, OwnableByERC721)
        returns (address ownerAddress)
    {
        return OwnableByERC721.owner();
    }

    function getLockSetCount() external view override returns (uint256 count) {
        return _lockSet.length();
    }

    function getLockAt(uint256 index) external view override returns (LockData memory lockData) {
        return _locks[_lockSet.at(index)];
    }

    function getBalanceDelegated(address token, address delegate)
        external
        view
        override
        returns (uint256 balance)
    {
        return _locks[calculateLockID(delegate, token)].balance;
    }

    function getBalanceLocked(address token) public view override returns (uint256 balance) {
        uint256 count = _lockSet.length();
        for (uint256 index; index < count; index++) {
            LockData storage _lockData = _locks[_lockSet.at(index)];
            if (_lockData.token == token && _lockData.balance > balance)
                balance = _lockData.balance;
        }
        return balance;
    }

    function getNumERC721TypesLocked() public view override returns (uint256 count) {
        return _lockedERC721Types.length();
    }
    function getERC721TypeLockedAt(uint index) public view override returns (address token) {
        return _lockedERC721Types.at(index);
    }

    function getERC721LockedBalance(address token) public view override returns (uint256 balance) {
        return _lockedERC721s[token].length();
    }

    function getERC721LockedAt(address token, uint index) public view override returns (uint256 tokenId) {
        return _lockedERC721s[token].at(index);
    }

    function getNumERC721TypesInVault() public view override returns (uint256 count) {
        return _vaultERC721Types.length();
    }
    function getERC721TypeInVaultAt(uint index) public view override returns (address token) {
        return _vaultERC721Types.at(index);
    }

    function getERC721VaultBalance(address token) public view override returns (uint256 balance) {
        return _vaultERC721s[token].length();
    }

    function getERC721InVaultAt(address token, uint index) public view override returns (uint256 tokenId) {
        return _vaultERC721s[token].at(index);
    }

    function checkERC20Balances() external view override returns (bool validity) {
        // iterate over all token locks and validate sufficient balance
        uint256 count = _lockSet.length();
        for (uint256 index; index < count; index++) {
            // fetch storage lock reference
            LockData storage _lockData = _locks[_lockSet.at(index)];
            // if insufficient balance return false
            if (IERC20(_lockData.token).balanceOf(address(this)) < _lockData.balance) return false;
        }
        // if sufficient balance return true
        return true;
    }

    function checkERC721Balances() external view override returns (bool validity) {
        // iterate over all token locks and validate sufficient balance
        uint256 count = _lockSet.length();
        for (uint256 index; index < count; index++) {
            // fetch storage lock reference
            LockData storage _lockData = _locks[_lockSet.at(index)];
            // if insufficient balance return false
            if (IERC721(_lockData.token).balanceOf(address(this)) < _lockData.balance) return false;
        }
        // if sufficient balance return true
        return true;
    }

    /* user functions */

    /// @notice Lock ERC20 tokens in the vault
    /// access control: called by delegate with signed permission from owner
    /// state machine: anytime
    /// state scope:
    /// - insert or update _locks
    /// - increase _nonce
    /// token transfer: none
    /// @param token Address of token being locked
    /// @param amount Amount of tokens being locked
    /// @param permission Permission signature payload
    function lock(
        address token,
        uint256 amount,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHash(LOCK_TYPEHASH, msg.sender, token, amount, _nonce),
            permission
        )
    {
        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // add lock to storage
        if (_lockSet.contains(lockID)) {
            // if lock already exists, increase amount
            _locks[lockID].balance = _locks[lockID].balance.add(amount);
        } else {
            // if does not exist, create new lock
            // add lock to set
            assert(_lockSet.add(lockID));
            // add lock data to storage
            _locks[lockID] = LockData(msg.sender, token, amount);
        }

        // validate sufficient balance
        require(
            IERC20(token).balanceOf(address(this)) >= _locks[lockID].balance,
            "UniversalVaultV2: insufficient balance"
        );

        // increase nonce
        _nonce += 1;

        // emit event
        emit Locked(msg.sender, token, amount);
    }

    function lockERC721(
        address token,
        uint256 tokenId,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHashERC721(LOCK_ERC721_TYPEHASH, msg.sender, token, tokenId, _nonce),
            permission
        )
    {
        // sanity check, can't lock self
        require(
            address(tokenId) != address(this),
            "can't self lock"
        );

        // validate ownership
        require(
            IERC721(token).ownerOf(tokenId) == address(this),
            "UniversalVaultV2: vault not owner of nft"
        );

        require(
            !_lockedERC721s[token].contains(tokenId),
            "NFT already locked"
        );

        _lockedERC721Types.add(token);
        _lockedERC721s[token].add(tokenId);


        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // add lock to storage
        if (_lockSet.contains(lockID)) {
            // if lock already exists, increase amount by 1
            _locks[lockID].balance = _locks[lockID].balance.add(1);
        } else {
            // if does not exist, create new lock
            // add lock to set
            assert(_lockSet.add(lockID));
            // add lock data to storage
            _locks[lockID] = LockData(msg.sender, token, 1);
        }

        // increase nonce
        _nonce += 1;

        // emit event
        emit LockedERC721(msg.sender, token, tokenId);
    }

    /// @notice Unlock ERC20 tokens in the vault
    /// access control: called by delegate with signed permission from owner
    /// state machine: after valid lock from delegate
    /// state scope:
    /// - remove or update _locks
    /// - increase _nonce
    /// token transfer: none
    /// @param token Address of token being unlocked
    /// @param amount Amount of tokens being unlocked
    /// @param permission Permission signature payload
    function unlock(
        address token,
        uint256 amount,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHash(UNLOCK_TYPEHASH, msg.sender, token, amount, _nonce),
            permission
        )
    {
        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // validate existing lock
        require(_lockSet.contains(lockID), "UniversalVaultV2: missing lock");

        // update lock data
        if (_locks[lockID].balance > amount) {
            // subtract amount from lock balance
            _locks[lockID].balance = _locks[lockID].balance.sub(amount);
        } else {
            // delete lock data
            delete _locks[lockID];
            assert(_lockSet.remove(lockID));
        }

        // increase nonce
        _nonce += 1;

        // emit event
        emit Unlocked(msg.sender, token, amount);
    }

    function unlockERC721(
        address token,
        uint256 tokenId,
        bytes calldata permission
    )
        external
        override
        onlyValidSignature(
            getPermissionHashERC721(UNLOCK_ERC721_TYPEHASH, msg.sender, token, tokenId, _nonce),
            permission
        )
    {
        // validate ownership
        require(
            IERC721(token).ownerOf(tokenId) == address(this),
            "UniversalVaultV2: vault not owner of nft"
        );

        require(
            _lockedERC721s[token].contains(tokenId),
            "NFT not locked"
        );

        _lockedERC721s[token].remove(tokenId);
        if (_lockedERC721s[token].length() == 0) {
            _lockedERC721Types.remove(token);
        }

        _vaultERC721Types.add(token);
        _vaultERC721s[token].add(tokenId);

        // get lock id
        bytes32 lockID = calculateLockID(msg.sender, token);

        // validate existing lock
        require(_lockSet.contains(lockID), "UniversalVaultV2: missing lock");

        // update lock data
        if (_locks[lockID].balance > 1) {
            // subtract 1 from lock balance
            _locks[lockID].balance = _locks[lockID].balance.sub(1);
        } else {
            // delete lock data
            delete _locks[lockID];
            assert(_lockSet.remove(lockID));
        }

        // increase nonce
        _nonce += 1;

        // emit event
        emit UnlockedERC721(msg.sender, token, tokenId);
    }

    /// @notice Forcibly cancel delegate lock
    /// @dev This function will attempt to notify the delegate of the rage quit using a fixed amount of gas.
    /// access control: only owner
    /// state machine: after valid lock from delegate
    /// state scope:
    /// - remove item from _locks
    /// token transfer: none
    /// @param delegate Address of delegate
    /// @param token Address of token being unlocked
    
    function rageQuit(address delegate, address token)
        external
        override
        onlyOwner
        returns (bool notified, string memory error)
    {
        // get lock id
        bytes32 lockID = calculateLockID(delegate, token);

        // validate existing lock
        require(_lockSet.contains(lockID), "UniversalVaultV2: missing lock");

        // attempt to notify delegate
        if (delegate.isContract()) {
            // check for sufficient gas
            require(gasleft() >= RAGEQUIT_GAS, "UniversalVaultV2: insufficient gas");

            // attempt rageQuit notification
            try IRageQuit(delegate).rageQuit{gas: RAGEQUIT_GAS}() {
                notified = true;
            } catch Error(string memory res) {
                notified = false;
                error = res;
            } catch (bytes memory) {
                notified = false;
            }
        }

        // update lock storage
        assert(_lockSet.remove(lockID));
        delete _locks[lockID];

        // emit event
        emit RageQuit(delegate, token, notified, error);
    }

    /// @notice Transfer ERC20 tokens out of vault
    /// access control: only owner
    /// state machine: when balance >= max(lock) + amount
    /// state scope: none
    /// token transfer: transfer any token
    /// @param token Address of token being transferred
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer
    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner {
        // check for sufficient balance
        require(
            IERC20(token).balanceOf(address(this)) >= getBalanceLocked(token).add(amount),
            "UniversalVaultV2: insufficient balance"
        );
        // perform transfer
        TransferHelper.safeTransfer(token, to, amount);
    }

    function transferERC721(
        address token,
        address to,
        uint256 tokenId
    ) external override onlyOwner {
        // validate ownership
        require(
            IERC721(token).ownerOf(tokenId) == address(this),
            "UniversalVaultV2: vault not owner of nft"
        );
        require(
            !_lockedERC721s[token].contains(tokenId),
            "NFT is locked. Unlock first."
        );

        _vaultERC721s[token].remove(tokenId);
        if (_vaultERC721s[token].length() == 0) {
            _vaultERC721Types.remove(token);
        }

        // perform transfer
        IERC721(token).safeTransferFrom(address(this), to, tokenId);
    }

    /// @notice Transfer ERC20 tokens out of vault
    /// access control: only owner
    /// state machine: when balance >= amount
    /// state scope: none
    /// token transfer: transfer any token
    /// @param to Address of the recipient
    /// @param amount Amount of ETH to transfer
    function transferETH(address to, uint256 amount) external payable override onlyOwner {
        // perform transfer
        TransferHelper.safeTransferETH(to, amount);
    }
}
