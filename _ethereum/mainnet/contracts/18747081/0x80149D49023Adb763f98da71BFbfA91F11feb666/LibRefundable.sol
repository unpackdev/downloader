// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

/// @title LibRefundable - Library for handling cancellable mint operations.
library LibRefundable {

    /// @dev Struct to hold data for mints.
    struct MintData {
        mapping(bytes32 => uint256) _mintAmounts;
        uint256[] _cancelledMints;
    }

    /// @dev Custom error for mints that are not cancelled.
    error ErrorMintNonRefundable();

    /// @dev Cancels a mint.
    /// @param self The storage reference to a MintData.
    /// @param mintId The ID of the mint.
    function cancelMint(MintData storage self, uint256 mintId, uint256 total) internal {
        self._mintAmounts[_mintKey(mintId, address(0))] = total;
        self._cancelledMints.push(mintId);
    }

    /// @dev Returns all cancelled mints.
    /// @param self The storage reference to a MintData.
    function cancelledMints(MintData storage self) internal view returns (uint256[] memory) {
        return self._cancelledMints;
    }

    /// @dev Returns the total number of cancelled mints.
    /// @param self The storage reference to a MintData.
    function totalCancelledMints(MintData storage self) internal view returns (uint256) {
        return self._cancelledMints.length;
    }

    /// @dev Returns a cancelled mint at a specific index.
    /// @param self The storage reference to a MintData.
    /// @param index The index of the cancelled mint.
    function cancelledMintAtIndex(MintData storage self, uint256 index) internal view returns (uint256) {
        return index < self._cancelledMints.length ? self._cancelledMints[index] : 0;
    }

    /// @dev Records the amount of a mint.
    /// @param self The storage reference to a MintData.
    /// @param mintId The ID of the mint.
    /// @param owner The address of the owner.
    /// @param amount The amount to record.
    function addRefundableAmount(MintData storage self, uint256 mintId, address owner, uint256 amount) internal {
        self._mintAmounts[_mintKey(mintId, owner)] += amount;
    }

    /// @dev Retrieves the refundable amount of a mint.
    /// @param self The storage reference to a MintData.
    /// @param mintId The ID of the mint.
    /// @param owner The address of the owner.
    /// @return The refundable amount for the mint.
    function getRefundableAmount(MintData storage self, uint256 mintId, address owner) internal view returns (uint256) {
        return self._mintAmounts[_mintKey(mintId, owner)];
    }

    /// @dev Refunds the amount of a mint.
    /// @param self The storage reference to a MintData.
    /// @param mintId The ID of the mint.
    /// @param owner The address of the owner.
    function removeRefundableAmount(MintData storage self, uint256 mintId, address owner) internal returns (uint256) {
        bytes32 cancelKey = _mintKey(mintId, address(0));
        bytes32 key = _mintKey(mintId, owner);
        if (self._mintAmounts[cancelKey] == 0) {
            revert ErrorMintNonRefundable();
        }
        uint256 refund = self._mintAmounts[key];
        delete self._mintAmounts[key];
        self._mintAmounts[cancelKey] -= refund;
        if (self._mintAmounts[cancelKey] == 0) {
            delete self._mintAmounts[cancelKey];
        }
        return refund;
    }

    /// @dev Generates a key for mint.
    /// @param mintId The ID of the mint.
    /// @param owner The address of the owner.
    function _mintKey(uint256 mintId, address owner) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(mintId, owner));
    }
}
