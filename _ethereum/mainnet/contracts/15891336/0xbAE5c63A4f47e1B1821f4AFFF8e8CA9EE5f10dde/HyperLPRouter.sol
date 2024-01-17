// SPDX-License-Identifier: MIT

/***
 *      ______             _______   __                                             
 *     /      \           |       \ |  \                                            
 *    |  $$$$$$\ __    __ | $$$$$$$\| $$  ______    _______  ______ ____    ______  
 *    | $$$\| $$|  \  /  \| $$__/ $$| $$ |      \  /       \|      \    \  |      \ 
 *    | $$$$\ $$ \$$\/  $$| $$    $$| $$  \$$$$$$\|  $$$$$$$| $$$$$$\$$$$\  \$$$$$$\
 *    | $$\$$\$$  >$$  $$ | $$$$$$$ | $$ /      $$ \$$    \ | $$ | $$ | $$ /      $$
 *    | $$_\$$$$ /  $$$$\ | $$      | $$|  $$$$$$$ _\$$$$$$\| $$ | $$ | $$|  $$$$$$$
 *     \$$  \$$$|  $$ \$$\| $$      | $$ \$$    $$|       $$| $$ | $$ | $$ \$$    $$
 *      \$$$$$$  \$$   \$$ \$$       \$$  \$$$$$$$ \$$$$$$$  \$$  \$$  \$$  \$$$$$$$
 *                                                                                  
 *                                                                                  
 *                                                                                  
 */

pragma solidity ^0.8.4;

import "./IERC20.sol";

import "./IUniswapV3Factory.sol";

import "./IUniswapV3Pool.sol";

import "./IUniswapV3SwapCallback.sol";

import "./GasStationRecipient.sol";
import "./Ownable.sol";
import "./IHyper.sol";
import "./IHyperStorage.sol";
import "./SafeERC20v2.sol";
import "./LiquidityAmounts.sol";
import "./SafeCast.sol";
import "./TickMath.sol";

interface IERC20Meta {
    function decimals() external view returns (uint8);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract HyperLPRouter is IUniswapV3SwapCallback, GasStationRecipient, Ownable {
    using SafeERC20v2 for IERC20;
    using TickMath for int24;
    using SafeCast for uint256;

    address private constant _ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    IUniswapV3Factory public immutable factory;
    IWETH public immutable wETH;

    constructor(address hyperlpfactory, address weth) {
        factory = IUniswapV3Factory(
            IHyperLPoolFactoryStorage(hyperlpfactory).factory()
        );
        wETH = IWETH(weth);
    }

    event Minted(
        address receiver,
        uint256 mintAmount,
        uint256 amount0In,
        uint256 amount1In,
        uint128 liquidityMinted
    );

    /**
     * @notice mint fungible `hyperpool` tokens with `token` or ETH transformation
     * to `hyperpool` tokens
     * when current tick is outside of [lowerTick, upperTick]
     * @dev see HyperLPool.mint method
     * @param hyperpool HyperLPool address
     * @param paymentToken token to pay
     * @param paymentAmount amount of token to pay
     * @return amount0 amount of token0 transferred from msg.sender to mint `mintAmount`
     * @return amount1 amount of token1 transferred from msg.sender to mint `mintAmount`
     * @return mintAmount The number of HyperLP tokens to mint
     * @return liquidityMinted amount of liquidity added to the underlying Uniswap V3 position
     */
    // solhint-disable-next-line function-max-lines
    function mint(
        address hyperpool,
        address paymentToken,
        uint256 paymentAmount
    )
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 mintAmount,
            uint128 liquidityMinted
        )
    {
        require(paymentAmount > 0, "!amount");
        (uint256 share0, address token0, address token1) =
            _calcShare(IHyperLPoolStorage(hyperpool), paymentAmount);

        uint24 fee = IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).fee();
        uint256 amount0Max = _swap(paymentToken, token0, fee, share0);
        uint256 amount1Max =
            _swap(paymentToken, token1, fee, paymentAmount - share0);

        IERC20(token0).safeApprove(hyperpool, amount0Max);
        IERC20(token1).safeApprove(hyperpool, amount1Max);

