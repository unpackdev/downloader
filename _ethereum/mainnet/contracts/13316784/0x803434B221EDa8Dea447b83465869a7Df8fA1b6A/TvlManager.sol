// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";
import "./Imports.sol";

import "./IChainlinkRegistry.sol";
import "./IAssetAllocationRegistry.sol";
import "./Erc20Allocation.sol";

/**
 * @notice Assets can be deployed in a variety of ways within the DeFi
 * ecosystem: accounts, pools, vaults, gauges, etc. This contract tracks
 * deployed capital with asset allocations that allow position balances to
 * be priced and aggregated by Chainlink into the deployed TVL.
 * @notice When other contracts perform operations that can change how the TVL
 * must be calculated, such as swaping, staking, or claiming rewards, they
 * check the `TvlManager` to ensure the appropriate asset allocations are
 * registered.
 * @dev It is imperative that the registered asset allocations are up-to-date.
 * Any assets in the system that have been deployed but are not registered
 * could lead to significant misreporting of the TVL.
 */
contract TvlManager is
    AccessControl,
    ReentrancyGuard,
    IChainlinkRegistry,
    IAssetAllocationRegistry,
    Erc20AllocationConstants
{
    using NamedAddressSet for NamedAddressSet.AssetAllocationSet;

    IAddressRegistryV2 public addressRegistry;

    NamedAddressSet.AssetAllocationSet private _assetAllocations;

    /** @notice Log when the address registry is changed */
    event AddressRegistryChanged(address);

    /** @notice Log when the ERC20 asset allocation is changed */
    event Erc20AllocationChanged(address);

    constructor(address addressRegistry_) public {
        _setAddressRegistry(addressRegistry_);
        _setupRole(DEFAULT_ADMIN_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(EMERGENCY_ROLE, addressRegistry.emergencySafeAddress());
        _setupRole(ADMIN_ROLE, addressRegistry.adminSafeAddress());
    }

    /**
     * @notice Set the new address registry
     * @param addressRegistry_ The new address registry
     */
    function emergencySetAddressRegistry(address addressRegistry_)
        external
        onlyEmergencyRole
    {
        _setAddressRegistry(addressRegistry_);
    }

    function registerAssetAllocation(IAssetAllocation assetAllocation)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        _assetAllocations.add(assetAllocation);

        _lockOracleAdapter();

        emit AssetAllocationRegistered(assetAllocation);
    }

    function removeAssetAllocation(string memory name)
        external
        override
        nonReentrant
        onlyAdminRole
    {
        require(
            keccak256(abi.encodePacked(name)) !=
                keccak256(abi.encodePacked(Erc20AllocationConstants.NAME)),
            "CANNOT_REMOVE_ALLOCATION"
        );

        _assetAllocations.remove(name);

        _lockOracleAdapter();

        emit AssetAllocationRemoved(name);
    }

    function getAssetAllocation(string calldata name)
        external
        view
        override
        returns (IAssetAllocation)
    {
        return _assetAllocations.get(name);
    }

    /**
     * @dev The list contains no duplicate identifiers
     * @dev IDs are not constant, updates to an asset allocation change the ID
     */
    function getAssetAllocationIds()
        external
        view
        override
        returns (bytes32[] memory)
    {
        IAssetAllocation[] memory allocations = _getAssetAllocations();
        return _getAssetAllocationsIds(allocations);
    }

    function isAssetAllocationRegistered(string[] calldata allocationNames)
        external
        view
        override
        returns (bool)
    {
        uint256 length = allocationNames.length;
        for (uint256 i = 0; i < length; i++) {
            IAssetAllocation allocation =
                _assetAllocations.get(allocationNames[i]);
            if (address(allocation) == address(0)) {
                return false;
            }
        }

        return true;
    }

    function balanceOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return
            assetAllocation.balanceOf(
                addressRegistry.lpAccountAddress(),
                tokenIndex
            );
    }

    function symbolOf(bytes32 allocationId)
        external
        view
        override
        returns (string memory)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return assetAllocation.symbolOf(tokenIndex);
    }

    function decimalsOf(bytes32 allocationId)
        external
        view
        override
        returns (uint256)
    {
        (IAssetAllocation assetAllocation, uint8 tokenIndex) =
            _getAssetAllocation(allocationId);
        return assetAllocation.decimalsOf(tokenIndex);
    }

    function _setAddressRegistry(address addressRegistry_) internal {
        require(addressRegistry_.isContract(), "INVALID_ADDRESS");
        addressRegistry = IAddressRegistryV2(addressRegistry_);
        emit AddressRegistryChanged(addressRegistry_);
    }

    /**
     * @notice Lock the `OracleAdapter` for the default period of time
     * @dev Locking protects against front-running while Chainlink updates
     */
    function _lockOracleAdapter() internal {
        ILockingOracle oracleAdapter =
            ILockingOracle(addressRegistry.oracleAdapterAddress());
        oracleAdapter.lock();
    }

    /**
     * @notice Get all IDs from an array of asset allocations
     * @notice Each ID is a unique asset allocation and token index pair
     * @dev Should contain no duplicate IDs
     * @return list of all IDs
     */
    function _getAssetAllocationsIds(IAssetAllocation[] memory allocations)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 idsLength = _getAssetAllocationIdCount(allocations);
        bytes32[] memory assetAllocationIds = new bytes32[](idsLength);

        uint256 k = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            uint256 tokensLength = allocations[i].numberOfTokens();

            require(tokensLength < type(uint8).max, "TOO_MANY_TOKENS");

            for (uint256 j = 0; j < tokensLength; j++) {
                assetAllocationIds[k] = _encodeAssetAllocationId(
                    address(allocations[i]),
                    uint8(j)
                );
                k++;
            }
        }

        return assetAllocationIds;
    }

    /**
     * @notice Get an asset allocation and token index pair from an ID
     * @notice The token index references a token in the asset allocation
     * @param id The ID
     * @return The asset allocation and token index pair
     */
    function _getAssetAllocation(bytes32 id)
        internal
        view
        returns (IAssetAllocation, uint8)
    {
        (address assetAllocationAddress, uint8 tokenIndex) =
            _decodeAssetAllocationId(id);

        IAssetAllocation assetAllocation =
            IAssetAllocation(assetAllocationAddress);

        require(
            _assetAllocations.contains(assetAllocation),
            "INVALID_ASSET_ALLOCATION"
        );
        require(
            assetAllocation.numberOfTokens() > tokenIndex,
            "INVALID_TOKEN_INDEX"
        );

        return (assetAllocation, tokenIndex);
    }

    /**
     * @notice Get the total number of IDs for an array of allocations
     * @notice Used by `_getAssetAllocationsIds`
     * @notice Needed to initialize an ID array with the correct length
     * @param allocations The array of asset allocations
     * @return The number of IDs
     */
    function _getAssetAllocationIdCount(IAssetAllocation[] memory allocations)
        internal
        view
        returns (uint256)
    {
        uint256 idsLength = 0;
        for (uint256 i = 0; i < allocations.length; i++) {
            idsLength += allocations[i].numberOfTokens();
        }

        return idsLength;
    }

    /**
     * @notice Get an array of registered asset allocations
     * @dev Needed to convert from the set data structure to an array
     * @return The array of asset allocations
     */
    function _getAssetAllocations()
        internal
        view
        returns (IAssetAllocation[] memory)
    {
        uint256 numAllocations = _assetAllocations.length();
        IAssetAllocation[] memory allocations =
            new IAssetAllocation[](numAllocations);

        for (uint256 i = 0; i < numAllocations; i++) {
            allocations[i] = _assetAllocations.at(i);
        }

        return allocations;
    }

    /**
     * @notice Create an ID from an asset allocation and token index pair
     * @param assetAllocation The asset allocation
     * @param tokenIndex The token index
     * @return The ID
     */
    function _encodeAssetAllocationId(address assetAllocation, uint8 tokenIndex)
        internal
        pure
        returns (bytes32)
    {
        bytes memory idPacked = abi.encodePacked(assetAllocation, tokenIndex);

        bytes32 id;

        assembly {
            id := mload(add(idPacked, 32))
        }

        return id;
    }

    /**
     * @notice Get the asset allocation and token index for a given ID
     * @param id The ID
     * @return The asset allocation address
     * @return The token index
     */
    function _decodeAssetAllocationId(bytes32 id)
        internal
        pure
        returns (address, uint8)
    {
        uint256 id_ = uint256(id);

        address assetAllocation = address(bytes20(uint160(id_ >> 96)));
        uint8 tokenIndex = uint8(id_ >> 88);

        return (assetAllocation, tokenIndex);
    }
}
