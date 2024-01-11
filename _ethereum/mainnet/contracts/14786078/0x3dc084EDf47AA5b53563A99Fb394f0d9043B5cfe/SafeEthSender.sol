// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ReentrancyGuard.sol";
import "./CallHelpers.sol";

abstract contract SafeEthSender is ReentrancyGuard {
    mapping(address => uint256) private withdrawRegistry;

    event PendingWithdraw(address _user, uint256 _amount);
    event Withdrawn(address _user, uint256 _amount);

    constructor() ReentrancyGuard() {}

    function sendEthWithLimitedGas(
        address payable _user,
        uint256 _amount,
        uint256 _gasLimit
    ) internal {
        if (_amount == 0) {
            return;
        }

        (bool success, ) = _user.call{value: _amount, gas: _gasLimit}("");
        if (!success) {
            withdrawRegistry[_user] += _amount;

            emit PendingWithdraw(_user, _amount);
        }
    }

    function getAmountToWithdrawForUser(address user)
        public
        view
        returns (uint256)
    {
        return withdrawRegistry[user];
    }

    function withdrawPendingEth() external {
        this.withdrawPendingEthFor(payable(msg.sender));
    }

    function withdrawPendingEthFor(address payable _user)
        external
        nonReentrant
    {
        uint256 amount = withdrawRegistry[_user];
        require(amount > 0, "SafeEthSender: no funds to withdraw");
        withdrawRegistry[_user] = 0;
        (bool success, bytes memory response) = _user.call{value: amount}("");

        if (!success) {
            string memory message = CallHelpers.getRevertMsg(response);
            revert(message);
        }

        emit Withdrawn(_user, amount);
    }
}
