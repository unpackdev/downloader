// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./CurveV1_Base.sol";

import "./ICurveV1Adapter.sol";
import "./IWETH.sol";

import "./ICurvePool_2.sol";
import "./ICurvePoolStETH.sol";
import "./ICRVToken.sol";
import "./IAdapter.sol";
import "./ICreditManagerV2.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./CreditAccount.sol";
import "./CreditManager.sol";
import "./WadRayMath.sol";

// EXCEPTIONS
import "./IErrors.sol";

import "./console.sol";

/// @title CurveV1StETHPoolGateway
/// @dev This is connector contract to connect creditAccounts and Curve stETH pool
/// it converts WETH to ETH and vice versa for operational purposes
contract CurveV1StETHPoolGateway is ICurvePool2Assets {
    using SafeERC20 for IERC20;

    address public immutable token0;
    address public immutable token1;
    address public immutable pool;
    address public immutable lp_token;

    constructor(
        address _weth,
        address _steth,
        address _pool
    ) {
        if (_weth == address(0) || _steth == address(0) || _pool == address(0))
            revert ZeroAddressException();

        token0 = _weth;
        token1 = _steth;
        pool = _pool;

        lp_token = ICurvePoolStETH(_pool).lp_token();
        IERC20(token1).approve(pool, type(uint256).max);
    }

    /// @dev Implements exchange logic to work with ETH cases
    /// @param i Represent index for pool (0 for ETH, 1 for stETH)
    /// @param j Represent index for pool (0 for ETH, 1 for stETH)
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external {
        if (i == 0 && j == 1) {
            IERC20(token0).safeTransferFrom(msg.sender, address(this), dx);
            IWETH(token0).withdraw(dx);
            ICurvePoolStETH(pool).exchange{value: dx}(i, j, dx, min_dy);

            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        } else if (i == 1 && j == 0) {
            IERC20(token1).safeTransferFrom(msg.sender, address(this), dx);
            ICurvePoolStETH(pool).exchange(i, j, dx, min_dy);

            IWETH(token0).deposit{value: address(this).balance}();
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        } else {
            revert("Incorrect i,j parameters");
        }
    }

    function add_liquidity(
        uint256[N_COINS] memory amounts,
        uint256 min_mint_amount
    ) external {
        if (amounts[0] > 0) {
            IERC20(token0).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[0]
            );
            IWETH(token0).withdraw(amounts[0]);
        }

        if (amounts[1] > 0) {
            IERC20(token1).safeTransferFrom(
                msg.sender,
                address(this),
                amounts[1]
            );
        }

        ICurvePoolStETH(pool).add_liquidity{value: amounts[0]}(
            amounts,
            min_mint_amount
        );

        IERC20(lp_token).safeTransfer(
            msg.sender,
            IERC20(lp_token).balanceOf(address(this))
        );
    }

    function remove_liquidity(
        uint256 amount,
        uint256[N_COINS] memory min_amounts
    ) external {
        IERC20(lp_token).safeTransferFrom(msg.sender, address(this), amount);

        ICurvePoolStETH(pool).remove_liquidity(amount, min_amounts);

        IWETH(token0).deposit{value: address(this).balance}();
        IERC20(token0).safeTransfer(
            msg.sender,
            IERC20(token0).balanceOf(address(this))
        );
        IERC20(token1).safeTransfer(
            msg.sender,
            IERC20(token1).balanceOf(address(this))
        );
    }

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external override {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            _token_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_one_coin(
            _token_amount,
            i,
            min_amount
        );

        if (i == 0) {
            IWETH(token0).deposit{value: address(this).balance}();
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        } else {
            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function remove_liquidity_imbalance(
        uint256[N_COINS] memory amounts,
        uint256 max_burn_amount
    ) external {
        IERC20(lp_token).safeTransferFrom(
            msg.sender,
            address(this),
            max_burn_amount
        );

        ICurvePoolStETH(pool).remove_liquidity_imbalance(
            amounts,
            max_burn_amount
        );

        if (amounts[0] > 1) {
            IWETH(token0).deposit{value: address(this).balance}();
            IERC20(token0).safeTransfer(
                msg.sender,
                IERC20(token0).balanceOf(address(this))
            );
        }
        if (amounts[1] > 1) {
            IERC20(token1).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }

        if (IERC20(lp_token).balanceOf(address(this)) > 1) {
            IERC20(lp_token).safeTransfer(
                msg.sender,
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function exchange_underlying(
        int128,
        int128,
        uint256,
        uint256
    ) external pure override {
        revert NotImplementedException();
    }

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        revert NotImplementedException();
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_dy(i, j, dx);
    }

    function get_virtual_price() external view override returns (uint256) {
        return ICurvePoolStETH(pool).get_virtual_price();
    }

    function token() external view returns (address) {
        return lp_token;
    }

    function coins(uint256 i) external view returns (address) {
        if (i == 0) {
            return token0;
        } else {
            return token1;
        }
    }

    receive() external payable {}
}
