// SPDX-License-Identifier: MIT;
pragma solidity >=0.7.6;
pragma experimental ABIEncoderV2;

import "./IUniswapV3FlashCallback.sol";
import "./IUniswapV3Factory.sol";
import "./LowGasSafeMath.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./Ownable.sol";
import "./IOneinchRouter.sol";
import "./ReentrancyGuard.sol";
/// @title Flashloan contract implementation
/// @notice contract using the Uniswap V3 flash function
contract UniswapFlash1Inch is 
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments,
    ReentrancyGuard,
    Ownable {
    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
    }
    using LowGasSafeMath for uint256;
    IUniswapV3Pool public flashPool;
    uint24 public flashPoolFee;  //  flash from the 0.05% fee of pool
    constructor(
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {}
    function initUniFlashSwap(
        address[] calldata loanAssets,
        uint256[] calldata loanAmounts,
        address[] calldata tokenPath,
        address[] calldata oneInchRouters,
        bytes[] calldata tradeDatas
    ) external nonReentrant {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey(
            {
                token0: loanAssets[0],
                token1: loanAssets[1],
                fee: flashPoolFee
            }
        );
        flashPool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(address(flashPool) != address(0), "Invalid flash pool!");

        flashPool.flash(
            address(this),
            loanAmounts[0],
            loanAmounts[1],
            abi.encode(
                FlashCallbackData({
                    amount0: loanAmounts[0],
                    amount1: loanAmounts[1],
                    payer: msg.sender,
                    poolKey: poolKey
                }),
                tokenPath,
                oneInchRouters,
                tradeDatas
            )
        );
    }

    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(flashPool), "Only Pool can call!");
        (
            FlashCallbackData memory callback,
            address[] memory tokenPath,
            address[] memory routers,
            bytes[] memory tradeDatas
        ) = abi.decode(data, (FlashCallbackData, address[],  address[], bytes[]));
        CallbackValidation.verifyCallback(factory, callback.poolKey);
        require(
            callback.amount0 == 0 ||  callback.amount1 == 0,
            "one of amounts must be 0"
        );
        address loanAsset = callback.amount0 > 0 ? callback.poolKey.token0: callback.poolKey.token1;
        uint256 loanAmount = callback.amount0 > 0 ? callback.amount0: callback.amount1;
        uint256 fee = callback.amount0 > 0 ? fee0 : fee1;
        address payer = callback.payer;
        // start trade
        for (uint i; i < tokenPath.length; i++) {
            address router = routers[i];
            address tokenIn = tokenPath[i];
            uint256 amountIn = IERC20(tokenIn).balanceOf(address(this));
            TransferHelper.safeApprove(tokenIn, router, amountIn);
            (bool success, ) = router.call(tradeDatas[i]);
            require(success, "Swap Failue!");

        }
        uint256 amountOut = IERC20(loanAsset).balanceOf(address(this));
        uint256 amountOwed = LowGasSafeMath.add(loanAmount, fee);
        
        if (amountOut >= amountOwed) {
            pay(loanAsset, address(this), msg.sender, amountOwed);
        }
        uint256 profit = LowGasSafeMath.sub(amountOut, amountOwed);
        if (profit > 0) {
            pay(loanAsset, address(this), payer, profit);
        }
    }
    
    function setFlashPoolFee(uint24 poolFee) public onlyOwner() {
        flashPoolFee = poolFee;
    }
    fallback() external payable {}
}
