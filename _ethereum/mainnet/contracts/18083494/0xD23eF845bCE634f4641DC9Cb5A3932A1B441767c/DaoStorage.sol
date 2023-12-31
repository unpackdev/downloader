// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./D4AEnums.sol";
import "./D4AStructs.sol";

library DaoStorage {
    struct DaoInfo {
        // metadata
        uint256 startRound;
        uint256 mintableRound;
        uint256 daoIndex;
        string daoUri;
        address daoFeePool;
        // token related info
        address token;
        uint256 tokenMaxSupply;
        // nft related info
        address nft;
        uint256 nftMaxSupply;
        uint256 nftTotalSupply;
        uint96 royaltyFeeRatioInBps;
        // miscellanous
        bool daoExist;
        PriceTemplateType priceTemplateType;
        RewardTemplateType rewardTemplateType;
        DaoTag daoTag;
        DaoMintInfo daoMintInfo;
        bytes32[] canvases;
        uint256 nftPriceFactor;
        uint256 daoFeePoolETHRatioInBps;
        uint256 daoFeePoolETHRatioInBpsFlatPrice;
    }

    struct Layout {
        mapping(bytes32 daoId => DaoInfo) daoInfos;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("D4Av2.contracts.storage.DaoStorage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
