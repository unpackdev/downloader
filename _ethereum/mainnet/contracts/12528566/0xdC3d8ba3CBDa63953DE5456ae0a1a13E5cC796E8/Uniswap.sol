// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

import "./FuseMarginBase.sol";
import "./IUniswapV2Callee.sol";
import "./IERC20.sol";
import "./IPositionProxy.sol";
import "./CErc20Interface.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./UniswapV2Library.sol";

/// @author Ganesh Gautham Elango
/// @title Uniswap flash loan contract
abstract contract Uniswap is FuseMarginBase, IUniswapV2Callee {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @dev Enum for differentiating open/close callbacks
    enum Action { Open, Close }

    /// @dev ConnectorV1 address containing implementation logic
    address public immutable override connector;
    /// @dev Uniswap V2 factory address
    address public immutable uniswapFactory;

    /// @param _connector ConnectorV1 address containing implementation logic
    /// @param _uniswapFactory Uniswap V2 factory address
    constructor(address _connector, address _uniswapFactory) {
        connector = _connector;
        uniswapFactory = _uniswapFactory;
    }

    /// @dev Uniswap flash loan/swap callback. Receives the token amount and gives it back + fees
    /// @param sender The msg.sender who called the Uniswap pair
    /// @param amount0 Amount of token0 received
    /// @param amount1 Amount of token1 received
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(sender == address(this), "FuseMarginV1: Only this contract may initiate");
        (
            Action action,
            address user,
            address position,
            address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
            bytes memory exchangeData
        ) = abi.decode(data, (Action, address, address, address[7], bytes));
        uint256 amount = amount0 > 0 ? amount0 : amount1;
        if (action == Action.Open) {
            require(
                msg.sender ==
                    UniswapV2Library.pairFor(
                        uniswapFactory,
                        addresses[1], /* quote */
                        addresses[2] /* pairToken */
                    ),
                "FuseMarginV1: only permissioned UniswapV2 pair can call"
            );
            _openPosition(amount, position, addresses, exchangeData);
        } else if (action == Action.Close) {
            require(
                msg.sender ==
                    UniswapV2Library.pairFor(
                        uniswapFactory,
                        addresses[0], /* base */
                        addresses[2] /* pairToken */
                    ),
                "FuseMarginV1: only permissioned UniswapV2 pair can call"
            );
            _closePosition(amount, user, position, addresses, exchangeData);
        }
    }

    function _openPosition(
        uint256 amount,
        address position,
        address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
        bytes memory exchangeData
    ) internal {
        // Swap flash loaned quote amount to base
        uint256 depositAmount =
            _swap(
                addresses[1], /* quote */
                addresses[0], /* base */
                addresses[6], /* exchange */
                amount,
                exchangeData
            );
        // Transfer total base to position
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(position, depositAmount);
        // Mint base and borrow quote
        IPositionProxy(position).execute(
            connector,
            abi.encodeWithSignature(
                "mintAndBorrow(address,address,address,address,address,uint256,uint256)",
                addresses[3], /* comptroller */
                addresses[0], /* base */
                addresses[4], /* cBase */
                addresses[1], /* quote */
                addresses[5], /* cQuote */
                depositAmount,
                _uniswapLoanFees(amount)
            )
        );
        // Send the pair the owed amount + flashFee
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(msg.sender, _uniswapLoanFees(amount));
    }

    function _closePosition(
        uint256 amount,
        address user,
        address position,
        address[7] memory addresses, /* [base, quote, pairToken, comptroller, cBase, cQuote, exchange] */
        bytes memory exchangeData
    ) internal {
        // Swap flash loaned base amount to quote
        uint256 receivedAmount =
            _swap(
                addresses[0], /* base */
                addresses[1], /* quote */
                addresses[6], /* exchange */
                amount,
                exchangeData
            );
        // Get amount of quote to repay
        uint256 repayAmount =
            CErc20Interface(
                addresses[5] /* cQuote */
            )
                .borrowBalanceCurrent(position);
        // Transfer quote to be repaid to position
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(position, repayAmount);
        // Repay quote and redeem base
        IPositionProxy(position).execute(
            connector,
            abi.encodeWithSignature(
                "repayAndRedeem(address,address,address,address,uint256,uint256)",
                addresses[0], /* base */
                addresses[4], /* cBase */
                addresses[1], /* quote */
                addresses[5], /* cQuote */
                IERC20(
                    addresses[4] /* cBase */
                )
                    .balanceOf(position),
                repayAmount
            )
        );
        // Send the pair the owed amount + flashFee
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(msg.sender, _uniswapLoanFees(amount));
        // Send the user the base profit
        IERC20(
            addresses[0] /* base */
        )
            .safeTransfer(
            user,
            IERC20(
                addresses[0] /* base */
            )
                .balanceOf(address(this))
        );
        // Send the user leftover quote dust
        IERC20(
            addresses[1] /* quote */
        )
            .safeTransfer(user, receivedAmount.sub(repayAmount));
    }

    function _swap(
        address from,
        address to,
        address exchange,
        uint256 amount,
        bytes memory data
    ) internal returns (uint256) {
        IERC20(from).safeApprove(exchange, amount);
        (bool success, ) = exchange.call(data);
        require(success, "FuseMarginV1: Swap failed");
        return IERC20(to).balanceOf(address(this));
    }

    function _uniswapLoanFees(uint256 amount) internal pure returns (uint256) {
        return amount.add(amount.mul(3).div(997).add(1));
    }
}