        (amount0, amount1, mintAmount, liquidityMinted) = IHyperLPool(hyperpool)
            .mint(amount0Max, amount1Max, _msgSender());

        amount0Max = IERC20(token0).balanceOf(address(this));
        amount1Max = IERC20(token1).balanceOf(address(this));

        if (amount0Max > 0) {
            IERC20(token0).safeTransfer(_msgSender(), amount0Max);
        }
        if (amount1Max > 0) {
            IERC20(token1).safeTransfer(_msgSender(), amount1Max);
        }
        emit Minted(
            _msgSender(),
            mintAmount,
            amount0,
            amount1,
            liquidityMinted
        );
    }

    function _calcShare(IHyperLPoolStorage hyperpool, uint256 amount)
        internal
        view
        returns (
            uint256 share0,
            address token0,
            address token1
        )
    {
        (uint160 sqrtRatioX96, , , , , , ) =
            IUniswapV3Pool(IHyperLPoolStorage(hyperpool).pool()).slot0();
        int24 lowerTick = IHyperLPoolStorage(hyperpool).lowerTick();
        int24 upperTick = IHyperLPoolStorage(hyperpool).upperTick();
        (uint256 amount0Max, uint256 amount1Max) =
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                lowerTick.getSqrtRatioAtTick(),
                upperTick.getSqrtRatioAtTick(),
                1000000
            );
        token0 = address(hyperpool.token0());
        token1 = address(hyperpool.token1());
        uint256 decimals0 = IERC20Meta(token0).decimals();
        uint256 decimals1 = IERC20Meta(token1).decimals();
        if (decimals0 < decimals1) {
            amount0Max *= 10**(decimals1 - decimals0);
        } else if (decimals0 > decimals1) {
            amount1Max *= 10**(decimals0 - decimals1);
        }
        share0 = (amount * amount0Max) / (amount0Max + amount1Max);
    }

    /// @notice Uniswap v3 callback fn, called back on pool.swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        (address pool, address payer) = abi.decode(data, (address, address));
        require(_msgSender() == address(pool), "callback caller");
        if (amount0Delta > 0) {
            IERC20(IUniswapV3Pool(pool).token0()).safeTransferFrom(
                payer,
                _msgSender(),
                uint256(amount0Delta)
            );
        } else {
            IERC20(IUniswapV3Pool(pool).token1()).safeTransferFrom(
                payer,
                _msgSender(),
                uint256(amount1Delta)
            );
        }
    }

    function _swap(
        address token0,
        address token1,
        uint24 fee,
        uint256 swapAmount
    ) internal returns (uint256 amount) {
        address pool = factory.getPool(token0, token1, fee);
        require(pool != address(0), "!swap pool");
        IUniswapV3Pool(pool).swap(
            address(this),
            false,
            -swapAmount.toInt256(),
            TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(pool, _msgSender())
        );
        amount = IERC20(token1).balanceOf(address(this));
        require(amount > 0, "!swap out");
    }

    /**
     * @dev Set a new trusted gas station address
     * @param _gasStation New gas station address
     */
    function setGasStation(address _gasStation) external onlyOwner {
        _setGasStation(_gasStation);
    }

    /**
     * @dev Forwards calls to the this contract and extracts a fee based on provided arguments
     * @param msgData The byte data representing a mint using the original contract.
     * This is either recieved from the Multiswap API directly or we construct it
     * in order to perform a single swap trade
     */
    function route(bytes calldata msgData) external returns (bytes memory) {
        (bool success, bytes memory resultData) = address(this).call(msgData);

        if (!success) {
            _revertWithData(resultData);
        }

        _returnWithData(resultData);
    }

    /**
     * @dev Revert with arbitrary bytes.
     * @param data Revert data.
     */
    function _revertWithData(bytes memory data) private pure {
        assembly {
            revert(add(data, 32), mload(data))
        }
    }

    /**
     * @dev Return with arbitrary bytes.
     */
    function _returnWithData(bytes memory data) private pure {
        assembly {
            return(add(data, 32), mload(data))
        }
    }
}
