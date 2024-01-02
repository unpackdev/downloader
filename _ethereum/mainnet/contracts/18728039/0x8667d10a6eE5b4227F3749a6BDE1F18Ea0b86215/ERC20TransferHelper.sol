// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Constants.sol";

interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    function doApprove(address underlying, address spender, uint256 amount) internal {
        require(underlying.code.length > 0, "invalid underlying");
        (bool success, bytes memory data) = underlying.call(
            abi.encodeWithSelector(
                ERC20Interface.approve.selector,
                spender,
                amount
            )
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SAF");
    }

    function doTransferIn(address underlying, address from, uint256 amount) internal {
        if (underlying == Constants.ETH_ADDRESS) {
            // Sanity checks
            require(tx.origin == from || msg.sender == from, "sender mismatch");
            require(msg.value >= amount, "value mismatch");
        } else {
            require(underlying.code.length > 0, "invalid underlying");
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transferFrom.selector,
                    from,
                    address(this),
                    amount
                )
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))), "STF");
        }
    }

    function doTransferOut(address underlying, address payable to, uint256 amount) internal {
        if (underlying == Constants.ETH_ADDRESS) {
            (bool success, ) = to.call{value: amount}(new bytes(0));
            require(success, "STE");
        } else {
            require(underlying.code.length > 0, "invalid underlying");
            (bool success, bytes memory data) = underlying.call(
                abi.encodeWithSelector(
                    ERC20Interface.transfer.selector,
                    to,
                    amount
                )
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
        }
    }

    function getCashPrior(address underlying_) internal view returns (uint256) {
        if (underlying_ == Constants.ETH_ADDRESS) {
            uint256 startingBalance = address(this).balance - msg.value;
            return startingBalance;
        } else {
            ERC20Interface token = ERC20Interface(underlying_);
            return token.balanceOf(address(this));
        }
    }
}
