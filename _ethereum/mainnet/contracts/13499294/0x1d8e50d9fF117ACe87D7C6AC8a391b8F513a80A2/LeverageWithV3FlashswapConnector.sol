// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IUniswapV3PoolActions.sol";
import "./TickMath.sol";
import "./SafeCast.sol";
import "./PoolAddress.sol";

import "./SimplePositionBaseConnector.sol";
import "./ILeverageWithV3FlashswapConnector.sol";
import "./FundsManager.sol";
import "./FlashswapStorage.sol";

contract LeverageWithV3FlashswapConnector is
    SimplePositionBaseConnector,
    FundsManager,
    FlashswapStorage,
    ILeverageWithV3FlashswapConnector
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeCast for uint256;

    address private immutable SELF_ADDRESS;
    address private immutable factory;

    constructor(
        uint256 _principal,
        uint256 _profit,
        address _holder,
        address _factory
    ) public FundsManager(_principal, _profit, _holder) {
        SELF_ADDRESS = address(this);
        factory = _factory;
    }

    function increasePositionWithV3Flashswap(IncreasePositionWithFlashswapParams calldata params)
        external
        override
        onlyAccountOwnerOrRegistry
    {
        _verifySetup(params.platform, params.supplyToken, params.borrowToken);

        address pool = getPool(params.supplyToken, params.borrowToken, params.fee);
        _setExpectedCallback(pool);

        bool zeroForOne = params.borrowToken < params.supplyToken;

        IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            params.borrowAmount.toInt256(), // positive amount => this amount is the exact input
            (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            abi.encode(
                SwapCallbackDataParams(
                    true,
                    abi.encode(
                        IncreasePositionInternalParams(
                            params.principalAmount,
                            params.minimumSupplyAmount,
                            params.borrowToken,
                            params.supplyToken,
                            params.platform
                        )
                    )
                )
            )
        );
    }

    function decreasePositionWithV3Flashswap(DecreasePositionWithFlashswapParams calldata params)
        external
        override
        onlyAccountOwner
    {
        requireSimplePositionDetails(params.platform, params.supplyToken, params.borrowToken);
        require(params.maximumFlashAmount <= params.redeemAmount, 'LWV3FC3');

        address pool = getPool(params.supplyToken, params.borrowToken, params.fee);
        _setExpectedCallback(pool);

        bool zeroForOne = params.borrowToken > params.supplyToken;

        address lender = getLender(params.platform);
        uint256 debt = getBorrowBalance(lender, params.platform, params.borrowToken);

        IUniswapV3PoolActions(pool).swap(
            address(this),
            zeroForOne,
            params.repayAmount > debt ? -(debt.toInt256()) : -(params.repayAmount.toInt256()), // negative amount => this amount is an exact output
            (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1),
            abi.encode(
                SwapCallbackDataParams(
                    false,
                    abi.encode(
                        DecreasePositionInternalParams(
                            params.redeemAmount,
                            params.maximumFlashAmount,
                            debt,
                            params.borrowToken,
                            params.supplyToken,
                            params.platform,
                            lender
                        )
                    )
                )
            )
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _verifyCallbackAndClear();

        SwapCallbackDataParams memory data = abi.decode(_data, (SwapCallbackDataParams));

        if (data.increasePosition) {
            IncreasePositionInternalParams memory params = abi.decode(
                data.internalParams,
                (IncreasePositionInternalParams)
            );

            uint256 amountToSupply = amount0Delta < 0
                ? params.principalAmount.add(uint256(-amount0Delta))
                : params.principalAmount.add(uint256(-amount1Delta));

            require(amountToSupply >= params.minimumSupplyAmount, 'LWV3FC1');
            uint256 amountToBorrow = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);

            addPrincipal(params.principalAmount);

            _increasePosition(params.platform, params.supplyToken, amountToSupply, params.borrowToken, amountToBorrow);
            IERC20(params.borrowToken).safeTransfer(msg.sender, amountToBorrow);
        } else {
            DecreasePositionInternalParams memory params = abi.decode(
                data.internalParams,
                (DecreasePositionInternalParams)
            );

            uint256 amountOwedToPool = uint256(amount0Delta > 0 ? amount0Delta : amount1Delta);
            uint256 deposit = getSupplyBalance(params.lender, params.platform, params.supplyToken);
            uint256 amountToRedeem = params.redeemAmount > deposit ? deposit : params.redeemAmount;

            require(amountOwedToPool <= params.maximumFlashAmount, 'LWV3FC4');
            uint256 amountToRepay = uint256(amount0Delta < 0 ? -amount0Delta : -amount1Delta);

            _decreasePosition(
                params.platform,
                params.lender,
                params.supplyToken,
                amountToRedeem,
                params.borrowToken,
                amountToRepay
            );

            IERC20(params.supplyToken).safeTransfer(msg.sender, amountOwedToPool);

            uint256 amountToWithdraw = amountToRedeem - amountOwedToPool;

            if (amountToWithdraw > 0) {
                uint256 positionValue = deposit.sub(
                    params.debt.mul(getReferencePrice(params.lender, params.platform, params.borrowToken)).div(
                        getReferencePrice(params.lender, params.platform, params.supplyToken)
                    )
                );
                withdraw(amountToWithdraw, positionValue);
            }
        }
    }

    function _increasePosition(
        address platform,
        address supplyToken,
        uint256 amountToSupply,
        address borrowToken,
        uint256 amountToBorrow
    ) internal {
        address lender = getLender(platform);
        supply(lender, platform, supplyToken, amountToSupply);
        borrow(lender, platform, borrowToken, amountToBorrow);
    }

    function _decreasePosition(
        address platform,
        address lender,
        address supplyToken,
        uint256 amountToRedeem,
        address borrowToken,
        uint256 amountToRepay
    ) internal {
        repayBorrow(lender, platform, borrowToken, amountToRepay);
        redeemSupply(lender, platform, supplyToken, amountToRedeem);
    }

    function _verifySetup(
        address platform,
        address supplyToken,
        address borrowToken
    ) internal {
        address lender = getLender(platform);

        if (isSimplePosition()) {
            requireSimplePositionDetails(platform, supplyToken, borrowToken);
        } else {
            simplePositionStore().platform = platform;
            simplePositionStore().supplyToken = supplyToken;
            simplePositionStore().borrowToken = borrowToken;

            address[] memory markets = new address[](2);
            markets[0] = supplyToken;
            markets[1] = borrowToken;
            enterMarkets(lender, platform, markets);
        }
    }

    function _setExpectedCallback(address pool) internal {
        aStore().callbackTarget = SELF_ADDRESS;
        aStore().expectedCallbackSig = bytes4(keccak256('uniswapV3SwapCallback(int256,int256,bytes)'));
        flashswapStore().expectedCaller = pool;
    }

    function _verifyCallbackAndClear() internal {
        // Verify and clear authorisations for callbacks
        require(msg.sender == flashswapStore().expectedCaller, 'LWV3FC2');
        delete flashswapStore().expectedCaller;
        delete aStore().callbackTarget;
        delete aStore().expectedCallbackSig;
    }

    /// @dev Returns the pool for the given token pair and fee. The pool contract may or may not exist.
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) private view returns (address) {
        return PoolAddress.computeAddress(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }
}
