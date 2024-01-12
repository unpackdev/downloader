// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IWETHUpgradable.sol";
import "./IDelegate.sol";

contract ABIGeneratorX2Y2 {
    
    enum Op {
        INVALID,
        COMPLETE_SELL_OFFER,
        COMPLETE_BUY_OFFER,
        CANCEL_OFFER,
        BID,
        COMPLETE_AUCTION,
        REFUND_AUCTION,
        REFUND_AUCTION_STUCK_ITEM
    }

    struct OrderItem {
        uint256 price;
        bytes data;
    }

    struct Order {
        uint256 salt;
        address user;
        uint256 network;
        uint256 intent;
        uint256 delegateType;
        uint256 deadline;
        IERC20Upgradeable currency;
        bytes dataMask;
        OrderItem[] items;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signVersion;
    }

    struct Fee {
        uint256 percentage;
        address to;
    }

    struct SettleDetail {
        Op op;  //was Market.Op
        uint256 orderIdx;
        uint256 itemIdx;
        uint256 price;
        bytes32 itemHash;
        IDelegate executionDelegate;
        bytes dataReplacement;
        uint256 bidIncentivePct;
        uint256 aucMinIncrementPct;
        uint256 aucIncDurationSecs;
        Fee[] fees;
    }

    struct SettleShared {
        uint256 salt;
        uint256 deadline;
        uint256 amountToEth;
        uint256 amountToWeth;
        address user;
        bool canFail;
    }
    
    function generateAbiRun(
        Order[] memory orders,
        SettleDetail[] memory details,
        SettleShared memory shared,
        bytes32 r,
        bytes32 s,
        uint8 v 
    ) external pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "run(Order[],SettleDetail[],SettleShared,bytes32,bytes32,uint8)",
                orders,
                details,
                shared,
                r,
                s,
                v
            );
    }
}

 