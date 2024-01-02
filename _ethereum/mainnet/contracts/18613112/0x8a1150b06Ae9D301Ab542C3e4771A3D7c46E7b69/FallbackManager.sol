// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title Cyan Wallet Fallback Manager - A Cyan wallet's fallback manager.
/// @author Bulgantamir Gankhuyag - <bulgaa@usecyan.com>
/// @author Naranbayar Uuganbayar - <naba@usecyan.com>
abstract contract IFallbackManager {
    // keccak256("core.fallbackHandler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT =
        0x7734d301adfb6b9d8ff43068373ec4ffef29a42d1456fb5e0ba2ebb9f4793edb;

    event ChangedFallbackHandler(address handler);

    /// @notice Sets the fallback handler.
    /// @param handler Address of the fallback handler.
    function _setFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            sstore(slot, handler)
        }
        emit ChangedFallbackHandler(handler);
    }

    /// @notice Sets the fallback handler.
    /// @param handler Address of the fallback handler.
    function setFallbackHandler(address handler) external virtual;

    /// @notice Returns the fallback handler.
    /// @return handler Address of the fallback handler.
    function getFallbackHandler() external view returns (address handler) {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        assembly {
            handler := sload(slot)
        }
    }

    /// @notice Returns an native token balance of the wallet.
    /// return native token balance of the wallet.
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows the wallet to receive native token.
    receive() external payable {}
}
