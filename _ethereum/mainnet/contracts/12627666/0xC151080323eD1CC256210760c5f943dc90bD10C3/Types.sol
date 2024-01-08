//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

library Types {

    struct TokenAmount {
        IERC20 token;
        uint112 amount;
    }

    //status of order. Only tracked on action from user/miners
    enum OrderStatus {
        UNDEFINED,
        PENDING,
        FILLED,
        CANCELLED,
        PENALIZED
    }


    enum OrderType {
        EXACT_IN,
        EXACT_OUT
    }

    struct Order {

        //fee offered (120+128 = 248)
        uint128 fee;

        //the fee that needs to be paid to a target DEX in ETH
        uint128 dexFee;

        //trader that owns the order
        address trader;

        //the type of trade being made
        OrderType orderType;

        //token being offered
        TokenAmount input;

        //token wanted
        TokenAmount output;
    }

    /**
     * A trader's gas tank balance and any amount that's 
     * thawing waiting for withdraw.
     */
    struct Gas {
        //available balance used to pay for fees
        uint112 balance;

        //amount user is asking to withdraw after a that period expires
        uint112 thawing;

        //the block at which any thawing amount can be withdrawn
        uint256 thawingUntil;
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