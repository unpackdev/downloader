// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MADTypeDefinitions.sol";
import "./IMADStakingManagerDelegate.sol";
import "./IERC20Upgradeable.sol";

/**
 * @title [Interface] MAD's Radical Market callback hooks
 * @author Jupiter, Neptune
 */
abstract contract IMADStakingManager is MADTypeDefinitions {
    event AssetsStakeStatusChanged(
        Metaverse metaverse,
        address sender,
        uint256[] assetIds,
        bool stake
    );
    event AssetsUnstakeRequested(Metaverse metaverse, uint256[] assetIds);
    event AssetOperatorsSet(
        Metaverse metaverse,
        uint256 assetId,
        address[] operators
    );
    event AdsAssetAdded(Metaverse metaverse, uint256 assetId);
    event AdsAssetRemoved(Metaverse metaverse, uint256 assetId);

    /**
     * @dev Sets the address for MAD token. Currently unused.
     */
    function setMADToken(IERC20Upgradeable madtoken_) external virtual;

    /**
     * @dev Sets authorized entities, namely the Radical Market and Ads contracts.
     */
    function setAuthorizedEntities(address entity) external virtual;

    function setStakingManagerDelegate(IMADStakingManagerDelegate delegate)
        external
        virtual;

    /**
     * @dev Enable or disable public staking.
     */
    function setIsStakingOpenToPublic(Metaverse metaverse, bool status)
        external
        virtual;

    /**
     * @dev Sets the contract address for a metaverse.
     */
    function setContractAddress(Metaverse metaverse, address addr)
        external
        virtual;

    /**
     * @dev Whitelisting individuals for staking.
     */
    function setAuthorizedStakerStatus(
        Metaverse metaverse,
        address staker,
        bool isAuthorized
    ) external virtual;

    function setMetaverseInfoSM(
        Metaverse metaverse,
        uint8 maxOperators,
        address contractAddress,
        uint256 unstakeCooldownDuration
    ) external virtual;

    /**
     * @dev Stakes assets owned by the sender
     */
    function stake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        virtual;

    function requestUnstake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        virtual;

    /**
     * @dev Unstakes assets owned by the sender
     */
    function unstake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        virtual;

    /**
     * @dev Sets the operator for an asset as the current lender
     */
    function setAssetOperators(
        Metaverse metaverse,
        uint256 assetId,
        address[] memory operators
    ) external virtual;

    /**
     * @dev Distributing unclaimed revenue from Ads (deprecated)
     */
    function addUnclaimedRevenue(
        Metaverse metaverse,
        uint256 assetId,
        uint256 unclaimedEtherRevenue,
        uint256 unclaimedMADRevenue
    ) external payable virtual;

    /**
     * @dev Claiming revenue from Ads
     */
    function claimUnclaimedRevenue(Metaverse metaverse, uint256 assetId)
        external
        virtual;

    /**
     * @dev Gets information regarding an asset
     */
    function getAsset(Metaverse metaverse, uint256 assetId)
        external
        view
        virtual
        returns (AssetSM memory);

    /**
     * @dev Returns if an asset is currently staked
     */
    function getIfAssetStaked(Metaverse metaverse, uint256 assetId)
        external
        view
        virtual
        returns (bool);
}
