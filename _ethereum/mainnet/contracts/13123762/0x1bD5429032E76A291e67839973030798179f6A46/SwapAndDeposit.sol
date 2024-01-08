//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;
import "./IERC20.sol";
import "./ERC20.sol";

interface IWETH9 is IERC20 {
    function deposit() external payable;
}

interface IRootChainManager {
    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external virtual;
}

abstract contract SwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        virtual
        returns (uint256 amountOut);
}

contract SwapAndDeposit {
    IERC20 constant ERC20_PREDICATE_PROXY =
        IERC20(0x40ec5B33f54e0E8A33A975908C5BA1c14e5BbbDf);
    IERC20 constant MATIC_TOKEN =
        IERC20(0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0);

    IRootChainManager constant ROOT_CHAIN_MANAGER =
        IRootChainManager(0xA0c68C638235ee32657e8f720a23ceC1bFc77C77);
    IWETH9 constant WETH9 = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    uint24 constant FEE = 3000;
    SwapRouter constant SWAP_ROUTER =
        SwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    constructor() {
        MATIC_TOKEN.approve(address(ERC20_PREDICATE_PROXY), type(uint256).max);
        WETH9.approve(address(SWAP_ROUTER), type(uint256).max);
    }

    function foo() external payable {
        WETH9.deposit{value: msg.value}();
    }

    function swapAndDepositETH(uint256 deadline, uint256 amountOutMinimum)
        external
        payable
    {
        /* WETH9.deposit{ value: msg.value }(); */
        uint256 outputAmount =
            SWAP_ROUTER.exactInputSingle(
                SwapRouter.ExactInputSingleParams({
                    tokenIn: address(WETH9),
                    tokenOut: address(MATIC_TOKEN),
                    fee: FEE,
                    recipient: msg.sender,
                    deadline: block.timestamp,
                    amountIn: 1000000000000000,
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                })
            );
        /* uint256 outputAmount = */
        /*     SWAP_ROUTER.exactInputSingle( */
        /*         SwapRouter.ExactInputSingleParams({ */
        /*             tokenIn: address(_WETH9), */
        /*             tokenOut: address(MATIC_TOKEN), */
        /*             fee: FEE, */
        /*             recipient: address(this), */
        /*             deadline: deadline, */
        /*             amountIn: msg.value, */
        /*             amountOutMinimum: amountOutMinimum, */
        /*             sqrtPriceLimitX96: 0 */
        /*         }) */
        /*     ); */
        /* ROOT_CHAIN_MANAGER.depositFor( */
        /*     msg.sender, */
        /*     address(MATIC_TOKEN), */
        /*     abi.encodePacked(outputAmount) */
        /* ); */
    }
}
