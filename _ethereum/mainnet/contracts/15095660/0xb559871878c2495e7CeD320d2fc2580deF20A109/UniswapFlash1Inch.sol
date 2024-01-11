// SPDX-License-Identifier: MIT;
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV3FlashCallback.sol";
import "./IUniswapV3Pool.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";
import "./PoolAddress.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
contract UniswapFlash1Inch is 
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments,
    ReentrancyGuard,
    Ownable {
    using SafeMath for uint256;
    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
    }
    address public oneInchRouter = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    uint24 public flashPoolFee = 500;  //  flash from the 0.05% fee of pool
    constructor(
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {}
    function initUniFlashSwap(
        address[] calldata loanAssets,
        uint256[] calldata loanAmounts,
        address[] calldata tokenPath,
        // address[] calldata oneInchRouters,
        bytes[] calldata tradeDatas
    ) external nonReentrant {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey(
            {
                token0: loanAssets[0],
                token1: loanAssets[1],
                fee: flashPoolFee
            }
        );
        uint amount0 = loanAmounts[0];
        uint amount1 = loanAmounts[1];
        address flashPool = getFlashPool(factory, poolKey);
        require(flashPool != address(0), "Invalid flash pool!");

        IUniswapV3Pool(flashPool).flash(
            address(this),
            amount0,
            amount1,
            abi.encode(
                FlashCallbackData({
                    amount0: amount0,
                    amount1: amount1,
                    payer: msg.sender,
                    poolKey: poolKey
                }),
                tokenPath,
                // oneInchRouters,
                tradeDatas
            )
        );
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        address self = address(this); 
        (
            FlashCallbackData memory callback,
            address[] memory tokenPath,
            // address[] memory routers,
            bytes[] memory tradeDatas
        ) = abi.decode(data, (FlashCallbackData, address[], bytes[]));
        require(msg.sender == getFlashPool(factory, callback.poolKey), "Only Pool can call!");
        // CallbackValidation.verifyCallback(factory, callback.poolKey);
        // require(
        //     callback.amount0 == 0 ||  callback.amount1 == 0,
        //     "one of amounts must be 0"
        // );
        address loanToken = callback.amount0 > 0 ? callback.poolKey.token0: callback.poolKey.token1;
        uint256 loanAmount = callback.amount0 > 0 ? callback.amount0: callback.amount1;
        uint256 fee = callback.amount0 > 0 ? fee0 : fee1;
        // address payer = callback.payer;
        // start trade
        for (uint i; i < tradeDatas.length; i++) {
            // address router = routers[i];
            // address tokenIn = tokenPath[i];
            uint256 amountIn = IERC20(tokenPath[i]).balanceOf(self);
            require(amountIn > 0, "Balanace is 0!");
            // approveToken(tokenIn, router);
            (bool success, ) = oneInchRouter.call(tradeDatas[i]);
            require(success, "Swap Failue!");
        }
        uint256 amountOut = IERC20(loanToken).balanceOf(self);
        uint256 amountOwed = loanAmount.add(fee);
        
        if (amountOut >= amountOwed) {
            pay(loanToken, self, msg.sender, amountOwed);
        }
        uint256 profit = amountOut.sub(amountOwed);
        if (profit > 0) {
            pay(loanToken, self, callback.payer, profit);
        }
    }
    function getFlashPool(
        address factory, 
        PoolAddress.PoolKey memory poolKey
    ) public pure returns (address) {
        return PoolAddress.computeAddress(factory, poolKey);
    }
    function approveToken(address token) public {
        TransferHelper.safeApprove(token, oneInchRouter, uint(-1));
    }
    function setFlashPoolFee(uint24 poolFee) public onlyOwner() {
        flashPoolFee = poolFee;
    }
    function changeOneInchRouter(address router) public onlyOwner() {
        oneInchRouter = router;
    }
    fallback() external payable {}
//     receive() external payable {
//         // solhint-disable-next-line avoid-tx-origin
//         require(msg.sender != tx.origin, "ETH deposit rejected");
//     }
}
