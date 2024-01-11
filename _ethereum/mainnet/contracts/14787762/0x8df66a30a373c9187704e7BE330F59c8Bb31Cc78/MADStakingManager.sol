// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./MADBootstrapper.sol";
import "./IMADStakingManager.sol";
import "./IMADRadicalMarketDelegate.sol";
import "./ILandRegistry.sol";
import "./IEstateRegistry.sol";
import "./SafeERC20Upgradeable.sol";

contract MADStakingManager is
    MADBootstrapper,
    IMADStakingManager,
    IMADRadicalMarketDelegate
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public madToken;
    mapping(Metaverse => MetaverseInfoSM) internal _metaverseInfo;
    mapping(address => bool) internal _authorizedEntities;

    address public defaultOperator;
    IMADStakingManagerDelegate public smDelegate;

    modifier authorized() {
        require(_authorizedEntities[_msgSender()], "Unauthorized");
        _;
    }

    function setDefaultOperator(address operator) external onlyOwner {
        defaultOperator = operator;
    }

    function setMADToken(IERC20Upgradeable madtoken_)
        external
        override
        onlyOwner
    {
        madToken = madtoken_;
    }

    function setAuthorizedEntities(address entity) external override onlyOwner {
        _authorizedEntities[entity] = true;
    }

    function setStakingManagerDelegate(IMADStakingManagerDelegate delegate)
        external
        override
        onlyOwner
    {
        smDelegate = delegate;
    }

    function setIsStakingOpenToPublic(Metaverse metaverse, bool status)
        external
        override
        onlyOwner
    {
        _metaverseInfo[metaverse].isStakingOpenToPublic = status;
    }

    function setContractAddress(Metaverse metaverse, address addr)
        external
        override
        onlyOwner
    {
        _metaverseInfo[metaverse].contractAddress = addr;
    }

    function setAuthorizedStakerStatus(
        Metaverse metaverse,
        address staker,
        bool isAuthorized
    ) external override onlyOwner {
        _metaverseInfo[metaverse].authorizedStakers[staker] = isAuthorized;
    }

    function setMetaverseInfoSM(
        Metaverse metaverse,
        uint8 maxOperators,
        address contractAddress,
        uint256 unstakeCooldownDuration
    ) external override onlyOwner {
        MetaverseInfoSM storage info = _metaverseInfo[metaverse];
        info.maxOperators = maxOperators;
        info.contractAddress = contractAddress;
        info.unstakeCooldownDuration = unstakeCooldownDuration;
    }

    function stake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        override
        whenNotPaused
    {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        require(
            mmInfo.authorizedStakers[_msgSender()] ||
                mmInfo.isStakingOpenToPublic,
            "Unauthorized"
        );
        if (metaverse == Metaverse.DCL_LAND) {
            address[] memory defaultOperators = new address[](1);
            defaultOperators[0] = defaultOperator;
            for (uint256 i = 0; i < assetIds.length; i++) {
                ILandRegistry land = ILandRegistry(mmInfo.contractAddress);
                require(
                    mmInfo.stakedAssets[assetIds[i]].owner == address(0),
                    "Already staked"
                );
                mmInfo.stakedAssets[assetIds[i]].owner = _msgSender();
                land.transferFrom(_msgSender(), address(this), assetIds[i]);
                _setAssetOperatorsInternal(
                    metaverse,
                    assetIds[i],
                    defaultOperators
                );
                mmInfo.isAdsAsset[assetIds[i]] = true;
                emit AdsAssetAdded(metaverse, assetIds[i]);
            }
        } else if (metaverse == Metaverse.DCL_ESTATE) {
            address[] memory defaultOperators = new address[](1);
            defaultOperators[0] = defaultOperator;
            for (uint256 i = 0; i < assetIds.length; i++) {
                IEstateRegistry estate = IEstateRegistry(
                    mmInfo.contractAddress
                );
                require(
                    mmInfo.stakedAssets[assetIds[i]].owner == address(0),
                    "Already staked"
                );
                mmInfo.stakedAssets[assetIds[i]].owner = _msgSender();
                estate.transferFrom(_msgSender(), address(this), assetIds[i]);
                _setAssetOperatorsInternal(
                    metaverse,
                    assetIds[i],
                    defaultOperators
                );
                mmInfo.isAdsAsset[assetIds[i]] = true;
                emit AdsAssetAdded(metaverse, assetIds[i]);
            }
        } else {
            revert("Unsupported");
        }
        emit AssetsStakeStatusChanged(metaverse, _msgSender(), assetIds, true);
    }

    function requestUnstake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        override
        whenNotPaused
    {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        for (uint256 i = 0; i < assetIds.length; ++i) {
            AssetSM storage assetInfo = mmInfo.stakedAssets[assetIds[i]];
            require(
                assetInfo.unstakeCooldownDeadline == 0,
                "Already requested"
            );
            assetInfo.unstakeCooldownDeadline =
                block.timestamp +
                mmInfo.unstakeCooldownDuration;
        }
        emit AssetsUnstakeRequested(metaverse, assetIds);
    }

    function unstake(Metaverse metaverse, uint256[] calldata assetIds)
        external
        override
        whenNotPaused
    {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        for (uint256 i = 0; i < assetIds.length; i++) {
            if (mmInfo.isAdsAsset[assetIds[i]]) continue;
            _notifyUnstake(metaverse, assetIds[i]);
            AssetSM storage assetInfo = mmInfo.stakedAssets[assetIds[i]];
            require(
                assetInfo.unstakeCooldownDeadline > 0,
                "Must request cooldown"
            );
            require(
                assetInfo.unstakeCooldownDeadline < block.timestamp,
                "Still in cooldown"
            );
            assetInfo.unstakeCooldownDeadline = 0;
        }
        if (metaverse == Metaverse.DCL_LAND) {
            address[] memory operators = new address[](1);
            operators[0] = _msgSender();
            for (uint256 i = 0; i < assetIds.length; i++) {
                ILandRegistry land = ILandRegistry(mmInfo.contractAddress);
                require(
                    mmInfo.stakedAssets[assetIds[i]].owner == _msgSender(),
                    "Not owner"
                );
                _setAssetOperatorsInternal(metaverse, assetIds[i], operators);
                land.transferFrom(address(this), _msgSender(), assetIds[i]);
                if (mmInfo.isAdsAsset[assetIds[i]]) {
                    mmInfo.isAdsAsset[assetIds[i]] = false;
                    emit AdsAssetRemoved(metaverse, assetIds[i]);
                }
                mmInfo.stakedAssets[assetIds[i]].owner = address(0);
            }
        } else if (metaverse == Metaverse.DCL_ESTATE) {
            address[] memory operators = new address[](1);
            operators[0] = _msgSender();
            for (uint256 i = 0; i < assetIds.length; i++) {
                IEstateRegistry estate = IEstateRegistry(
                    mmInfo.contractAddress
                );
                require(
                    mmInfo.stakedAssets[assetIds[i]].owner == _msgSender(),
                    "Not owner"
                );
                _setAssetOperatorsInternal(metaverse, assetIds[i], operators);
                estate.transferFrom(address(this), _msgSender(), assetIds[i]);
                if (mmInfo.isAdsAsset[assetIds[i]]) {
                    mmInfo.isAdsAsset[assetIds[i]] = false;
                    emit AdsAssetRemoved(metaverse, assetIds[i]);
                }
                mmInfo.stakedAssets[assetIds[i]].owner = address(0);
            }
        } else {
            revert("Unsupported");
        }
        emit AssetsStakeStatusChanged(metaverse, _msgSender(), assetIds, false);
    }

    function addUnclaimedRevenue(
        Metaverse metaverse,
        uint256 assetId,
        uint256 unclaimedEtherRevenue,
        uint256 unclaimedMADRevenue
    ) external payable override authorized {
        require(unclaimedEtherRevenue == msg.value, "Wrong value");
        _metaverseInfo[metaverse]
            .stakedAssets[assetId]
            .unclaimedEtherRevenue += unclaimedEtherRevenue;
        _metaverseInfo[metaverse]
            .stakedAssets[assetId]
            .unclaimedMADRevenue = unclaimedMADRevenue;
    }

    function claimUnclaimedRevenue(Metaverse metaverse, uint256 assetId)
        external
        override
        nonReentrant
    {
        AssetSM storage asset = _metaverseInfo[metaverse].stakedAssets[assetId];
        require(_msgSender() == asset.owner, "Not owner");
        uint256 etherAmount = asset.unclaimedEtherRevenue;
        // uint256 madAmount = asset.unclaimedMADRevenue;
        asset.unclaimedEtherRevenue = 0;
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, bytes memory data) = payable(_msgSender()).call{
            value: etherAmount
        }("");
        require(sent, string(data));
        // madToken.safeTransfer(_msgSender(), madAmount);
    }

    function didReleaseAsset(Metaverse metaverse, uint256 assetId)
        external
        override
        authorized
    {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        mmInfo.isAdsAsset[assetId] = true;
        address[] memory operators = new address[](1);
        operators[0] = defaultOperator;
        _setAssetOperatorsInternal(metaverse, assetId, operators);
        emit AdsAssetAdded(metaverse, assetId);
    }

    function didAcquireLenderForAsset(
        Metaverse metaverse,
        uint256 assetId,
        address lender
    ) external override authorized {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        mmInfo.isAdsAsset[assetId] = false;
        address[] memory operators = new address[](1);
        operators[0] = lender;
        _setAssetOperatorsInternal(metaverse, assetId, operators);
        emit AdsAssetRemoved(metaverse, assetId);
    }

    function setAssetOperators(
        Metaverse metaverse,
        uint256 assetId,
        address[] memory operators
    ) external override whenNotPaused authorized {
        _setAssetOperatorsInternal(metaverse, assetId, operators);
    }

    function getMetaverseInfo(Metaverse metaverse)
        external
        view
        returns (
            bool isStakingOpenToPublic,
            uint8 maxOperators,
            address contractAddress
        )
    {
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        return (
            mmInfo.isStakingOpenToPublic,
            mmInfo.maxOperators,
            mmInfo.contractAddress
        );
    }

    function getAsset(Metaverse metaverse, uint256 assetId)
        external
        view
        override
        returns (AssetSM memory)
    {
        return _metaverseInfo[metaverse].stakedAssets[assetId];
    }

    function getIfAssetStaked(Metaverse metaverse, uint256 assetId)
        external
        view
        override
        returns (bool)
    {
        return
            _metaverseInfo[metaverse].stakedAssets[assetId].owner != address(0);
    }

    function _setAssetOperatorsInternal(
        Metaverse metaverse,
        uint256 assetId,
        address[] memory operators
    ) internal {
        // Different Metaverses have different rules regarding operators
        // Attempting to generalize a bit here
        MetaverseInfoSM storage mmInfo = _metaverseInfo[metaverse];
        require(
            mmInfo.maxOperators == 0 || mmInfo.maxOperators >= operators.length,
            "Too many operators"
        );
        if (metaverse == Metaverse.DCL_LAND) {
            ILandRegistry land = ILandRegistry(mmInfo.contractAddress);
            land.setUpdateOperator(assetId, operators[0]);
        } else if (metaverse == Metaverse.DCL_ESTATE) {
            IEstateRegistry estate = IEstateRegistry(mmInfo.contractAddress);
            estate.setUpdateOperator(assetId, operators[0]);
        } else {
            revert("Unsupported metaverse");
        }
        emit AssetOperatorsSet(metaverse, assetId, operators);
    }

    function _notifyUnstake(Metaverse metaverse, uint256 assetId) internal {
        smDelegate.liquidateUnstakingAsset(metaverse, assetId);
    }
}
