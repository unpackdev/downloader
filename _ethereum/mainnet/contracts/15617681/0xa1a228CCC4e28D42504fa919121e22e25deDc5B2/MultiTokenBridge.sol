// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AccessControlUpgradeable.sol";

import "./PauseControlUpgradeable.sol";
import "./RescueControlUpgradeable.sol";
import "./StoragePlaceholder.sol";
import "./MultiTokenBridgeStorage.sol";
import "./IMultiTokenBridge.sol";
import "./IERC20Bridgeable.sol";

/**
 * @title MultiTokenBridgeUpgradeable contract
 * @dev The bridge contract that supports bridging of multiple tokens.
 * See terms in the comments of the {IMultiTokenBridge} interface.
 */
contract MultiTokenBridge is
    AccessControlUpgradeable,
    PauseControlUpgradeable,
    RescueControlUpgradeable,
    StoragePlaceholder200,
    MultiTokenBridgeStorage,
    IMultiTokenBridge
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev The role of this contract owner.
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    /// @dev The role of bridger that is allowed to execute bridging operations.
    bytes32 public constant BRIDGER_ROLE = keccak256("BRIDGER_ROLE");

    // -------------------- Events -----------------------------------

    /// @dev Emitted when the mode of relocation is changed.
    event SetRelocationMode(
        uint256 indexed chainId, // The destination chain ID of the relocation.
        address indexed token,   // The address of the token used for relocation.
        OperationMode oldMode,   // The old mode of relocation.
        OperationMode newMode    // The new mode of relocation.
    );

    /// @dev Emitted when the mode of accommodation is changed.
    event SetAccommodationMode(
        uint256 indexed chainId, // The source chain ID of the accommodation.
        address indexed token,   // The address of the token used for accommodation.
        OperationMode oldMode,   // The old mode of accommodation.
        OperationMode newMode    // The new mode of accommodation.
    );

    // -------------------- Errors -----------------------------------

    /// @dev The zero token address has been passed when requesting a relocation.
    error ZeroRelocationToken();

    /// @dev The zero amount of tokens has been passed when requesting a relocation.
    error ZeroRelocationAmount();

    /// @dev The zero count of relocations has been passed when processing pending relocations.
    error ZeroRelocationCount();

    /// @dev The count of relocations to process is greater than the number of pending relocations.
    error LackOfPendingRelocations();

    /// @dev The relocation to the destination chain for the provided token is not supported.
    error UnsupportedRelocation();

    /// @dev The relocation with the provided nonce does not exist.
    error NotExistentRelocation();

    /// @dev The relocation with the provided nonce is already processed.
    error AlreadyProcessedRelocation();

    /// @dev The relocation with the provided nonce is already canceled.
    error AlreadyCanceledRelocation();

    /// @dev An empty array of nonces has been passed when cancelling relocations.
    error EmptyCancellationNoncesArray();

    /// @dev The transaction sender is not authorized to cancel the relocation request.
    error UnauthorizedCancellation();

    /// @dev The zero nonce has been passed when processing accommodation operations.
    error ZeroAccommodationNonce();

    /// @dev A nonce mismatch has been found when processing accommodation operations.
    error AccommodationNonceMismatch();

    /// @dev An empty array of relocations has been passed when processing accommodation operations.
    error EmptyAccommodationRelocationsArray();

    /// @dev An accommodation from the source chain for the provided token contract is not supported.
    error UnsupportedAccommodation();

    /// @dev The zero account has been found when processing an accommodation operations.
    error ZeroAccommodationAccount();

    /// @dev The zero amount has been found when processing an accommodation operations.
    error ZeroAccommodationAmount();

    /// @dev The minting of tokens failed when processing an accommodation operation.
    error TokenMintingFailure();

    /// @dev The burning of tokens failed when processing a relocation operation.
    error TokenBurningFailure();

    /// @dev The token contract does not support the {IERC20Bridgeable} interface.
    error NonBridgeableToken();

    /// @dev The mode of relocation has not been changed.
    error UnchangedRelocationMode();

    /// @dev The mode of accommodation has not been changed.
    error UnchangedAccommodationMode();

    // -------------------- Functions -----------------------------------

    /**
     * @dev The initialize function of the upgradable contract.
     * See details https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
     */
    function initialize() public initializer {
        __MultiTokenBridge_init();
    }

    function __MultiTokenBridge_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __Pausable_init_unchained();
        __PauseControl_init_unchained(OWNER_ROLE);
        __RescueControl_init_unchained(OWNER_ROLE);

        __MultiTokenBridge_init_unchained();
    }

    function __MultiTokenBridge_init_unchained() internal onlyInitializing {
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(BRIDGER_ROLE, OWNER_ROLE);

        _setupRole(OWNER_ROLE, _msgSender());
    }

    /**
     * @dev See {IMultiTokenBridge-requestRelocation}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The token address used for relocation must not be zero.
     * - The amount of tokens to relocate must be greater than zero.
     * - The relocation to the destination chain for the provided token must be supported.
     */
    function requestRelocation(
        uint256 chainId,
        address token,
        uint256 amount
    ) external whenNotPaused returns (uint256 nonce) {
        if (token == address(0)) {
            revert ZeroRelocationToken();
        }
        if (amount == 0) {
            revert ZeroRelocationAmount();
        }

        OperationMode mode = _relocationModes[chainId][token];

        if (mode == OperationMode.Unsupported) {
            revert UnsupportedRelocation();
        }

        address sender =  _msgSender();

        uint256 newPendingRelocationCount = _pendingRelocationCounters[chainId] + 1;
        nonce = _lastProcessedRelocationNonces[chainId] + newPendingRelocationCount;
        _pendingRelocationCounters[chainId] = newPendingRelocationCount;
        Relocation storage relocation = _relocations[chainId][nonce];
        relocation.account = sender;
        relocation.token = token;
        relocation.amount = amount;

        emit RequestRelocation(
            chainId,
            token,
            sender,
            amount,
            nonce
        );

        IERC20Upgradeable(token).safeTransferFrom(
            sender,
            address(this),
            amount
        );
    }

    /**
     * @dev See {IMultiTokenBridge-cancelRelocation}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must be the initiator of the relocation that is being canceled.
     * - The relocation for the provided chain ID and nonce must not be processed.
     * - The relocation for the provided chain ID and nonce must not be canceled.
     */
    function cancelRelocation(uint256 chainId, uint256 nonce) external whenNotPaused {
        if (_relocations[chainId][nonce].account != _msgSender()) {
            revert UnauthorizedCancellation();
        }

        cancelRelocationInternal(chainId, nonce);
    }

    /**
     * @dev See {IMultiTokenBridge-cancelRelocations}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {BRIDGER_ROLE} role.
     * - The provided array of relocation nonces must not be empty.
     * - All the relocations for the provided chain ID and nonces must not be processed.
     * - All the relocations for the provided chain ID and nonces must not be canceled.
     */
    function cancelRelocations(uint256 chainId, uint256[] memory nonces) external whenNotPaused onlyRole(BRIDGER_ROLE) {
        if (nonces.length == 0) {
            revert EmptyCancellationNoncesArray();
        }

        uint len = nonces.length;
        for (uint256 i = 0; i < len; i++) {
            cancelRelocationInternal(chainId, nonces[i]);
        }
    }

    /**
     * @dev See {IMultiTokenBridge-relocate}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {BRIDGER_ROLE} role.
     * - The provided count of relocations to process must not be zero
     *   and must be less than or equal to the number of pending relocations.
     */
    function relocate(uint256 chainId, uint256 count) external whenNotPaused onlyRole(BRIDGER_ROLE) {
        if (count == 0) {
            revert ZeroRelocationCount();
        }

        uint256 currentPendingRelocationCount = _pendingRelocationCounters[chainId];
        if (count > currentPendingRelocationCount) {
            revert LackOfPendingRelocations();
        }

        uint256 fromNonce = _lastProcessedRelocationNonces[chainId] + 1;
        uint256 toNonce = fromNonce + count - 1;

        _pendingRelocationCounters[chainId] = currentPendingRelocationCount - count;
        _lastProcessedRelocationNonces[chainId] = toNonce;

        for (uint256 nonce = fromNonce; nonce <= toNonce; nonce++) {
            Relocation memory relocation = _relocations[chainId][nonce];
            if (!relocation.canceled) {
                OperationMode mode = _relocationModes[chainId][relocation.token];
                relocateInternal(relocation, mode);
                emit Relocate(
                    chainId,
                    relocation.token,
                    relocation.account,
                    relocation.amount,
                    nonce,
                    mode
                );
            }
        }
    }

    /**
     * @dev See {IMultiTokenBridge-accommodate}.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     * - The caller must have the {BRIDGER_ROLE} role.
     * - The nonce of the first relocation must not be zero
     *   and must be greater than the nonce of the last accommodation.
     * - The array of relocations must not be empty and accommodation for
     *   each relocation in the array must be supported.
     * - All the provided relocations must have non-zero account address.
     * - All the provided relocations must have non-zero token amount.
     */
    function accommodate(
        uint256 chainId,
        uint256 nonce,
        Relocation[] memory relocations
    ) external whenNotPaused onlyRole(BRIDGER_ROLE) {
        if (nonce == 0) {
            revert ZeroAccommodationNonce();
        }
        if (_lastAccommodationNonces[chainId] != (nonce - 1)) {
            revert AccommodationNonceMismatch();
        }
        if (relocations.length == 0) {
            revert EmptyAccommodationRelocationsArray();
        }

        uint len = relocations.length;
        for (uint256 i = 0; i < len; i++) {
            Relocation memory relocation = relocations[i];
            if (_accommodationModes[chainId][relocation.token] == OperationMode.Unsupported) {
                revert UnsupportedAccommodation();
            }
            if (relocation.account == address(0)) {
                revert ZeroAccommodationAccount();
            }
            if (relocation.amount == 0) {
                revert ZeroAccommodationAmount();
            }

            if (!relocation.canceled) {
                OperationMode mode = _accommodationModes[chainId][relocation.token];
                accommodateInternal(relocation, mode);
                emit Accommodate(
                    chainId,
                    relocation.token,
                    relocation.account,
                    relocation.amount,
                    nonce,
                    mode
                );
            }

            nonce += 1;
        }

        _lastAccommodationNonces[chainId] = nonce - 1;
    }

    /**
     * @dev Sets the mode of relocation for a given destination chain and provided token.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The new mode of relocation must be different from the current one.
     * - In the case of `BurnOrMint` relocation mode the token contract must
     *   support {IERC20Bridgeable} interface.
     *
     * Emits a {SetRelocationMode} event.
     *
     * @param chainId The ID of the destination chain to relocate tokens to.
     * @param token The address of the token used for relocation.
     * @param newMode The new mode of relocation.
     */
    function setRelocationMode(
        uint256 chainId,
        address token,
        OperationMode newMode
    ) external onlyRole(OWNER_ROLE) {
        OperationMode oldMode = _relocationModes[chainId][token];
        if (oldMode == newMode) {
            revert UnchangedRelocationMode();
        }
        if (newMode == OperationMode.BurnOrMint) {
            if (!isTokenIERC20BridgeableInternal(token)) {
                revert NonBridgeableToken();
            }
        }

        _relocationModes[chainId][token] = newMode;

        emit SetRelocationMode(chainId, token, oldMode, newMode);
    }

    /**
     * @dev Sets the mode of accommodation for a given source chain and provided token.
     *
     * Requirements:
     *
     * - The caller must have the {OWNER_ROLE} role.
     * - The new mode of accommodation must be different from the current one.
     * - In the case of `BurnOrMint` accommodation mode the token contract must
     *   support {IERC20Bridgeable} interface.
     *
     * Emits a {SetAccommodationMode} event.
     *
     * @param chainId The ID of the source chain to accommodate tokens from.
     * @param token The address of the token used for accommodation.
     * @param newMode The new mode of accommodation.
     */
    function setAccommodationMode(
        uint256 chainId,
        address token,
        OperationMode newMode
    ) external onlyRole(OWNER_ROLE) {
        OperationMode oldMode = _accommodationModes[chainId][token];
        if (oldMode == newMode) {
            revert UnchangedAccommodationMode();
        }
        if (newMode == OperationMode.BurnOrMint) {
            if (!isTokenIERC20BridgeableInternal(token)) {
                revert NonBridgeableToken();
            }
        }

        _accommodationModes[chainId][token] = newMode;

        emit SetAccommodationMode(chainId, token, oldMode, newMode);
    }

    /**
     * @dev See {IMultiTokenBridge-getPendingRelocationCounter}.
     */
    function getPendingRelocationCounter(uint256 chainId) external view returns (uint256) {
        return _pendingRelocationCounters[chainId];
    }

    /**
     * @dev See {IMultiTokenBridge-getLastProcessedRelocationNonce}.
     */
    function getLastProcessedRelocationNonce(uint256 chainId) external view returns (uint256) {
        return _lastProcessedRelocationNonces[chainId];
    }

    /**
     * @dev See {IMultiTokenBridge-getRelocationMode}.
     */
    function getRelocationMode(uint256 chainId, address token) external view returns (OperationMode) {
        return _relocationModes[chainId][token];
    }

    /**
     * @dev See {IMultiTokenBridge-getRelocation}.
     */
    function getRelocation(uint256 chainId, uint256 nonce) external view returns (Relocation memory) {
        return _relocations[chainId][nonce];
    }

    /**
     * @dev See {IMultiTokenBridge-getAccommodationMode}.
     */
    function getAccommodationMode(uint256 chainId, address token) external view returns (OperationMode) {
        return _accommodationModes[chainId][token];
    }

    /**
     * @dev See {IMultiTokenBridge-getLastAccommodationNonce}.
     */
    function getLastAccommodationNonce(uint256 chainId) external view returns (uint256) {
        return _lastAccommodationNonces[chainId];
    }

    /**
     * @dev See {IMultiTokenBridge-getRelocations}.
     */
    function getRelocations(
        uint256 chainId,
        uint256 nonce,
        uint256 count
    ) external view returns (Relocation[] memory relocations) {
        relocations = new Relocation[](count);
        for (uint256 i = 0; i < count; i++) {
            relocations[i] = _relocations[chainId][nonce];
            nonce += 1;
        }
    }

    function cancelRelocationInternal(uint256 chainId, uint256 nonce) internal {
        uint256 lastProcessedRelocationNonce = _lastProcessedRelocationNonces[chainId];
        if (nonce <= lastProcessedRelocationNonce) {
            revert AlreadyProcessedRelocation();
        }
        if (nonce > lastProcessedRelocationNonce + _pendingRelocationCounters[chainId]) {
            revert NotExistentRelocation();
        }

        Relocation storage relocation = _relocations[chainId][nonce];

        if (relocation.canceled) {
            revert AlreadyCanceledRelocation();
        }

        relocation.canceled = true;

        emit CancelRelocation(
            chainId,
            relocation.token,
            relocation.account,
            relocation.amount,
            nonce
        );

        IERC20Upgradeable(relocation.token).safeTransfer(relocation.account, relocation.amount);
    }

    function relocateInternal(Relocation memory relocation, OperationMode mode) internal {
        if (mode == OperationMode.BurnOrMint) {
            bool burningSuccess = IERC20Bridgeable(relocation.token).burnForBridging(
                relocation.account,
                relocation.amount
            );
            if (!burningSuccess) {
                revert TokenBurningFailure();
            }
        }
    }

    function accommodateInternal(Relocation memory relocation, OperationMode mode) internal {
        if (mode == OperationMode.BurnOrMint) {
            bool mintingSuccess = IERC20Bridgeable(relocation.token).mintForBridging(
                relocation.account,
                relocation.amount
            );
            if (!mintingSuccess) {
                revert TokenMintingFailure();
            }
        } else {
            IERC20Upgradeable(relocation.token).safeTransfer(relocation.account, relocation.amount);
        }
    }

    // Safely call the appropriate function from the IERC20Bridgeable interface.
    function isTokenIERC20BridgeableInternal(address token) internal virtual returns (bool) {
        (bool success, bytes memory result) = token.staticcall(
            abi.encodeWithSelector(IERC20Bridgeable.isIERC20Bridgeable.selector)
        );
        if (success && result.length > 0) {
            return abi.decode(result, (bool));
        } else {
            return false;
        }
    }
}
