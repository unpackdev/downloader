//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ILockableV3.sol";
import "./IERC5192.sol";
import "./ERC165Upgradeable.sol";

import "./Initializable.sol";
import "./console.sol";

library LockableStorageV3 {
	bytes32 constant STRUCT_POSITION = keccak256("revolvinggames.wildlands.Lockable");

	struct Layout {
		bool tokenLockingEnabled;
		bool overrideLocked;
		mapping(uint256 => bool) tokenLockedStates;
		mapping(uint256 => ILockableV3.LockInfo) tokenLockedInfo;
	}

	function layout() internal pure returns (Layout storage l) {
		bytes32 position = STRUCT_POSITION;
		assembly {
			l.slot := position
		}
	}
}

/**
	@notice Upgradeable implementation of Lockable
 */
abstract contract LockableUpgradeableV3 is IERC5192, ILockableV3, Initializable, ERC165Upgradeable {
	// ====================================================
	// STATE
	// ====================================================
	using LockableStorageV3 for LockableStorageV3.Layout;

	// ====================================================
	// MODIFIERS
	// ====================================================
	modifier onlyWhenUnlocked(uint256 tokenId) {
		(bool isLocked, ) = this.getTokenLockedState(tokenId);

		if (isLocked) {
			revert OperationBlockedByTokenLock();
		}
		_;
	}

	// ====================================================
	// INITIALIZATION
	// ====================================================
	function __Lockable_init() internal onlyInitializing {
		__Lockable_init_unchained();
	}

	function __Lockable_init_unchained() internal onlyInitializing {}

	// ====================================================
	// INTERNAL
	// ====================================================
	function _lockToken(uint256 tokenId) private {
		if (!LockableStorageV3.layout().tokenLockingEnabled) {
			revert TokenLockingDisabled();
		}
		LockableStorageV3.layout().tokenLockedStates[tokenId] = true;
		emit Locked(tokenId);
	}

	function lockToken(uint256 tokenId) internal {
		_lockToken(tokenId);

		// Reset info state (since the duration is indefinite)
		LockableStorageV3.layout().tokenLockedInfo[tokenId] = LockInfo({ lockTime: 0, lockDuration: 0 });
	}

	function lockToken(uint256 tokenId, uint256 lockDuration) internal {
		_lockToken(tokenId);

		LockableStorageV3.layout().tokenLockedInfo[tokenId] = LockInfo({
			lockTime: block.timestamp,
			lockDuration: lockDuration
		});
	}

	function unlockToken(uint256 tokenId) internal {
		if (!LockableStorageV3.layout().tokenLockingEnabled) {
			revert TokenLockingDisabled();
		}
		LockableStorageV3.layout().tokenLockedStates[tokenId] = false;
		emit Unlocked(tokenId);

		delete LockableStorageV3.layout().tokenLockedInfo[tokenId];
	}

	// ====================================================
	// PUBLIC API - READ
	// ====================================================
	function getTokenLockingEnabled() public view returns (bool) {
		return LockableStorageV3.layout().tokenLockingEnabled;
	}

	function getTokenLockedState(uint256 tokenId) public view returns (bool lockedState, LockInfo memory lockInfo) {
		lockInfo = LockableStorageV3.layout().tokenLockedInfo[tokenId];
		lockedState = LockableStorageV3.layout().tokenLockedStates[tokenId];
	}

	/**
	 * @notice IERC5192
	 */
	function locked(uint256 tokenId) public view returns (bool isLocked) {
		(isLocked, ) = getTokenLockedState(tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
	}

	// ====================================================
	// PUBLIC API - WRITE
	// ====================================================
	function enableTokenLocking() public virtual {
		LockableStorageV3.layout().tokenLockingEnabled = true;
		emit LockingEnabledToggle(true);
	}

	function disableTokenLocking() public virtual {
		LockableStorageV3.layout().tokenLockingEnabled = false;
		emit LockingEnabledToggle(false);
	}
}
