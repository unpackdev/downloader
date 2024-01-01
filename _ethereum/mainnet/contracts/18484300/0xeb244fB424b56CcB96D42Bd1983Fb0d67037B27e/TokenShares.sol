pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



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

    // represents wrapped native currency (WETH or WMATIC)
    address public constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 

    struct Data {
        mapping(address => uint256) totalShares;
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
        if (token == WETH_ADDRESS || isNonRebasing(token)) {
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
        if (token == WETH_ADDRESS) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else if (isNonRebasing(token)) {
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
        if (token == WETH_ADDRESS) {
            if (wrap) {
                // require(msg.value >= amount, 'TS03'); // Duplicate check in TwapRelayer.sell
                IWETH(token).deposit{ value: amount }();
            }
            return amount;
        } else if (isNonRebasing(token)) {
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

    function onUnwrapFailed(address to, uint256 amount) external {
        emit UnwrapFailed(to, amount);
        IWETH(WETH_ADDRESS).deposit{ value: amount }();
        TransferHelper.safeTransfer(WETH_ADDRESS, to, amount);
    }

    
    // constant mapping for nonRebasingToken
    function isNonRebasing(address token) internal pure returns (bool) {
        if (token == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) return true;
        if (token == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) return true;
        if (token == 0xdAC17F958D2ee523a2206206994597C13D831ec7) return true;
        if (token == 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) return true;
        return false;
    }
}
