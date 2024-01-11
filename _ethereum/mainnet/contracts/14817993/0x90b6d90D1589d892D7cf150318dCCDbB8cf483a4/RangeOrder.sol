// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IUniswapV3Pool.sol";
import "./IERC721Receiver.sol";
import "./INonfungiblePositionManager.sol";
import "./IWETH9.sol";
import "./IEjectLP.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./Proxied.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./SEject.sol";
import "./SRangeOrder.sol";
import "./CEjectLP.sol";
import "./FEjectLp.sol";

// BE CAREFUL: DOT NOT CHANGE THE ORDER OF INHERITED CONTRACT
contract RangeOrder is
    Initializable,
    Proxied,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IERC721Receiver
{
    using SafeERC20 for IERC20;

    // solhint-disable-next-line max-line-length
    ////////////////////////////////////////// CONSTANTS AND IMMUTABLES ///////////////////////////////////

    INonfungiblePositionManager public immutable nftPositionManager;
    IEjectLP public immutable eject;
    IWETH9 public immutable WETH9; // solhint-disable-line var-name-mixedcase
    address public immutable rangeOrderResolver;

    // !!!!!!!!!!!!!!!!!!!!!!!! EVENTS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    event LogSetRangeOrder(
        uint256 indexed tokenId,
        address pool,
        uint256 amountIn
    );

    event LogCancelRangeOrder(
        uint256 indexed tokenId,
        uint256 amount0,
        uint256 amount1
    );

    // solhint-disable-next-line var-name-mixedcase, func-param-name-mixedcase
    constructor(
        INonfungiblePositionManager nftPositionManager_,
        IEjectLP eject_,
        IWETH9 WETH9_, // solhint-disable-line var-name-mixedcase, func-param-name-mixedcase
        address rangeOrderResolver_
    ) {
        nftPositionManager = nftPositionManager_;
        eject = eject_;
        WETH9 = WETH9_;
        rangeOrderResolver = rangeOrderResolver_;
    }

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
    }

    // !!!!!!!!!!!!!!!!!!!!!!!! ADMIN FUNCTIONS !!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    function pause() external onlyProxyAdmin {
        _pause();
    }

    function unpause() external onlyProxyAdmin {
        _unpause();
    }

    // solhint-disable-next-line function-max-lines
    function setRangeOrder(RangeOrderParams calldata params_)
        external
        payable
        whenNotPaused
        nonReentrant
    {
        uint256 tokenId;
        uint24 fee;
        {
            int24 lowerTick;
            int24 upperTick;
            {
                int24 tickSpacing = params_.pool.tickSpacing();

                require(
                    params_.tickThreshold % tickSpacing == 0,
                    "RangeOrder:setRangeOrder:: threshold must be initializable tick"
                );

                lowerTick = params_.zeroForOne
                    ? params_.tickThreshold
                    : params_.tickThreshold - tickSpacing;
                upperTick = params_.zeroForOne
                    ? params_.tickThreshold + tickSpacing
                    : params_.tickThreshold;
            }

            _requirePoolTickNotInRange(
                params_.pool,
                params_.tickThreshold,
                params_.zeroForOne
            );

            address token0 = params_.pool.token0();
            address token1 = params_.pool.token1();
            fee = params_.pool.fee();

            {
                IERC20 tokenIn = IERC20(params_.zeroForOne ? token0 : token1);

                if (
                    address(tokenIn) == address(WETH9) &&
                    msg.value > params_.maxFeeAmount
                ) {
                    require(
                        msg.value > params_.amountIn,
                        "RangeOrder:setRangeOrder:: Invalid amount in."
                    );

                    require(
                        msg.value - params_.amountIn == params_.maxFeeAmount,
                        "RangeOrder:setRangeOrder:: Invalid maxFeeAmount."
                    );

                    WETH9.deposit{value: params_.amountIn}();
                } else {
                    require(
                        msg.value == params_.maxFeeAmount,
                        "RangeOrder:setRangeOrder:: Invalid maxFeeAmount."
                    );

                    tokenIn.safeTransferFrom(
                        msg.sender,
                        address(this),
                        params_.amountIn
                    );
                }

                tokenIn.safeIncreaseAllowance(
                    address(nftPositionManager),
                    params_.amountIn
                );
            }

            {
                uint256 amount0;
                uint256 amount1;
                uint256 minLiquidity0;
                uint256 minLiquidity1;
                if (params_.zeroForOne) {
                    amount0 = params_.amountIn;
                    minLiquidity0 = params_.minLiquidity;
                    amount1 = minLiquidity1 = 0;
                } else {
                    amount0 = minLiquidity0 = 0;
                    amount1 = params_.amountIn;
                    minLiquidity1 = params_.minLiquidity;
                }

                (tokenId, , , ) = nftPositionManager.mint(
                    INonfungiblePositionManager.MintParams({
                        token0: token0,
                        token1: token1,
                        fee: fee,
                        tickLower: lowerTick,
                        tickUpper: upperTick,
                        amount0Desired: amount0,
                        amount1Desired: amount1,
                        amount0Min: minLiquidity0,
                        amount1Min: minLiquidity1,
                        recipient: address(this),
                        deadline: block.timestamp // solhint-disable-line not-rely-on-time
                    })
                );
            }

            nftPositionManager.approve(address(eject), tokenId);
            eject.schedule{value: params_.maxFeeAmount}(
                OrderParams({
                    tokenId: tokenId,
                    tickThreshold: params_.tickThreshold,
                    ejectAbove: params_.zeroForOne,
                    receiver: params_.receiver,
                    feeToken: ETH,
                    resolver: rangeOrderResolver,
                    maxFeeAmount: params_.maxFeeAmount,
                    ejectAtExpiry: true
                })
            );
        }

        emit LogSetRangeOrder(tokenId, address(params_.pool), params_.amountIn);
    }

    // solhint-disable-next-line function-max-lines
    function cancelRangeOrder(
        uint256 tokenId_,
        RangeOrderParams calldata params_,
        uint256 startTime_
    ) external whenNotPaused nonReentrant {
        require(
            params_.receiver == msg.sender,
            "RangeOrder::cancelRangeOrder: only receiver."
        );

        eject.cancel(
            tokenId_,
            Order({
                tickThreshold: params_.tickThreshold,
                ejectAbove: params_.zeroForOne,
                receiver: params_.receiver,
                owner: address(this),
                maxFeeAmount: params_.maxFeeAmount,
                startTime: startTime_,
                ejectAtExpiry: true
            })
        );

        (, , , , , , , uint128 liquidity, , , , ) = nftPositionManager
            .positions(tokenId_);

        nftPositionManager.approve(params_.receiver, tokenId_); // remove approval to EjectLP.

        (uint256 amount0, uint256 amount1) = _collect(
            nftPositionManager,
            tokenId_,
            liquidity,
            params_.receiver
        );

        emit LogCancelRangeOrder(tokenId_, amount0, amount1);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function _requirePoolTickNotInRange(
        IUniswapV3Pool pool_,
        int24 tickThreshold,
        bool ejectAbove
    ) internal view {
        (, int24 tick, , , , , ) = pool_.slot0();

        require(
            ejectAbove ? tick < tickThreshold : tick > tickThreshold,
            "RangeOrder:_requireThresholdInRange:: eject tick in range"
        );
    }
}
