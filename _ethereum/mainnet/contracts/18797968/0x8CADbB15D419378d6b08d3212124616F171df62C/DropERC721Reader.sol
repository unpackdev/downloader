// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

/// @author rarible

//    /$$$$$$$                      /$$ /$$       /$$
//    | $$__  $$                    |__/| $$      | $$
//    | $$  \ $$  /$$$$$$   /$$$$$$  /$$| $$$$$$$ | $$  /$$$$$$
//    | $$$$$$$/ |____  $$ /$$__  $$| $$| $$__  $$| $$ /$$__  $$
//    | $$__  $$  /$$$$$$$| $$  \__/| $$| $$  \ $$| $$| $$$$$$$$
//    | $$  \ $$ /$$__  $$| $$      | $$| $$  | $$| $$| $$_____/
//    | $$  | $$|  $$$$$$$| $$      | $$| $$$$$$$/| $$|  $$$$$$$
//    |__/  |__/ \_______/|__/      |__/|_______/ |__/ \_______/


//  ==========  External imports    ==========

import "./MulticallUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./IERC2981Upgradeable.sol";

import "./ERC721AVirtualApproveUpgradeable.sol";

//  ==========  Internal imports    ==========
import "./CurrencyTransferLib.sol";

//  ==========  Features    ==========

import "./ContractMetadata.sol";
import "./PlatformFee.sol";
import "./Royalty.sol";
import "./PrimarySale.sol";
import "./Ownable.sol";
import "./DelayedReveal.sol";
import "./LazyMint.sol";
import "./PermissionsEnumerable.sol";
import "./Drop.sol";
import "./IClaimCondition.sol";
import "./IClaimConditionMultiPhase.sol";

import "./DropERC721.sol";
import "./console.sol";
import "./IERC20.sol";

contract DropERC721Reader {

    struct FeeData {
        address recipient;
        uint256 bps;
    }

    struct GlobalData {
        uint256 totalMinted;
        uint256 claimedByUser;
        uint256 totalSupply;
        uint256 maxTotalSupply;
        uint256 nextTokenIdToMint;
        uint256 nextTokenIdToClaim;
        string name;
        string symbol;
        string contractURI;
        uint256 baseURICount;
        uint256 userBalance;
        uint256 blockTimeStamp;
        FeeData defaultRoyaltyInfo;
        FeeData platformFeeInfo;
    }

    address public constant NATIVE1 = 0x0000000000000000000000000000000000000000;
    address public constant NATIVE2 = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor() {

    }

    function getAllData(
        address _dropERC721,
        address _claimer
    ) public view returns (
        uint256 activeClaimConditionIndex,
        IClaimCondition.ClaimCondition[] memory conditions,
        GlobalData memory globalData
        ) {
        DropERC721 drop = DropERC721(_dropERC721);

        (uint256 startConditionIndex,uint256 stopConditionIndex)  = drop.claimCondition();
        uint256 _claimedByUser = 0;
        if(stopConditionIndex != 0) {
            try drop.getActiveClaimConditionId() returns (uint256 _activeClaimConditionIndex) {
                activeClaimConditionIndex = _activeClaimConditionIndex;
            } catch {
                activeClaimConditionIndex = 0;
            }
            conditions = new IClaimCondition.ClaimCondition[](stopConditionIndex);
            
            for (uint i = 0; i < stopConditionIndex; i++) {
                IClaimCondition.ClaimCondition memory condition = drop.getClaimConditionById(i);
                conditions[i] = condition;
            }
        }

        DropERC721Reader.GlobalData memory _globalData;
        if(stopConditionIndex > 0) {
            _claimedByUser = drop.getSupplyClaimedByWallet(activeClaimConditionIndex, _claimer);
            IClaimCondition.ClaimCondition memory condition = drop.getClaimConditionById(activeClaimConditionIndex);
            if(condition.currency == NATIVE1 || condition.currency == NATIVE2) {
                _globalData.userBalance = _claimer.balance;
            } else {
                _globalData.userBalance = IERC20(condition.currency).balanceOf(_claimer);
            }

        }

        _globalData.totalMinted         = drop.totalMinted();
        _globalData.claimedByUser       = _claimedByUser;
        _globalData.totalSupply         = drop.totalSupply();
        _globalData.maxTotalSupply      = drop.maxTotalSupply();
        _globalData.nextTokenIdToMint   = drop.nextTokenIdToMint();
        _globalData.nextTokenIdToClaim  = drop.nextTokenIdToClaim();
        _globalData.name                = drop.name();
        _globalData.symbol              = drop.symbol();
        _globalData.contractURI         = drop.contractURI();
        _globalData.baseURICount        = drop.getBaseURICount();
        _globalData.blockTimeStamp      = block.timestamp;
        (address rAddress, uint16 rBps)     = drop.getDefaultRoyaltyInfo();
        _globalData.defaultRoyaltyInfo.recipient    = rAddress;
        _globalData.defaultRoyaltyInfo.bps          = rBps;

        (address pAddress, uint16 pBps)     = drop.getPlatformFeeInfo();
        _globalData.platformFeeInfo.recipient       = pAddress;
        _globalData.platformFeeInfo.bps             = pBps;
        return (activeClaimConditionIndex, conditions, _globalData);
    }
}