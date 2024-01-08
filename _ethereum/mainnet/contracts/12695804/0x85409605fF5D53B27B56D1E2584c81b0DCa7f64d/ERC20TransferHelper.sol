// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./IERC20.sol";
import "./SafeMathUpgradeable.sol";
import "./EthAddressLib.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    using SafeMathUpgradeable for uint256;

    function doTransferIn(
        address underlying,
        address from,
        uint256 amount
    ) internal returns (uint256) {
        if (underlying == EthAddressLib.ethAddress()) {
            // Sanity checks
            require(tx.origin == from || msg.sender == from, "sender mismatch");
            require(msg.value == amount, "value mismatch");

            return amount;
        } else {
            require(msg.value == 0, "don't support msg.value");
            uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    IERC20.transferFrom.selector,
                    from,
                    address(this),
                    amount
                )
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "STF"
            );

            // Calculate the amount that was *actually* transferred
            uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));
            require(
                balanceAfter >= balanceBefore,
                "TOKEN_TRANSFER_IN_OVERFLOW"
            );
            return balanceAfter - balanceBefore; // underflow already checked above, just subtract
        }
    }

    function doTransferOut(
        address underlying,
        address payable to,
        uint256 amount
    ) internal {
        if (underlying == EthAddressLib.ethAddress()) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "STE");
        } else {
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "ST"
            );
        }
    }

    function getCashPrior(address underlying_) internal view returns (uint256) {
        if (underlying_ == EthAddressLib.ethAddress()) {
            uint256 startingBalance = address(this).balance.sub(msg.value);
            return startingBalance;
        } else {
            IERC20 token = IERC20(underlying_);
            return token.balanceOf(address(this));
        }
    }
}
