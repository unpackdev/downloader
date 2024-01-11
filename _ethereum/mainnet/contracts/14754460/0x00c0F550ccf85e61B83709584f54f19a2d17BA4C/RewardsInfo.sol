// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./IERC721Enumerable.sol";
import "./CollectionsRegistry.sol";
import "./DropperToken.sol";
import "./DroppingNowToken.sol";

contract RewardsInfo {
    address public immutable DROP_REWARD_ESCROW;
    CollectionsRegistry public immutable COLLECTIONS_REGISTRY;
    DropperToken public immutable DROPPER_TOKEN;
    DroppingNowToken public immutable DROPPING_NOW_TOKEN;

    struct DNRewardsInfo {
        uint256 myMinted;
        uint256 myUnminted;
        uint256 rewardsToClaim;
        uint256 unmintedDNSupply;
        uint256 mintedDNSupply;
    }

    struct DTRewardsInfo {
        uint256 id;
        address collection;
        bytes collectionOwnerRaw;
        bool isCollectionApproved;
        uint256 myMinted;
        uint256 myUnminted;
        uint256 escrowUnminted;
        uint256 rewardsToClaim;
        uint256 unmintedDTSupply;
        uint256 mintedDTSupply;
        bytes totalCollectionSupplyRaw;
    }

    constructor(
        address dropRewardEscrowAddress,
        address collectionsRegistryAddress,
        address dropperTokenAddress,
        address droppingNowTokenAddress
    ) {
        DROP_REWARD_ESCROW = dropRewardEscrowAddress;
        COLLECTIONS_REGISTRY = CollectionsRegistry(collectionsRegistryAddress);
        DROPPER_TOKEN = DropperToken(dropperTokenAddress);
        DROPPING_NOW_TOKEN = DroppingNowToken(droppingNowTokenAddress);
    }

    function getDNRewardsInfoBatch(address[] calldata owners) external view returns (DNRewardsInfo[] memory) {
        DNRewardsInfo[] memory rewardsInfo = new DNRewardsInfo[](owners.length);
      
        for (uint256 i = 0; i < owners.length; i++) {
            address ownerAddress = owners[i];

            uint256 myMinted = DROPPING_NOW_TOKEN.balanceOf(ownerAddress);
            uint256 myUnminted = DROPPING_NOW_TOKEN.mintableBalanceOf(ownerAddress);
            uint256 rewardsToClaim = DROPPING_NOW_TOKEN.rewardBalanceOf(ownerAddress);
            uint256 unmintedDNSupply = DROPPING_NOW_TOKEN.totalMintableSupply();
            uint256 mintedDNSupply = DROPPING_NOW_TOKEN.totalSupply();

            DNRewardsInfo memory info = DNRewardsInfo(
                myMinted,
                myUnminted,
                rewardsToClaim,
                unmintedDNSupply,
                mintedDNSupply);

            rewardsInfo[i] = info;
        }

        return rewardsInfo;
    }

    function getDTRewardsInfoBatch(
        address[] calldata collectionAddresses,
        address[] calldata owners
    ) external view returns (DTRewardsInfo[] memory) {
        DTRewardsInfo[] memory rewardsInfo = new DTRewardsInfo[](collectionAddresses.length);
      
        for (uint256 i = 0; i < collectionAddresses.length; i++) {
            address collectionAddress = collectionAddresses[i];
            address ownerAddress = owners[i];

            uint256 id = DROPPER_TOKEN.getId(collectionAddress);
            bool isCollectionApproved = COLLECTIONS_REGISTRY.isCollectionApproved(collectionAddress);
            uint256 myMinted = DROPPER_TOKEN.balanceOf(ownerAddress, id);
            uint256 myUnminted = DROPPER_TOKEN.mintableBalanceOf(ownerAddress, id);
            uint256 escrowUnminted = DROPPER_TOKEN.mintableBalanceOf(DROP_REWARD_ESCROW, id);
            uint256 rewardsToClaim = DROPPER_TOKEN.rewardBalanceOf(ownerAddress, id);
            uint256 unmintedDTSupply = DROPPER_TOKEN.totalMintableSupply(id);
            uint256 mintedDTSupply = DROPPER_TOKEN.totalSupply(id);
            bytes memory totalCollectionSupplyRaw = _getTotalCollectionSupplyRaw(collectionAddress);
            bytes memory collectionOwnerRaw = _getCollectionOwnerRaw(collectionAddress);

            DTRewardsInfo memory info = DTRewardsInfo(
                id, 
                collectionAddress,
                collectionOwnerRaw,
                isCollectionApproved,
                myMinted,
                myUnminted,
                escrowUnminted,
                rewardsToClaim,
                unmintedDTSupply,
                mintedDTSupply,
                totalCollectionSupplyRaw);

            rewardsInfo[i] = info;
        }

        return rewardsInfo;
    }

    function _getTotalCollectionSupplyRaw(address collectionAddress) internal view returns (bytes memory totalCollectionSupplyRaw) {
        (bool success, bytes memory returnData) = collectionAddress.staticcall(
            abi.encodeWithSelector(IERC721Enumerable.totalSupply.selector)
        );

        if (success) {
            totalCollectionSupplyRaw = returnData;
        }

        return totalCollectionSupplyRaw;
    }

    function _getCollectionOwnerRaw(address collectionAddress) internal view returns (bytes memory collectionOwnerRaw) {
        (bool success, bytes memory returnData) = collectionAddress.staticcall(
            abi.encodeWithSelector(Ownable.owner.selector)
        );

        if (success) {
            collectionOwnerRaw = returnData;
        }

        return collectionOwnerRaw;
    }
}