// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IAuctionManager.sol";
import "./IRoyaltyManager.sol";
import "./IAbridgedMintVector.sol";
import "./Proxy.sol";
import "./Address.sol";
import "./StorageSlot.sol";

/**
 * @notice Instance of MultipleEditionsDFS contract (multiple fixed size editions)
 * @dev Uses Decentralized File Storage
 * @author highlight.xyz
 */
contract MultipleEditionsDFS is Proxy {
    /**
     * @notice Initialize MultipleEditions instance with first edition, and potentially auction
     * @param implementation_ ERC721Editions implementation
     * @param initializeData Data to initialize instance
     * @ param creator Creator/owner of contract
     * @ param _contractURI Contract metadata
     * @ param _name Name of token edition
     * @ param _symbol Symbol of the token edition
     * @ param trustedForwarder Trusted minimal forwarder
     * @ param initialMinters Initial minters to register
     * @ param useMarketplaceFiltererRegistry Denotes whether to use marketplace filterer registry
     * @ param _observability Observability contract address
     * @param _editionUri Edition uri (metadata)
     * @param editionSize Edition size
     * @param _editionTokenManager Edition's token manager
     * @param editionRoyalty Edition's royalty
     * @param auctionData Data to create auction
     * @ param auctionManagerAddress AuctionManager address. Auction not created if this is the null address
     * @ param auctionId Auction ID
     * @ param auctionCurrency Auction currency
     * @ param auctionPaymentRecipient Auction payment recipient
     * @ param auctionEndTime Auction end time
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
     */
    constructor(
        address implementation_,
        bytes memory initializeData,
        string memory _editionUri,
        uint256 editionSize,
        address _editionTokenManager,
        IRoyaltyManager.Royalty memory editionRoyalty,
        bytes memory auctionData,
        bytes memory mintVectorData,
        bytes memory mechanicVectorData
    ) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
        Address.functionDelegateCall(implementation_, abi.encodeWithSignature("initialize(bytes)", initializeData));

        // create edition
        if (bytes(_editionUri).length > 0) {
            if (mechanicVectorData.length > 0) {
                Address.functionDelegateCall(
                    implementation_,
                    abi.encodeWithSignature(
                        "createEditionWithMechanicVector(string,uint256,address,(address,uint16),bytes)",
                        _editionUri,
                        editionSize,
                        _editionTokenManager,
                        editionRoyalty,
                        mechanicVectorData
                    )
                );
            } else {
                Address.functionDelegateCall(
                    implementation_,
                    abi.encodeWithSignature(
                        "createEdition(string,uint256,address,(address,uint16),bytes)",
                        _editionUri,
                        editionSize,
                        _editionTokenManager,
                        editionRoyalty,
                        mintVectorData
                    )
                );
            }
        }

        if (auctionData.length > 0) {
            // if creating auction for this edition, validate that edition size was 1
            require(editionSize == 1, "Invalid edition size for auction");

            (
                address auctionManagerAddress,
                bytes32 auctionId,
                address auctionCurrency,
                address payable auctionPaymentRecipient,
                uint256 auctionEndTime
            ) = abi.decode(auctionData, (address, bytes32, address, address, uint256));

            // edition id guaranteed to be = 0
            IAuctionManager(auctionManagerAddress).createAuctionForNewEdition(
                auctionId,
                IAuctionManager.EnglishAuction(
                    address(this),
                    auctionCurrency,
                    msg.sender,
                    auctionPaymentRecipient,
                    auctionEndTime,
                    0,
                    true,
                    IAuctionManager.AuctionState.LIVE_ON_CHAIN
                ),
                0
            );
        }
    }

    /**
     * @notice Return the contract type
     */
    function standard() external pure returns (string memory) {
        return "MultipleEditionsDFS2";
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
