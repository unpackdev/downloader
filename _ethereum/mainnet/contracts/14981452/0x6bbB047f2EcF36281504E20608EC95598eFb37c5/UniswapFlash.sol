// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IUniswapV3FlashCallback.sol";
import "./IUniswapV3Factory.sol";
import "./LowGasSafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./PeripheryPayments.sol";
import "./PeripheryImmutableState.sol";
import "./PoolAddress.sol";
import "./CallbackValidation.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./Helpers.sol";
import "./SwapAssets.sol";

/// @title Flash contract implementation
/// @notice An example contract using the Uniswap V3 flash function
contract UniswapFlash is 
    IUniswapV3FlashCallback,
    PeripheryImmutableState,
    PeripheryPayments,
    SwapAssets {
    

    // fee2 and fee3 are the two other fees associated with the two other pools of token0 and token1
    struct FlashCallbackData {
        uint256 amount0;
        uint256 amount1;
        address payer;
        PoolAddress.PoolKey poolKey;
        // uint24 poolFee2;
        // uint24 poolFee3;
    }

    using LowGasSafeMath for uint256;
    IUniswapV3Pool public flashPool;
    uint24 public flashPoolFee;  //  flash from the 0.05% fee of pool

    event FalshloanInited(
        address indexed _loanAsset,
        uint256 _loanAmount,
        address indexed _tradeAsset,
        uint16 _tradeDex
    );
    event AssetBorrowedFromPool(
        address indexed _pool,
        address indexed _loanAsset,
        uint256 _loanAmount,
        uint256 _fee
    );
    event AssetSwaped(
        address indexed _swapAsset,
        uint256 _swapAmount
    );
    event RepayedAssetToPool(
        address indexed _pool,
        address indexed _repayedAsset,
        uint256 _repayedAmount
    );
    event TransferProfitToWallet(
        address indexed _owner,
        address indexed _profitAsset,
        uint256 _profitAmount
    );
    event ChangedFlashPoolFee(address indexed _sender, uint24 _fee);
    constructor(
        address _factory,
        address _WETH9
    ) PeripheryImmutableState(_factory, _WETH9) {
     
    }

    /// @param loanAssets array of assets pair to loan. for example [token0, token1].
    /// @param loanAmounts array of assets amounts to loan. for example [amount0, amount1].
    ///         one of two amounts must be 0
    /// @param tradeAssets array of assets to trade. end asset must be equal to loaned assest
    /// @param tradeDexs array of dexes to trade.
    /// @notice Calls the pools flash function with data needed in `uniswapV3FlashCallback`
    function initUniFlashSwap(
        address[] calldata loanAssets,
        uint256[] calldata loanAmounts,
        address[] calldata tradeAssets,
        uint16[] calldata tradeDexs
    ) external {
        PoolAddress.PoolKey memory poolKey = PoolAddress.PoolKey(
            {
                token0: loanAssets[0],
                token1: loanAssets[1],
                fee: flashPoolFee
            }
        );
        flashPool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(address(flashPool) != address(0), "Invalid flash pool!");
        emit FalshloanInited(loanAssets[0], loanAmounts[0], tradeAssets[0], tradeDexs[0]);

        // recipient of borrowed amounts (should be (this) contract)
        // amount of token0 requested to borrow
        // amount of token1 requested to borrow
        // need amount 0 and amount1 in callback to pay back pool
        // recipient of flash should be THIS contract
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
                    // poolFee2: params.fee2,
                    // poolFee3: params.fee3
                }),
                tradeAssets,
                tradeDexs
            )
        );
    }

    /// @param fee0 The fee from calling flash for token0
    /// @param fee1 The fee from calling flash for token1
    /// @param data The data needed in the callback passed as FlashCallbackData from `initUniFlashSwap`
    /// @notice implements the callback called from flash
    /// @dev fails if the flash is not profitable, meaning the amountOut from the flash is less than the amount borrowed
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external override {
       
        (
            FlashCallbackData memory decoded,
            address[] memory tradeAssets,
            uint16[] memory tradeDexs
        ) = abi.decode(data, (FlashCallbackData, address[], uint16[]));
        CallbackValidation.verifyCallback(factory, decoded.poolKey);
        require(
            decoded.amount0 == 0 ||  decoded.amount1 == 0,
            "one of amounts must be 0"
        );
        address loanAsset = decoded.amount0 > 0 ? decoded.poolKey.token0: decoded.poolKey.token1;
        uint256 loanAmount = decoded.amount0 > 0 ? decoded.amount0: decoded.amount1;
        uint256 fee = decoded.amount0 > 0 ? fee0 : fee1;
        address payer = decoded.payer;
        emit AssetBorrowedFromPool(msg.sender, loanAsset, loanAmount, fee);
        // start trade
        uint256 amountOut = tradeExecute(
            address(this),
            loanAsset,
            loanAmount,
            tradeAssets,
            tradeDexs
        );
        emit AssetSwaped(loanAsset, amountOut);

        // compute amount to pay back to pool 
        // loanAmount + fee
        uint256 amountOwed = LowGasSafeMath.add(loanAmount, fee);
        
        // pay back pool the loan 
        // note: msg.sender == pool to pay back 
        if (amountOwed > 0) {
            pay(loanAsset, address(this), msg.sender, amountOwed);
            emit RepayedAssetToPool(msg.sender, loanAsset, amountOwed);
        }
        uint256 profit = LowGasSafeMath.sub(amountOut, amountOwed);
        // if profitable pay profits to payer
        if (profit > 0) {
            pay(loanAsset, address(this), payer, profit);
            emit TransferProfitToWallet(payer, loanAsset, profit);
        }
    }
    function setFlashPoolFee(uint24 poolFee) public onlyOwner() {
        flashPoolFee = poolFee;
        emit ChangedFlashPoolFee(msg.sender, poolFee);
    }
    fallback() external payable {}
}
