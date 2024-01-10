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

    event UnwrapFailed(address to, uint256 amount);

    struct Data {
        mapping(address => uint256) totalShares;
        address weth;
    }

    function setWeth(Data storage data, address _weth) internal {
        data.weth = _weth;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == data.weth) {
            return share;
        }
        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);
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
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            uint256 totalTokenShares = data.totalShares[token];
            require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore;
            }
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            require(balanceAfter > balanceBefore, 'TS2C');
            if (balanceBefore > 0) {
                uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
                data.totalShares[token] = newShares;
                return newShares - totalTokenShares;
            } else {
                data.totalShares[token] = balanceAfter;
                return balanceAfter;
            }
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
