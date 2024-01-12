// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./IERC20.sol";

contract ExiledDissidentSplitter is PaymentSplitter {
    uint256 immutable public count;

    constructor(address[] memory payees, uint256[] memory shares_) PaymentSplitter(payees, shares_) {
        count = payees.length;
    }

    function withdrawEth() public {
        for (uint256 i = 0; i < count; ++i) {
            try this.release(payable(payee(i))) {
                i;
            } catch (bytes memory reason) {
                reason;
            }
        }
    }

    function withdrawToken(IERC20 token) public {
        for (uint256 i = 0; i < count; ++i) {
            try this.release(token, payable(payee(i))) {
                i;
            } catch (bytes memory reason) {
                reason;
            }
        }
    }

    function withdrawEthAndToken(IERC20 token) external {
        withdrawEth();
        withdrawToken(token);
    }
}