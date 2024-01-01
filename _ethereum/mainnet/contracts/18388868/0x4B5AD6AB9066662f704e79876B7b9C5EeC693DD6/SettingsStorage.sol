// SPDX-License-Identifier: MIT

pragma solidity >=0.8.10;

import "./ID4ADrb.sol";
import "./ID4AFeePoolFactory.sol";
import "./ID4AERC20Factory.sol";
import "./ID4AERC721Factory.sol";
import "./ID4AOwnerProxy.sol";
import "./IPermissionControl.sol";

library SettingsStorage {
    struct Layout {
        // fee related
        uint256 createDaoFeeAmount;
        uint256 createCanvasFeeAmount;
        uint256 protocolMintFeeRatioInBps;
        uint256 daoFeePoolMintFeeRatioInBps;
        uint256 daoFeePoolMintFeeRatioInBpsFlatPrice;
        uint256 protocolRoyaltyFeeRatioInBps;
        uint256 minRoyaltyFeeRatioInBps;
        uint256 maxRoyaltyFeeRatioInBps;
        uint256 protocolERC20RatioInBps;
        uint256 daoCreatorERC20RatioInBps;
        uint256 canvasCreatorERC20RatioInBps;
        // contract address
        address protocolFeePool;
        ID4ADrb drb;
        ID4AERC20Factory erc20Factory;
        ID4AERC721Factory erc721Factory;
        ID4AFeePoolFactory feePoolFactory;
        ID4AOwnerProxy ownerProxy;
        IPermissionControl permissionControl;
        address createProjectProxy;
        // params
        uint256 tokenMaxSupply;
        uint256 maxMintableRound; //366
        uint256[] mintableRounds;
        uint256[] daoFloorPrices;
        uint256[] nftMaxSupplies;
        address assetOwner;
        bool isProtocolPaused;
        mapping(bytes32 => bool) pauseStatuses;
        uint256 reservedDaoAmount;
        address[256] priceTemplates;
        address[256] rewardTemplates;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.Settings");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
