// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
import "./IERC20.sol";
import "./EthAddressLib.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library ERC20TransferHelper {
    function doTransferIn(address underlying, address from, uint amount) internal returns (uint) {
        if (underlying == EthAddressLib.ethAddress()) {
            // Sanity checks
            require(tx.origin == from, "sender mismatch");
            require(msg.value == amount, "value mismatch");

            return amount;
        } else {
            require(msg.value == 0, "don't support msg.value");
            IERC20 token = IERC20(underlying);
            uint balanceBefore = IERC20(underlying).balanceOf(address(this));
            token.transferFrom(from, address(this), amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_IN_FAILED");

            // Calculate the amount that was *actually* transferred
            uint balanceAfter = IERC20(underlying).balanceOf(address(this));
            require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
            return balanceAfter - balanceBefore;   // underflow already checked above, just subtract
        }
    }
    function doTransferOut(address underlying, address payable to, uint amount) internal {
        if (underlying == EthAddressLib.ethAddress()) {
            to.transfer(amount);
        } else {
            IERC20 token = IERC20(underlying);
            token.transfer(to, amount);

            bool success;
            assembly {
                switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
            }
            require(success, "TOKEN_TRANSFER_OUT_FAILED");
        }
    }
}