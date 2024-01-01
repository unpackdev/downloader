// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.4;

import "./RegistryStorage.sol";
import "./RegistryHashes.sol";
import "./DelegateTokenLib.sol";

library DelegateTokenRegistryHelpers {
    /**
     * @notice Loads a delegateTokenHolder directly from a given registryHash
     * @param delegateRegistry The address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @return delegateTokenHolder Which is the delegate "to" address corresponding to the registryHash
     * @dev Will not revert or return address(0) if delegation has been 'revoked'
     */
    function loadTokenHolder(address delegateRegistry, bytes32 registryHash) internal view returns (address delegateTokenHolder) {
        unchecked {
            return RegistryStorage.unpackAddress(
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_SECOND_PACKED))
            );
        }
    }

    /**
     * @notice Loads a underlyingContract directly from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @return underlyingContract Which is the "contract_" address corresponding to the registryHash
     * @dev Two slots need to be loaded in the registry given the packed configuration, this function should only be used when you don't need "to" or "from"
     * @dev Will not revert or return address(0) if delegation has been 'revoked`
     */
    function loadContract(address delegateRegistry, bytes32 registryHash) internal view returns (address underlyingContract) {
        unchecked {
            uint256 registryLocation = uint256(RegistryHashes.location(registryHash));
            //slither-disable-next-line unused-return
            (,, underlyingContract) = RegistryStorage.unpackAddresses(
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(registryLocation + RegistryStorage.POSITIONS_FIRST_PACKED)),
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(registryLocation + RegistryStorage.POSITIONS_SECOND_PACKED))
            );
        }
    }

    /**
     * @notice Loads a delegateTokenHolder and a underlyingContract from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @return delegateTokenHolder Which is the delegate "to" address corresponding to the registryHash
     * @return underlyingContract Which is the "contract_" address corresponding to the registryHash
     * @dev Two slots need to be loaded from the registry given the packed position
     * @dev Will not revert or return address(0), address(0) if delegation has been revoked
     */
    function loadTokenHolderAndContract(address delegateRegistry, bytes32 registryHash) internal view returns (address delegateTokenHolder, address underlyingContract) {
        unchecked {
            uint256 registryLocation = uint256(RegistryHashes.location(registryHash));
            //slither-disable-next-line unused-return
            (, delegateTokenHolder, underlyingContract) = RegistryStorage.unpackAddresses(
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(registryLocation + RegistryStorage.POSITIONS_FIRST_PACKED)),
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(registryLocation + RegistryStorage.POSITIONS_SECOND_PACKED))
            );
        }
    }

    /**
     * @notice Loads the "from" address from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @dev Will not revert if delegation has been revoked or never existed
     */
    function loadFrom(address delegateRegistry, bytes32 registryHash) internal view returns (address) {
        unchecked {
            return RegistryStorage.unpackAddress(
                IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_FIRST_PACKED))
            );
        }
    }

    /**
     * @notice Loads the "amount" from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     */
    function loadAmount(address delegateRegistry, bytes32 registryHash) internal view returns (uint256) {
        unchecked {
            return uint256(IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_AMOUNT)));
        }
    }

    /**
     * @notice Loads the "rights" from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @dev Will not return empty or revert if delegation has been revoked
     */
    function loadRights(address delegateRegistry, bytes32 registryHash) internal view returns (bytes32) {
        unchecked {
            return IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_RIGHTS));
        }
    }

    /**
     * @notice Loads the "tokenId" from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @dev Will not revert or return 0 if delegation has been revoked
     */
    function loadTokenId(address delegateRegistry, bytes32 registryHash) internal view returns (uint256) {
        unchecked {
            return uint256(IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_TOKEN_ID)));
        }
    }

    /**
     * @notice Calculates a new decreased value given an "amount" from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @param decreaseAmount The value to decrement "amount" by
     * @dev Assumes the decreased amount won't underflow with "amount"
     */
    function calculateDecreasedAmount(address delegateRegistry, bytes32 registryHash, uint256 decreaseAmount) internal view returns (uint256) {
        unchecked {
            return
                uint256(IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_AMOUNT))) - decreaseAmount;
        }
    }

    /**
     * @notice Calculates a new increased value given an "amount" from a given registryHash
     * @param delegateRegistry Address of the DelegateRegistry v2 contract
     * @param registryHash The hash of the delegation to retrieve data for
     * @param increaseAmount The value to increment "amount" by
     * @dev Assumes the increased amount won't overflow with "amount"
     */
    function calculateIncreasedAmount(address delegateRegistry, bytes32 registryHash, uint256 increaseAmount) internal view returns (uint256) {
        unchecked {
            return
                uint256(IDelegateRegistry(delegateRegistry).readSlot(bytes32(uint256(RegistryHashes.location(registryHash)) + RegistryStorage.POSITIONS_AMOUNT))) + increaseAmount;
        }
    }

    function revertERC721FlashUnavailable(address delegateRegistry, Structs.FlashInfo calldata info) internal view {
        // We touch registry directly to check for active delegation of the respective hash, as bubbling up to contract
        // and all delegations is not required
        // Important to notice that we cannot rely on this method for the fungibles since delegate token doesn't ever
        // delete the fungible delegations
        if (
            loadFrom(delegateRegistry, RegistryHashes.erc721Hash(address(this), "", info.delegateHolder, info.tokenId, info.tokenContract)) == address(this)
                || loadFrom(delegateRegistry, RegistryHashes.erc721Hash(address(this), "flashloan", info.delegateHolder, info.tokenId, info.tokenContract)) == address(this)
        ) return;
        revert Errors.ERC721FlashUnavailable();
    }

    function revertERC20FlashAmountUnavailable(address delegateRegistry, Structs.FlashInfo calldata info) internal view {
        uint256 availableAmount = 0;
        unchecked {
            // We sum the delegation amounts for "flashloan" and "" rights since liquid delegate doesn't allow double spends for different rights
            availableAmount = loadAmount(delegateRegistry, RegistryHashes.erc20Hash(address(this), "flashloan", info.delegateHolder, info.tokenContract))
                + loadAmount(delegateRegistry, RegistryHashes.erc20Hash(address(this), "", info.delegateHolder, info.tokenContract));
        } // Unreasonable that this block will overflow
        if (info.amount > availableAmount) revert Errors.ERC20FlashAmountUnavailable();
    }

    function revertERC1155FlashAmountUnavailable(address delegateRegistry, Structs.FlashInfo calldata info) internal view {
        uint256 availableAmount = 0;
        unchecked {
            availableAmount = loadAmount(delegateRegistry, RegistryHashes.erc1155Hash(address(this), "flashloan", info.delegateHolder, info.tokenId, info.tokenContract))
                + loadAmount(delegateRegistry, RegistryHashes.erc1155Hash(address(this), "", info.delegateHolder, info.tokenId, info.tokenContract));
        } // Unreasonable that this block will overflow
        if (info.amount > availableAmount) {
            revert Errors.ERC1155FlashAmountUnavailable();
        }
    }

    /// @dev Will not revert if from didn't have a delegation in the first place
    function transferERC721(
        address delegateRegistry,
        bytes32 registryHash,
        address from,
        bytes32 newRegistryHash,
        address to,
        bytes32 underlyingRights,
        address underlyingContract,
        uint256 underlyingTokenId
    ) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC721(from, underlyingContract, underlyingTokenId, underlyingRights, false) == registryHash
                && IDelegateRegistry(delegateRegistry).delegateERC721(to, underlyingContract, underlyingTokenId, underlyingRights, true) == newRegistryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if from didn't have a delegation in the first place
    /// @dev Will not revert an underflow value if from's existing delegation amount > underlyingAmount
    /// @dev Will not revert an overflow value if to's existing delegation + underlyingAmount > type(uint256).max
    function transferERC20(
        address delegateRegistry,
        bytes32 registryHash,
        address from,
        bytes32 newRegistryHash,
        address to,
        uint256 underlyingAmount,
        bytes32 underlyingRights,
        address underlyingContract
    ) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC20(
                from, underlyingContract, underlyingRights, calculateDecreasedAmount(delegateRegistry, registryHash, underlyingAmount)
            ) == bytes32(registryHash)
                && IDelegateRegistry(delegateRegistry).delegateERC20(
                    to, underlyingContract, underlyingRights, calculateIncreasedAmount(delegateRegistry, newRegistryHash, underlyingAmount)
                ) == newRegistryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if from didn't have a delegation in the first place
    /// @dev Will not revert an underflow value if from's existing delegation amount > underlyingAmount
    /// @dev Will not revert an overflowed value if to's existing delegation + underlyingAmount > type(uint256).max
    function transferERC1155(
        address delegateRegistry,
        bytes32 registryHash,
        address from,
        bytes32 newRegistryHash,
        address to,
        uint256 underlyingAmount,
        bytes32 underlyingRights,
        address underlyingContract,
        uint256 underlyingTokenId
    ) internal {
        uint256 amount = calculateDecreasedAmount(delegateRegistry, registryHash, underlyingAmount);
        if (IDelegateRegistry(delegateRegistry).delegateERC1155(from, underlyingContract, underlyingTokenId, underlyingRights, amount) != registryHash) {
            revert Errors.HashMismatch();
        }
        amount = calculateIncreasedAmount(delegateRegistry, newRegistryHash, underlyingAmount);
        if (IDelegateRegistry(delegateRegistry).delegateERC1155(to, underlyingContract, underlyingTokenId, underlyingRights, amount) != newRegistryHash) {
            revert Errors.HashMismatch();
        }
    }

    /// @dev Will not revert if delegateHolder had a delegation in the first place
    function delegateERC721(address delegateRegistry, bytes32 newRegistryHash, Structs.DelegateInfo calldata delegateInfo) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC721(delegateInfo.delegateHolder, delegateInfo.tokenContract, delegateInfo.tokenId, delegateInfo.rights, true)
                == newRegistryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if delegateHolder had a delegation in the first place
    /// @dev Will not revert an overflow value if delegateHolder's existing delegation + amount > type(uint256).max
    function incrementERC20(address delegateRegistry, bytes32 newRegistryHash, Structs.DelegateInfo calldata delegateInfo) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC20(
                delegateInfo.delegateHolder, delegateInfo.tokenContract, delegateInfo.rights, calculateIncreasedAmount(delegateRegistry, newRegistryHash, delegateInfo.amount)
            ) == newRegistryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if delegateHolder had a delegation in the first place
    /// @dev Will not revert an overflow value if delegateHolder's existing delegation + amount > type(uint256).max
    function incrementERC1155(address delegateRegistry, bytes32 newRegistryHash, Structs.DelegateInfo calldata delegateInfo) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC1155(
                delegateInfo.delegateHolder,
                delegateInfo.tokenContract,
                delegateInfo.tokenId,
                delegateInfo.rights,
                calculateIncreasedAmount(delegateRegistry, newRegistryHash, delegateInfo.amount)
            ) == newRegistryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if delegateHolder never had a delegation in the first place
    function revokeERC721(
        address delegateRegistry,
        bytes32 registryHash,
        address delegateTokenHolder,
        address underlyingContract,
        uint256 underlyingTokenId,
        bytes32 underlyingRights
    ) internal {
        if (IDelegateRegistry(delegateRegistry).delegateERC721(delegateTokenHolder, underlyingContract, underlyingTokenId, underlyingRights, false) == registryHash) {
            return;
        }
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if delegateHolder never had a delegation in the first place
    /// @dev Will not revert an underflow value if delegateHolder's existing delegation - underlyingAmount < 0
    function decrementERC20(
        address delegateRegistry,
        bytes32 registryHash,
        address delegateTokenHolder,
        address underlyingContract,
        uint256 underlyingAmount,
        bytes32 underlyingRights
    ) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC20(
                delegateTokenHolder, underlyingContract, underlyingRights, calculateDecreasedAmount(delegateRegistry, registryHash, underlyingAmount)
            ) == registryHash
        ) return;
        revert Errors.HashMismatch();
    }

    /// @dev Will not revert if delegateHolder never had a delegation in the first place
    /// @dev Will not revert an underflow value if delegateHolder's existing delegation - underlyingAmount < 0
    function decrementERC1155(
        address delegateRegistry,
        bytes32 registryHash,
        address delegateTokenHolder,
        address underlyingContract,
        uint256 underlyingTokenId,
        uint256 underlyingAmount,
        bytes32 underlyingRights
    ) internal {
        if (
            IDelegateRegistry(delegateRegistry).delegateERC1155(
                delegateTokenHolder, underlyingContract, underlyingTokenId, underlyingRights, calculateDecreasedAmount(delegateRegistry, registryHash, underlyingAmount)
            ) == registryHash
        ) return;
        revert Errors.HashMismatch();
    }
}
