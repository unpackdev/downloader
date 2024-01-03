//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

library Types {

    struct TokenAmount {
        IERC20 token;
        uint112 amount;
    }

    struct GasAllowance {
        uint112 maxGas;
        uint8 percentGasPaid;
    }

    enum OrderType {
        EXACT_IN,
        EXACT_OUT
    }

    //status of order. Only tracked on action from user/miners
    enum OrderStatus {
        UNDEFINED,
        PENDING,
        FILLED,
        CANCELLED,
        PENALIZED
    }

    struct Order {
        //trader that owns the order
        address trader;

        //fee offered (120+128 = 248)
        uint128 fee;

        //how much gas is the user allowing?
        GasAllowance gasAllowance;

        //type of order being filled
        OrderType orderType;

        //token being offered
        TokenAmount input;

        //token wanted
        TokenAmount output;
    }

    struct Gas {
        uint112 balance;
        uint112 locked;
        uint256 lockedUntil;
    }



    //============== CONFIG STATE =============/
    struct Config {
        //dev team address (120b)
        address devTeam;

        //min fee amount (128b, 248b chunk)
        uint128 minFee;

        //penalty a user faces for removing assets or 
        //allowances before a trade
        uint128 penaltyFee;

        //number of blocks to lock stake and order cancellations
        uint8 lockoutBlocks;
    }

    //============== ACCESS STATE =============/
    //storage structure of access controls
    struct AccessControl {
        bool reentrantFlag;
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    //============== INITIALIZATION STATE =============/
    struct InitControls {
        bool initialized;
        bool initializing;
    }
    
    //=============== GAS TANK STATE =============/
    struct GasBalances {
        mapping(address => Gas) balances;
    }
}