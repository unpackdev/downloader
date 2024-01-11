// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IStrategy.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";

error UniswapStrategy_NotIncurDebtAddress();
error UniswapStrategy_AmountDoesNotMatch();
error UniswapStrategy_LPTokenDoesNotMatch();
error UniswapStrategy_OhmAddressNotFound();

/**
    @title UniswapStrategy
    @notice This contract provides liquidity to uniswap on behalf of IncurDebt contract.
 */
contract UniSwapStrategy is IStrategy {
    using SafeERC20 for IERC20;

    IUniswapV2Router router;
    IUniswapV2Factory factory;

    address incurDebtAddress;
    address ohmAddress;

    constructor(
        address _router,
        address _factory,
        address _incurDebtAddress,
        address _ohmAddress
    ) {
        router = IUniswapV2Router(_router);
        factory = IUniswapV2Factory(_factory);

        incurDebtAddress = _incurDebtAddress;
        ohmAddress = _ohmAddress;

        IERC20(ohmAddress).approve(_router, type(uint256).max);
    }

    function addLiquidity(
        bytes memory _data,
        uint256 _ohmAmount,
        address _user
    )
        external
        returns (
            uint256 liquidity,
            uint256 ohmUnused,
            address lpTokenAddress
        )
    {
        if (msg.sender != incurDebtAddress) revert UniswapStrategy_NotIncurDebtAddress();
        (
            address tokenA,
            address tokenB,
            uint256 amountADesired,
            uint256 amountBDesired,
            uint256 amountAMin,
            uint256 amountBMin
        ) = abi.decode(_data, (address, address, uint256, uint256, uint256, uint256));

        if (tokenA == ohmAddress) {
            if (_ohmAmount != amountADesired) revert UniswapStrategy_AmountDoesNotMatch();

            IERC20(tokenA).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(tokenB).safeTransferFrom(_user, address(this), amountBDesired);
            IERC20(tokenB).approve(address(router), amountBDesired);
        } else if (tokenB == ohmAddress) {
            if (_ohmAmount != amountBDesired) revert UniswapStrategy_AmountDoesNotMatch();

            IERC20(tokenB).safeTransferFrom(incurDebtAddress, address(this), _ohmAmount);
            IERC20(tokenA).safeTransferFrom(_user, address(this), amountADesired);
            IERC20(tokenA).approve(address(router), amountADesired);
        } else {
            revert UniswapStrategy_OhmAddressNotFound();
        }

        uint256 amountA;
        uint256 amountB;

        (amountA, amountB, liquidity) = router.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            incurDebtAddress,
            block.timestamp
        );

        uint256 amountALeftover = amountADesired - amountA;
        uint256 amountBLeftover = amountBDesired - amountB;

        if (tokenA == ohmAddress) {
            // Return leftover ohm to incurdebt and pair token to user
            ohmUnused = amountALeftover;
            if (amountALeftover > 0) {
                IERC20(ohmAddress).safeTransfer(incurDebtAddress, amountALeftover);
            }

            if (amountBLeftover > 0) {
                IERC20(tokenB).safeTransfer(_user, amountBLeftover);
            }
        } else {
            ohmUnused = amountBLeftover;
            if (amountBLeftover > 0) {
                IERC20(ohmAddress).safeTransfer(incurDebtAddress, amountBLeftover);
            }

            if (amountALeftover > 0) {
                IERC20(tokenA).safeTransfer(_user, amountALeftover);
            }
        }

        lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }

    function removeLiquidity(
        bytes memory _data,
        uint256 _liquidity,
        address _lpTokenAddress,
        address _user
    ) external returns (uint256 ohmRecieved) {
        if (msg.sender != incurDebtAddress) revert UniswapStrategy_NotIncurDebtAddress();
        (address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin) = abi.decode(
            _data,
            (address, address, uint256, uint256, uint256)
        );

        address lpTokenAddress = IUniswapV2Factory(factory).getPair(tokenA, tokenB);

        if (liquidity != _liquidity) revert UniswapStrategy_AmountDoesNotMatch();
        if (tokenA != ohmAddress && tokenB != ohmAddress) revert UniswapStrategy_OhmAddressNotFound();
        if (_lpTokenAddress != lpTokenAddress) revert UniswapStrategy_LPTokenDoesNotMatch();

        IUniswapV2Pair(lpTokenAddress).approve(address(router), liquidity);

        (uint256 amountA, uint256 amountB) = router.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            block.timestamp
        );

        if (tokenA == ohmAddress) {
            ohmRecieved = amountA;
            IERC20(tokenA).safeTransfer(incurDebtAddress, amountA);
            IERC20(tokenB).safeTransfer(_user, amountB);
        } else {
            ohmRecieved = amountB;
            IERC20(tokenB).safeTransfer(incurDebtAddress, amountB);
            IERC20(tokenA).safeTransfer(_user, amountA);
        }
    }
}
