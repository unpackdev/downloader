
// SPDX-License-Identifier: NONE
pragma solidity =0.8.20;

contract ToadStructs {
    /**
     * token: The token
     * dexId: the position of the dex struct in the list provided - should be the same between input and output token 
     
     */
    struct AggPath {
        address token;
        uint96 dexId;
    }
    /**
     * DexData - a list of UniV2 dexes referred to in AggPath - shared between gasPath and path
     * initcode: the initcode to feed the create2 seed
     * factory: the factory address to feed the create2 seed
     */
    struct DexData {
        bytes32 initcode;
        address factory;
    }
    /**
     * FeeStruct - a batch of fees to be paid in gas and optionally to another account
     */
    struct FeeStruct {
        uint256 gasLimit;
        address feeReceiver;
        uint96 fee;
    }


    struct ExactInputSingleParams {
        address holder;
        bool unwrap;
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        DexData dex;
    }

    struct GasRepayParams {
        bytes path;
        DexData dex;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
        bool isVeth;
        
        DexData dex;
    }

    struct ExactInputParams {
        address holder;
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        DexData dex;
    }


}
