// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.6;

import "./IERC20.sol";
import "./IWETH.sol";
import "./SafeMath.sol";
import "./TransferHelper.sol";

library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant TOLERANCE = 10**18 + 10**16;
    uint256 private constant TOTAL_SHARES_PRECISION = 10**18;

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        mapping(address => bool) nonRebasingToken;
        address weth; // represents wrapped native currency (WETH or WMATIC)
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share,
        uint256 amountLimit,
        address refundTo
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth || data.nonRebasingToken[token]) {
            return share;
        }

        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);

        if (amountLimit > 0) {
            uint256 amountLimitWithTolerance = amountLimit.mul(TOLERANCE).div(PRECISION);
            if (value > amountLimitWithTolerance) {
                TransferHelper.safeTransfer(token, refundTo, value.sub(amountLimitWithTolerance));
                return amountLimitWithTolerance;
            }
        }

        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == data.weth) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else if (data.nonRebasingToken[token]) {
            token.safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));

            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesWithoutTransfer(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (token == data.weth) {
            if (wrap) {
                // require(msg.value >= amount, 'TS03'); // Duplicate check in TwapRelayer.sell
                IWETH(token).deposit{ value: amount }();
            }
            return amount;
        } else if (data.nonRebasingToken[token]) {
            return amount;
        } else {
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            uint256 balanceBefore = balanceAfter.sub(amount);
            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesHelper(
        Data storage data,
        address token,
        uint256 balanceBefore,
        uint256 balanceAfter
    ) internal returns (uint256) {
        uint256 totalTokenShares = data.totalShares[token];
        require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
        require(balanceAfter > balanceBefore, 'TS2C');

        if (balanceBefore > 0) {
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore.mul(TOTAL_SHARES_PRECISION);
            }
            uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
            require(balanceAfter < type(uint256).max.div(newShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = newShares;
            return newShares - totalTokenShares;
        } else {
            totalTokenShares = balanceAfter.mul(TOTAL_SHARES_PRECISION);
            require(totalTokenShares < type(uint256).max.div(totalTokenShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = totalTokenShares;
            return totalTokenShares;
        }
    }

    function onUnwrapFailed(
        Data storage data,
        address to,
        uint256 amount
    ) external {
        emit UnwrapFailed(to, amount);
        IWETH(data.weth).deposit{ value: amount }();
        TransferHelper.safeTransfer(data.weth, to, amount);
    }
}
