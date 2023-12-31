//SPDX-License-Identifier: Apache 2.0

pragma solidity ^0.8.21;

import "./IERC20.sol";
import "./IERC721Metadata.sol";
import "./Ownable.sol";
import "./IRMRKDeployer.sol";
import "./IRMRKMintaurRegistry.sol";
import "./IRMRKRegistry.sol";

error FailedToSend();
error FeeTooLow();
error InvalidCutOffDate();
error WrongValueSent();

/**
 * @title RMRK Mint'aur
 * @notice This contract is used to create new RMRK collections
 */
contract RMRKMintaur is Ownable {
    /**
     * @notice Emitted when a collection is created.
     * @param collection The address of the new collection
     * @param deployer The address of the deployer
     */
    event CollectionDeployed(
        address indexed collection,
        address indexed deployer,
        uint256 maxSupply,
        uint256 mintPrice,
        uint256 cutOffDate,
        string collectionMetadata
    );

    uint8 CUSTOM_MINTING_TYPE_FROM_MINTAUR = 3;
    IRMRKRegistry.CollectionConfig private _defaultCollectionConfig;

    address private _platformBeneficiary;
    IRMRKDeployer private _deployer;
    IRMRKRegistry private _registry;
    IRMRKMintaurRegistry private _mintaurRegistry;

    uint256 private _assetPinningPrice;
    uint256 private _minimumMintingFee;
    uint256 private _mintingFeePercentageBPS;

    /**
     * @notice Initializes the contract.
     * @dev The basis points (bPt) are integer representation of percentage up to the second decimal space. Meaning that
     *  1 bPt equals 0.01% and 500 bPt equal 5%.
     * @param beneficiary The address of the beneficiary
     * @param deployer The address of the deployer contract
     * @param registry The address of the registry contract
     * @param assetPinningPrice The individial pinning price per asset
     * @param minimumMintingFee The minimum price per minted token
     * @param mintingFeePercentageBPS The minting fee percentage in basis points
     */
    constructor(
        address beneficiary,
        address deployer,
        address registry,
        uint256 assetPinningPrice,
        uint256 minimumMintingFee,
        uint256 mintingFeePercentageBPS
    ) {
        _platformBeneficiary = beneficiary;
        _deployer = IRMRKDeployer(deployer);
        _registry = IRMRKRegistry(registry);
        _assetPinningPrice = assetPinningPrice;
        _minimumMintingFee = minimumMintingFee;
        _mintingFeePercentageBPS = mintingFeePercentageBPS;

        _defaultCollectionConfig = IRMRKRegistry.CollectionConfig(
            true,
            false,
            true,
            true,
            false,
            true,
            false,
            false,
            false,
            0,
            CUSTOM_MINTING_TYPE_FROM_MINTAUR,
            0x0
        );
    }

    // -------------- GETTERS --------------

    /**
     * @notice Returns the address of the platform beneficiary.
     * @return beneficiary The address of the platform beneficiary
     */
    function getBeneficiary() public view returns (address) {
        return _platformBeneficiary;
    }

    /**
     * @notice Returns the address of the deployer contract.
     * @return deployer The address of the deployer contract
     */
    function getDeployer() public view returns (address) {
        return address(_deployer);
    }

    /**
     * @notice Returns the address of the registry contract.
     * @return registry The address of the registry contract
     */
    function getRegistry() public view returns (address) {
        return address(_registry);
    }

    /**
     * @notice Returns the address of the mintaur registry contract.
     * @return mintaurRegistry The address of the mintaur registry contract
     */
    function getMintaurRegistry() public view returns (address) {
        return address(_mintaurRegistry);
    }

    /**
     * @notice Returns the individual pinning price per asset.
     * @return assetPinningPrice The individual pinning price per asset
     */
    function getAssetPinningPrice() public view returns (uint256) {
        return _assetPinningPrice;
    }

    /**
     * @notice Returns the minimum fee per minted token.
     * @return minimumMintingFee The minimum fee per minted token
     */
    function getMinimumMintingFee() public view returns (uint256) {
        return _minimumMintingFee;
    }

    /**
     * @notice Returns the minting fee percentage in basis points.
     * @return mintingFeePercentageBPS The minting fee percentage in basis points
     */
    function getMintingFeePercentageBPS() public view returns (uint256) {
        return _mintingFeePercentageBPS;
    }

    // -------------- ADMIN SETTERS --------------

    /**
     * @notice Sets the address of the beneficiary.
     * @param beneficiary The address of the beneficiary
     */
    function setBeneficiary(address beneficiary) public onlyOwner {
        _platformBeneficiary = beneficiary;
    }

    /**
     * @notice Sets the address of the deployer contract.
     * @param deployer The address of the deployer contract
     */
    function setDeployer(address deployer) public onlyOwnerOrContributor {
        _deployer = IRMRKDeployer(deployer);
    }

    /**
     * @notice Sets the address of the registry contract.
     * @param registry The address of the registry contract
     */
    function setRegistry(address registry) public onlyOwnerOrContributor {
        _registry = IRMRKRegistry(registry);
    }

    /**
     * @notice Sets the address of the mintaur registry contract.
     * @param mintaurRegistry The address of the mintaur registry contract
     */
    function setMintaurRegistry(
        address mintaurRegistry
    ) public onlyOwnerOrContributor {
        _mintaurRegistry = IRMRKMintaurRegistry(mintaurRegistry);
    }

    /**
     * @notice Sets the individual pinning price per asset.
     * @param assetPinningPrice The individual pinning price per asset
     */
    function setAssetPinningPrice(
        uint256 assetPinningPrice
    ) public onlyOwnerOrContributor {
        _assetPinningPrice = assetPinningPrice;
    }

    /**
     * @notice Sets the minimum fee per minted token
     * @param minimumMintingFee The minimum fee per minted token
     */
    function setMinimumMintingFee(
        uint256 minimumMintingFee
    ) public onlyOwnerOrContributor {
        _minimumMintingFee = minimumMintingFee;
    }

    /**
     * @notice Sets the minting fee percentage in basis points.
     * @param mintingFeePercentageBPS The minting fee percentage in basis points
     */
    function setMintingFeePercentageBPS(
        uint256 mintingFeePercentageBPS
    ) public onlyOwnerOrContributor {
        _mintingFeePercentageBPS = mintingFeePercentageBPS;
    }

    // -------------- Deploying --------------

    /**
     * @notice Deploys a new collection.
     * @param name Name of the token collection
     * @param symbol Symbol of the token collection
     * @param collectionMetadata CID of the collection metadata
     * @param maxSupply The maximum supply of tokens
     * @param royaltyRecipient Recipient of resale royalties
     * @param royaltyPercentageBps The percentage to be paid from the sale of the token expressed in basis points
     * @param initialAssetsMetadata Array with metadata of the initial assets which will be added into every minte
     */
    function deployCollection(
        string memory name,
        string memory symbol,
        string memory collectionMetadata,
        uint256 maxSupply,
        uint256 mintPrice,
        address beneficiary,
        address royaltyRecipient,
        uint16 royaltyPercentageBps,
        uint256 cutOffDate,
        string[] memory initialAssetsMetadata
    ) external payable {
        if (mintPrice < _minimumMintingFee) revert FeeTooLow();
        if (cutOffDate < block.timestamp) revert InvalidCutOffDate();
        _chargeAssetPinning(initialAssetsMetadata.length);

        address newCollection = _deployer.deployCollection(
            name,
            symbol,
            collectionMetadata,
            maxSupply,
            msg.sender,
            royaltyRecipient,
            royaltyPercentageBps,
            initialAssetsMetadata
        );
        _addCollectionToRegistry(newCollection, collectionMetadata, maxSupply);
        _mintaurRegistry.storeNewCollection(
            newCollection,
            mintPrice,
            getMintFeeEstimate(mintPrice),
            beneficiary,
            cutOffDate
        );

        emit CollectionDeployed(
            newCollection,
            msg.sender,
            maxSupply,
            mintPrice,
            cutOffDate,
            collectionMetadata
        );
    }

    function mint(
        address collection,
        address to,
        uint256 numToMint
    ) external payable {
        // Extra checks (e.g. allow lists) in the future can be added here
        _mintaurRegistry.mint{value: msg.value}(
            collection,
            to,
            numToMint
        );
    }

    function getMintFeeEstimate(
        uint256 mintPrice
    ) public view returns (uint256) {
        uint256 fee = (mintPrice * _mintingFeePercentageBPS) / 10000;
        if (fee < _minimumMintingFee) fee = _minimumMintingFee;
        return fee;
    }

    function _addCollectionToRegistry(
        address collection,
        string memory collectionMetadata,
        uint256 maxSupply
    ) private {
        _registry.addCollection(
            collection,
            _msgSender(),
            maxSupply,
            IRMRKRegistry.LegoCombination.Equippable,
            IRMRKRegistry.MintingType.Custom,
            false,
            _defaultCollectionConfig,
            collectionMetadata
        );
    }

    function _chargeAssetPinning(uint256 numAssets) private {
        uint256 price = _assetPinningPrice * numAssets;
        if (msg.value != price) revert WrongValueSent();

        (bool sent, ) = _platformBeneficiary.call{
            value: msg.value
        }("");
        if (!sent) revert FailedToSend();
    }
}
