// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Address.sol";
import "./Context.sol";
import "./Ownable.sol";

contract PRTCPayback is Context, Ownable {
    event PaymentReleased(address to, uint256 amount);
    event PaymentReleaseDone();
    event PaymentReceived(address from, uint256 amount);

    constructor() {}

    function payback(address[] memory payees, uint256[] memory debts)
        external
        payable
        onlyOwner
    {
        require(
            payees.length == debts.length,
            "payees and shares length mismatch"
        );
        require(payees.length > 0, "no payees");

        uint256 __totalShares;
        for (uint256 index = 0; index < debts.length; index++) {
            __totalShares += debts[index];
        }

        uint256 __totalReceived = msg.value;
        require(
            __totalShares == __totalReceived,
            "total share is not equal with ether sent"
        );

        for (uint256 index = 0; index < payees.length; index++) {
            address payable __payee = payable(payees[index]);
            uint256 __debt = debts[index];
            Address.sendValue(__payee, __debt);
            emit PaymentReleased(__payee, __debt);
        }
        emit PaymentReleaseDone();
    }

    function balance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}
