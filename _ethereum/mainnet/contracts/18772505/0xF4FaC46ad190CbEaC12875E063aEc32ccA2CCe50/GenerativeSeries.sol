// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IAbridgedMintVector.sol";
import "./IMechanicMintManager.sol";
import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

/**
 * @notice Instance of Generative Series contract
 * @author highlight.xyz
 */
contract GenerativeSeries is Proxy {
    /**
     * @notice Set up Generative Series instance
     * @param implementation_ Generative721 implementation
     * @param initializeData Data to initialize Generative contract
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param defaultRoyalty Default royalty object for contract (optional)
     * @ param _defaultTokenManager Default token manager for contract (optional)
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinter Initial minter to register
     * @ param _generativeCodeURI Generative code URI
     * @ param newBaseURI Base URI for contract
     * @ param _limitSupply Initial limit supply
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @param mintVectorData Mint vector data
     * @ param mintManager
     * @ param paymentRecipient
     * @ param startTimestamp
     * @ param endTimestamp
     * @ param pricePerToken
     * @ param tokenLimitPerTx
     * @ param maxTotalClaimableViaVector
     * @ param maxUserClaimableViaVector
     * @ param allowlistRoot
     * @param mechanicVectorData Mechanic mint vector data
     * @ param mechanicVectorId Global mechanic vector ID
     * @ param mechanic Mechanic address
     * @ param mintManager Mint manager address
     * @ param vectorData Vector data
     * @param _observability Observability contract address
     */
    constructor(
        address implementation_,
        bytes memory initializeData,
        bytes memory mintVectorData,
        bytes memory mechanicVectorData,
        address _observability
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(
            implementation_,
            abi.encodeWithSignature("initialize(bytes,address)", initializeData, _observability)
        );

        if (mintVectorData.length > 0) {
            (
                address mintManager,
                address paymentRecipient,
                uint48 startTimestamp,
                uint48 endTimestamp,
                uint192 pricePerToken,
                uint48 tokenLimitPerTx,
                uint48 maxTotalClaimableViaVector,
                uint48 maxUserClaimableViaVector,
                bytes32 allowlistRoot
            ) = abi.decode(
                    mintVectorData,
                    (address, address, uint48, uint48, uint192, uint48, uint48, uint48, bytes32)
                );

            IAbridgedMintVector(mintManager).createAbridgedVector(
                IAbridgedMintVector.AbridgedVectorData(
                    uint160(address(this)),
                    startTimestamp,
                    endTimestamp,
                    uint160(paymentRecipient),
                    maxTotalClaimableViaVector,
                    0,
                    0,
                    tokenLimitPerTx,
                    maxUserClaimableViaVector,
                    pricePerToken,
                    0,
                    false,
                    false,
                    allowlistRoot
                )
            );
        }

        if (mechanicVectorData.length != 0) {
            (uint96 seed, address mechanic, address mintManager, bytes memory vectorData) = abi.decode(
                mechanicVectorData,
                (uint96, address, address, bytes)
            );

            IMechanicMintManager(mintManager).registerMechanicVector(
                IMechanicData.MechanicVectorMetadata(address(this), 0, mechanic, false, false, false),
                seed,
                vectorData
            );
        }
    }

    /**
     * @notice Return the contract type
     */
    function standard() external pure returns (string memory) {
        return "GenerativeSeries2";
    }

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal view override returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }
}
